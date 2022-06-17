-- Top-level of the Encoder FC7 project

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- user packages
use work.ipbus.all;
use work.system_package.all;
use work.user_package.all;

library unisim;
use unisim.vcomponents.all;

entity fc7_encoder_top is 
port (
    -- ------------
    -- common ports
    -- ------------

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
    osc_coax_sel          : out std_logic;
    osc_xpoint_ctrl       : out std_logic_vector(0 to 7);

    -- FMC controls
    fmc_l12_absent : in    std_logic;
    fmc_l12_pwr_en : out   std_logic;
    fmc_l8_absent  : in    std_logic;
    fmc_l8_pwr_en  : out   std_logic;
    fmc_i2c_scl    : inout std_logic;
    fmc_i2c_sda    : inout std_logic;

    -- LEDs
    top_led2 : out std_logic_vector(2 downto 0);
    top_led3 : out std_logic_vector(2 downto 0);
    bot_led1 : out std_logic_vector(2 downto 0);
    bot_led2 : out std_logic_vector(2 downto 0);

    -- CPLD
    cpld2fpga_gpio0 : in  std_logic;
    cpld2fpga_gpio1 : in  std_logic;
    cpld2fpga_gpio2 : out std_logic;
    cpld2fpga_gpio3 : in  std_logic;

    flash_spi_miso : in  std_logic;
    flash_spi_mosi : out std_logic;
    flash_spi_ss   : out std_logic;

    -- DAQ link
    daq_rxp : in  std_logic;
    daq_rxn : in  std_logic;
    daq_txp : out std_logic;
    daq_txn : out std_logic;
    
    -- TTC
    fabric_clk_p : in std_logic;
    fabric_clk_n : in std_logic;

    ttc_rx_p : in std_logic;
    ttc_rx_n : in std_logic;

    -- CDCE
    cdce_sync_b  : out std_logic;
    cdce_sync_r0 : out std_logic;
    cdce_xpoint  : out std_logic_vector(2 to 4);
    cdce_ref_sel : out std_logic;
    cdce_pwrdown : out std_logic;

    -- -------------
    -- encoder ports
    -- -------------

    -- FMC clock
    fmc_l8_clk0 : in std_logic;

    -- FMC LEMOs
    aux_lemo_a : in  std_logic;
    aux_lemo_b : out std_logic;
    tr0_lemo_p : in  std_logic;
    tr0_lemo_n : in  std_logic;
    tr1_lemo_p : in  std_logic;
    tr1_lemo_n : in  std_logic;

    -- FMC LEDs
    fmc_l8_led1 : out std_logic_vector(1 downto 0);
    fmc_l8_led2 : out std_logic_vector(1 downto 0);
    fmc_l8_led  : out std_logic_vector(8 downto 3);

    -- FMC I2C
    i2c_l12_scl : inout std_logic;
    i2c_l12_sda : inout std_logic;
    i2c_l12_rst : out   std_logic; -- active-low
    i2c_l12_int : in    std_logic; -- active-low

    i2c_l8_scl : inout std_logic;
    i2c_l8_sda : inout std_logic;
    i2c_l8_rst : out   std_logic; -- active-low

    -- FMC SFP
    sfp_l12_rx_p : in  std_logic_vector(7 downto 0);
    sfp_l12_rx_n : in  std_logic_vector(7 downto 0);
    sfp_l12_tx_p : out std_logic_vector(7 downto 0);
    sfp_l12_tx_n : out std_logic_vector(7 downto 0)
);
end fc7_encoder_top;

architecture top of fc7_encoder_top is

    -- clocks
    signal clk_31_250_bufg    : std_logic;
    signal osc125_a_bufg      : std_logic;
    signal osc125_a_mgtrefclk : std_logic;
    signal osc125_b_bufg      : std_logic;
    signal osc125_b_mgtrefclk : std_logic;
    signal ext_clk            : std_logic;
    signal ext_clk_buf        : std_logic;

    -- IPbus
    signal ipb_rst  : std_logic;
    signal ipb_miso : ipb_rbus_array(0 to nbr_usr_enc_slaves-1);
    signal ipb_mosi : ipb_wbus_array(0 to nbr_usr_enc_slaves-1);

    -- user signals
    signal reprog_fpga : std_logic;
    signal user_reset  : std_logic;
    signal board_id    : std_logic_vector(10 downto 0);

    -- CDCE
    signal cdce_sync_clk : std_logic;
    signal cdce_sync     : std_logic;
    
begin

-- -----------
-- FMC control
-- -----------

fmc_l12_pwr_en <= '1'; -- always power up EDA-02707-V2
fmc_l8_pwr_en  <= '1'; -- always power up EDA-02708-V2

-- ----------
-- CDCE logic
-- ----------

CDCE_SYNC_B_FDRE : FDRE port map (d => cdce_sync, q => cdce_sync_b,  c => cdce_sync_clk, ce => '1', r => '0');
CDCE_SYNC_R0_FDRE: FDRE port map (d => cdce_sync, q => cdce_sync_r0, c => cdce_sync_clk, ce => '1', r => '0');

-- ---------------
-- clock buffering
-- ---------------

FMC_L8_CLK_0_IBUFG: IBUFG port map (I => fmc_l8_clk0, O => ext_clk_buf);
EXT_CLK_BUFG      : BUFG  port map (I => ext_clk_buf, O => ext_clk    );

