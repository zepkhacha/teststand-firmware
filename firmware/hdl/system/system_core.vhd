-- Top-level module for system logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- user packages
use work.ipbus.all;
use work.ipbus_trans_decl.all;
use work.emac_hostbus_decl.all;
use work.system_package.all;
use work.user_package.all;

library unisim;
use unisim.vcomponents.all;

entity system_core is
generic (nbr_usr_slaves : positive := 3);
port (
    -- switch
    sw3 : in std_logic;

    -- on-board oscillator
    osc125_a_p : in std_logic;
    osc125_a_n : in std_logic;
    osc125_b_p : in std_logic;
    osc125_b_n : in std_logic;

    -- ethernet
    amc_tx_p0 : out std_logic;
    amc_tx_n0 : out std_logic;
    amc_rx_p0 : in  std_logic;
    amc_rx_n0 : in  std_logic;

    -- xpoint controls
    k7_master_xpoint_ctrl : out std_logic_vector(0 to 9);
    k7_pcie_clk_ctrl      : out std_logic_vector(0 to 3);
    k7_tclkb_en           : out std_logic;
    k7_tclkd_en           : out std_logic;
    cdce_xpoint           : out std_logic_vector(2 to 4);
    osc_coax_sel          : out std_logic;
    osc_xpoint_ctrl       : out std_logic_vector(0 to 7);

    -- uC interface
    uc_spi_sck  : in  std_logic;
    uc_spi_mosi : in  std_logic;
    uc_spi_miso : out std_logic;
    uc_spi_cs_b : in  std_logic;

    -- clock forwarding to user
    osc125_a_bufg_o      : out std_logic;
    osc125_a_mgtrefclk_o : out std_logic;
    osc125_b_bufg_o      : out std_logic;
    osc125_b_mgtrefclk_o : out std_logic;
    clk_31_250_bufg_o    : out std_logic;

    -- IPbus communication with user
    ipb_clk_i  : in  std_logic;
    ipb_rst_o  : out std_logic;
    ipb_miso_i : in  ipb_rbus_array(0 to nbr_usr_slaves-1);
    ipb_mosi_o : out ipb_wbus_array(0 to nbr_usr_slaves-1);

    -- flash interface
    flash_spi_miso : in  std_logic;
    flash_spi_mosi : out std_logic;
    flash_spi_ss   : out std_logic;

    -- other
    reprog_fpga : in  std_logic;
    user_reset  : in  std_logic;
    board_id    : out std_logic_vector(10 downto 0)
);
end system_core;

architecture wrapper of system_core is

    signal mac_clk                           : std_logic;
    signal mac_tx_valid, mac_rx_valid        : std_logic;
    signal mac_tx_last,  mac_rx_last         : std_logic;
    signal mac_tx_error, mac_rx_error        : std_logic;
    signal mac_tx_data,  mac_rx_data         : std_logic_vector(7 downto 0);
    signal mac_tx_ready                      : std_logic;
    signal eth_locked                        : std_logic;
    signal reset_powerup, reset_powerup_b    : std_logic;
    signal rst, rst_125mhz, ipb_rst, rst_eth : std_logic;
    signal ipb_from_master                   : ipb_wbus;
    signal ipb_to_master                     : ipb_rbus;
    signal ipb_to_slaves                     : ipb_wbus_array(0 to nbr_sys_slaves+nbr_usr_slaves-1);
    signal ipb_from_slaves                   : ipb_rbus_array(0 to nbr_sys_slaves+nbr_usr_slaves-1);
    signal oob_in                            : ipbus_trans_in;
    signal oob_out                           : ipbus_trans_out;
    signal osc125_a_bufg, osc125_a_mgtrefclk : std_logic;
    signal osc125_b_bufg, osc125_b_mgtrefclk : std_logic;
    signal clk_31_250_bufg                   : std_logic;
    signal flash_spi_clk                     : std_logic;
    signal rst_flash_intf                    : std_logic;

    -- Flash interface signals
    signal ipb_flash_wr_nBytes  : std_logic_vector( 8 downto 0);
    signal ipb_flash_rd_nBytes  : std_logic_vector( 8 downto 0);
    signal ipb_flash_cmd_strobe : std_logic;
    signal ipb_flash_rbuf_en    : std_logic;
    signal ipb_flash_rbuf_addr  : std_logic_vector( 6 downto 0);
    signal ipb_flash_rbuf_data  : std_logic_vector(31 downto 0);
    signal ipb_flash_wbuf_en    : std_logic;
    signal ipb_flash_wbuf_addr  : std_logic_vector( 6 downto 0);
    signal ipb_flash_wbuf_data  : std_logic_vector(31 downto 0);

    attribute keep : boolean;
    attribute keep of ipb_clk_i  : signal is true;
    attribute keep of ipb_mosi_o : signal is true;
    attribute keep of ipb_miso_i : signal is true;