-- --------------------
-- module instantiation
-- --------------------

-- -------------------------
sys: entity work.system_core
generic map (nbr_usr_slaves => 3)
port map (
    -- switch
    sw3 => sw3,

    -- on-board oscillator
    osc125_a_p => osc125_a_p,
    osc125_a_n => osc125_a_n,
    osc125_b_p => osc125_b_p,
    osc125_b_n => osc125_b_n,

    -- ethernet
    amc_tx_p0 => amc_tx_p0,
    amc_tx_n0 => amc_tx_n0,
    amc_rx_p0 => amc_rx_p0,
    amc_rx_n0 => amc_rx_n0,

    -- xpoint controls
    k7_master_xpoint_ctrl => k7_master_xpoint_ctrl,
    k7_pcie_clk_ctrl      => k7_pcie_clk_ctrl,
    k7_tclkb_en           => k7_tclkb_en,
    k7_tclkd_en           => k7_tclkd_en,
    cdce_xpoint           => cdce_xpoint,
    osc_coax_sel          => osc_coax_sel,
    osc_xpoint_ctrl       => osc_xpoint_ctrl,

    -- uC interface
    uc_spi_sck  => cpld2fpga_gpio0,
    uc_spi_mosi => cpld2fpga_gpio1,
    uc_spi_miso => cpld2fpga_gpio2,
    uc_spi_cs_b => cpld2fpga_gpio3,

    -- clock forwarding to user
    osc125_a_bufg_o      => osc125_a_bufg,
    osc125_a_mgtrefclk_o => osc125_a_mgtrefclk,
    osc125_b_bufg_o      => osc125_b_bufg,
    osc125_b_mgtrefclk_o => osc125_b_mgtrefclk,
    clk_31_250_bufg_o    => clk_31_250_bufg,

    -- IPbus communication with user
    ipb_clk_i  => clk_31_250_bufg,
    ipb_rst_o  => ipb_rst,
    ipb_mosi_o => ipb_mosi,
    ipb_miso_i => ipb_miso,

    -- flash interface
    flash_spi_miso => flash_spi_miso,
    flash_spi_mosi => flash_spi_mosi,
    flash_spi_ss   => flash_spi_ss,

    -- other
    reprog_fpga => reprog_fpga,
    user_reset  => user_reset,
    board_id    => board_id
);


-- --------------------------------
usr: entity work.user_encoder_logic
port map (
    -- clocks
    ext_clk => ext_clk,
    ipb_clk => clk_31_250_bufg,

    fabric_clk_p => fabric_clk_p,
    fabric_clk_n => fabric_clk_n,

    osc125_a_bufg      => osc125_a_bufg,
    osc125_a_mgtrefclk => osc125_a_mgtrefclk,
    osc125_b_bufg      => osc125_b_bufg,
    osc125_b_mgtrefclk => osc125_b_mgtrefclk,

    -- LEDs
    top_led2 => top_led2,
    top_led3 => top_led3,
    bot_led1 => bot_led1,
    bot_led2 => bot_led2,

    fmc_l8_led1 => fmc_l8_led1,
    fmc_l8_led2 => fmc_l8_led2,
    fmc_l8_led  => fmc_l8_led,

    -- FMC status
    fmc_l12_absent => fmc_l12_absent,
    fmc_l8_absent  => fmc_l8_absent,
    
    -- FMC LEMOs
    aux_lemo_a => aux_lemo_a,
    aux_lemo_b => aux_lemo_b,
    tr0_lemo_p => tr0_lemo_p,
    tr0_lemo_n => tr0_lemo_n,
    tr1_lemo_p => tr1_lemo_p,
    tr1_lemo_n => tr1_lemo_n,

    -- FMC SFP
    sfp_l12_rx_p => sfp_l12_rx_p,
    sfp_l12_rx_n => sfp_l12_rx_n,
    sfp_l12_tx_p => sfp_l12_tx_p,
    sfp_l12_tx_n => sfp_l12_tx_n,

    -- FMC I2C
    i2c_fmc_scl => fmc_i2c_scl,
    i2c_fmc_sda => fmc_i2c_sda,

    i2c_l12_scl => i2c_l12_scl,
    i2c_l12_sda => i2c_l12_sda,
    i2c_l12_rst => i2c_l12_rst,
    i2c_l12_int => i2c_l12_int,

    i2c_l8_scl => i2c_l8_scl,
    i2c_l8_sda => i2c_l8_sda,
    i2c_l8_rst => i2c_l8_rst,

    -- DAQ link
    daq_rxp => daq_rxp,
    daq_rxn => daq_rxn,
    daq_txp => daq_txp,
    daq_txn => daq_txn,

    -- TTC
    ttc_rx_p => ttc_rx_p,
    ttc_rx_n => ttc_rx_n,

    -- CDCE
    cdce_ref_sel_o  => cdce_ref_sel,
    cdce_pwrdown_o  => cdce_pwrdown,
    cdce_sync_o     => cdce_sync,
    cdce_sync_clk_o => cdce_sync_clk,

    -- IPbus
    ipb_rst_i  => ipb_rst,
    ipb_mosi_i => ipb_mosi,
    ipb_miso_o => ipb_miso,

    -- other
    reprog_fpga => reprog_fpga,
    user_reset  => user_reset,
    board_id    => board_id
);

end top;