begin

-- ------------
-- clock inputs
-- ------------

osc125a_gtebuf: ibufds_gte2 port map (i => osc125_a_p, ib => osc125_a_n, o => osc125_a_mgtrefclk, ceb => '0');
osc125a_clkbuf: bufg        port map (i => osc125_a_mgtrefclk,           o => osc125_a_bufg                 );
osc125b_gtebuf: ibufds_gte2 port map (i => osc125_b_p, ib => osc125_b_n, o => osc125_b_mgtrefclk, ceb => '0');
osc125b_clkbuf: bufg        port map (i => osc125_b_mgtrefclk,           o => osc125_b_bufg                 );


-- ------
-- resets
-- ------

reset_gen: srl16 port map (clk => ipb_clk_i, q => reset_powerup_b, a0 => '1', a1 => '1', a2 => '1', a3 => '1', d => '1');
reset_powerup <= not reset_powerup_b or not sw3;

-- ---------------------------------
clocks: entity work.clocks_7s_serdes
port map (
    clki_fr    => osc125_b_bufg, -- independent free running clock
    clki_125   => mac_clk,
    eth_locked => eth_locked,
    nuke       => reset_powerup,

    clko_ipb => clk_31_250_bufg,
    locked   => open,
    rsto_125 => rst_125mhz,
    rsto_ipb => ipb_rst,
    rsto_eth => rst_eth
);

-- ------------------------------
eth: entity work.eth_7s_1000basex
port map (
    clk_fr_i  => osc125_b_bufg, -- independent free running clock
    rst_i     => rst_eth, 
    locked_o  => eth_locked,
    mac_clk_o => mac_clk,

    gtx_refclk => osc125_a_mgtrefclk,
    gtx_txp    => amc_tx_p0,
    gtx_txn    => amc_tx_n0,
    gtx_rxp    => amc_rx_p0,
    gtx_rxn    => amc_rx_n0,

    tx_data  => mac_tx_data,
    tx_valid => mac_tx_valid,
    tx_last  => mac_tx_last,
    tx_error => mac_tx_error,
    tx_ready => mac_tx_ready,
    rx_data  => mac_rx_data,
    rx_valid => mac_rx_valid,
    rx_last  => mac_rx_last,
    rx_error => mac_rx_error
);

-- ------------------------
ipb: entity work.ipbus_ctrl
generic map (
    mac_cfg => internal,
    ip_cfg  => internal,
    n_oob   => 1
)
port map (
    mac_clk    => mac_clk,
    rst_macclk => rst_125mhz,
    ipb_clk    => ipb_clk_i,
    rst_ipb    => ipb_rst,

    mac_rx_data  => mac_rx_data,
    mac_rx_valid => mac_rx_valid,
    mac_rx_last  => mac_rx_last,
    mac_rx_error => mac_rx_error,

    mac_tx_data  => mac_tx_data,
    mac_tx_valid => mac_tx_valid,
    mac_tx_last  => mac_tx_last,
    mac_tx_error => mac_tx_error,
    mac_tx_ready => mac_tx_ready,

    ipb_out     => ipb_from_master,
    ipb_in      => ipb_to_master,
    rarp_select => '0',
    pkt_rx_led  => open,
    pkt_tx_led  => open,
    oob_in(0)   => oob_in,
    oob_out(0)  => oob_out,
    board_id_o  => board_id
);

-- ---------------------
uc_if: entity work.uc_if
port map (
    clk125      => osc125_b_bufg,
    rst125      => rst_125mhz,
    uc_spi_miso => uc_spi_miso,
    uc_spi_mosi => uc_spi_mosi,
    uc_spi_sck  => uc_spi_sck,
    uc_spi_cs_b => uc_spi_cs_b,
    clk_ipb     => clk_31_250_bufg,
    oob_in      => oob_out,
    oob_out     => oob_in
);

-- -------------------------------------
ipb_fabric: entity work.ipbus_sys_fabric
generic map (
    n_sys_slv     => nbr_sys_slaves,
    n_usr_slv     => nbr_usr_slaves,
    usr_base_addr => x"4000_0000",
    strobe_gap    => false
)
port map (
    ipb_clk         => ipb_clk_i,
    rst             => ipb_rst,
    ipb_in          => ipb_from_master,
    ipb_out         => ipb_to_master,
    ipb_to_slaves   => ipb_to_slaves,
    ipb_from_slaves => ipb_from_slaves
);


-- -------------------
-- IPbus system slaves
-- -------------------

-- -----------------------------------------
ipb_flash_regs: entity work.ipbus_flash_regs
port map (
    clk       => ipb_clk_i,
    reset     => ipb_rst,
    ipbus_in  => ipb_to_slaves(sys_ipb_flash_regs),
    ipbus_out => ipb_from_slaves(sys_ipb_flash_regs),

    flash_wr_nBytes  => ipb_flash_wr_nBytes,
    flash_rd_nBytes  => ipb_flash_rd_nBytes,
    flash_cmd_strobe => ipb_flash_cmd_strobe,
    flash_rbuf_en    => ipb_flash_rbuf_en,
    flash_rbuf_addr  => ipb_flash_rbuf_addr,
    flash_rbuf_data  => ipb_flash_rbuf_data,
    flash_wbuf_en    => ipb_flash_wbuf_en,
    flash_wbuf_addr  => ipb_flash_wbuf_addr,
    flash_wbuf_data  => ipb_flash_wbuf_data
);


-- -------------------
-- SPI Flash interface
-- -------------------

-- ---------------------------------------------
flash_reprog_wrapper: entity work.reprog_wrapper
port map (
    clk     => ipb_clk_i,
    reset   => ipb_rst,
    trigger => reprog_fpga
);

---- obtain access to the SPI clock pin
startupe2_inst: STARTUPE2
generic map (
    PROG_USR      => "FALSE", -- Activate program event security feature (requires encrypted bitstream)
    SIM_CCLK_FREQ => 0.0      -- Set the Configuration Clock Frequency (ns) for simulation
)
port map (
    CFGCLK    => open,          -- 1-bit output: Configuration main clock output
    CFGMCLK   => open,          -- 1-bit output: Configuration internal oscillator clock output
    EOS       => open,          -- 1-bit output: Active high output signal indicating the End Of Startup
    PREQ      => open,          -- 1-bit output: PROGRAM request to fabric output
    CLK       => '0',           -- 1-bit  input: User start-up clock input
    GSR       => '0',           -- 1-bit  input: Global Set/Reset input (GSR cannot be used for the port name)
    GTS       => '0',           -- 1-bit  input: Global 3-state input (GTS cannot be used for the port name)
    KEYCLEARB => '0',           -- 1-bit  input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
    PACK      => '0',           -- 1-bit  input: PROGRAM acknowledge input
    USRCCLKO  => flash_spi_clk, -- 1-bit  input: User CCLK input
    USRCCLKTS => '0',           -- 1-bit  input: User CCLK 3-state enable input
    USRDONEO  => '1',           -- 1-bit  input: User DONE pin output control
    USRDONETS => '1'            -- 1-bit  input: User DONE 3-state enable output
);

rst_flash_intf <= ipb_rst or user_reset;

-- ---------------------------------------------------
flash_intf_wrapper: entity work.spi_flash_intf_wrapper
port map (
    clk      => ipb_clk_i,
    reset    => rst_flash_intf,
    spi_clk  => flash_spi_clk,
    spi_mosi => flash_spi_mosi,
    spi_miso => flash_spi_miso,
    spi_ss   => flash_spi_ss,

    flash_wr_nBytes  => ipb_flash_wr_nBytes,
    flash_rd_nBytes  => ipb_flash_rd_nBytes,
    flash_cmd_strobe => ipb_flash_cmd_strobe,
    rbuf_rd_en       => ipb_flash_rbuf_en,
    rbuf_rd_addr     => ipb_flash_rbuf_addr,
    rbuf_data_out    => ipb_flash_rbuf_data,
    wbuf_wr_en       => ipb_flash_wbuf_en,
    wbuf_wr_addr     => ipb_flash_wbuf_addr,
    wbuf_data_in     => ipb_flash_wbuf_data
);


-- ----------------
-- register mapping
-- ----------------

k7_pcie_clk_ctrl(0)      <= '0'; -- pll_sel -> 0, default setting
k7_pcie_clk_ctrl(1)      <= '0'; -- mr -> 0, normal operation
k7_pcie_clk_ctrl(2)      <= '0'; -- fsel1 125 MHz
k7_pcie_clk_ctrl(3)      <= '1'; -- fsel0
cdce_xpoint(2)           <= '1'; -- u42 out_2 driven by in_4 = CDCE u1
cdce_xpoint(3)           <= '1'; -- u42 out_3 driven by in_4 = CDCE u1
cdce_xpoint(4)           <= '1'; -- u42 out_4 driven by in_4 = CDCE u1
osc_coax_sel             <= '1'; -- select osc
k7_master_xpoint_ctrl(0) <= '1'; -- u7 out_1 driven by in_4
k7_master_xpoint_ctrl(1) <= '1'; -- u7 out_1 driven by in_4
k7_master_xpoint_ctrl(2) <= '1'; -- u7 out_2 driven by in_4
k7_master_xpoint_ctrl(3) <= '1'; -- u7 out_2 driven by in_4
k7_master_xpoint_ctrl(4) <= '0'; -- u7 out_3 driven by in_1
k7_master_xpoint_ctrl(5) <= '0'; -- u7 out_3 driven by in_1
k7_master_xpoint_ctrl(6) <= '1'; -- u7 out_4 driven by in_4
k7_master_xpoint_ctrl(7) <= '1'; -- u7 out_4 driven by in_4
k7_master_xpoint_ctrl(8) <= '1'; -- u8 out_1 driven by in_4
k7_master_xpoint_ctrl(9) <= '1'; -- u8 out_1 driven by in_4
k7_tclkb_en              <= '0'; -- disabled
k7_tclkd_en              <= '0'; -- disabled
osc_xpoint_ctrl(0)       <= '1'; -- u3 out_1 driven by in_4
osc_xpoint_ctrl(1)       <= '1'; -- u3 out_1 driven by in_4
osc_xpoint_ctrl(2)       <= '1'; -- u3 out_2 driven by in_4
osc_xpoint_ctrl(3)       <= '1'; -- u3 out_2 driven by in_4
osc_xpoint_ctrl(4)       <= '1'; -- u3 out_3 driven by in_4
osc_xpoint_ctrl(5)       <= '1'; -- u3 out_3 driven by in_4
osc_xpoint_ctrl(6)       <= '1'; -- u3 out_4 driven by in_4
osc_xpoint_ctrl(7)       <= '1'; -- u3 out_4 driven by in_4


-- --------------------
-- user logic interface
-- --------------------

osc125_a_bufg_o      <= osc125_a_bufg;
osc125_a_mgtrefclk_o <= osc125_a_mgtrefclk;
osc125_b_bufg_o      <= osc125_b_bufg;
osc125_b_mgtrefclk_o <= osc125_b_mgtrefclk;
clk_31_250_bufg_o    <= clk_31_250_bufg;

ipb_rst_o  <= ipb_rst;
ipb_mosi_o <= ipb_to_slaves(nbr_sys_slaves to nbr_usr_slaves+nbr_sys_slaves-1);
ipb_from_slaves(nbr_sys_slaves to nbr_usr_slaves+nbr_sys_slaves-1) <= ipb_miso_i;

end wrapper;
