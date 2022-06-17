-------------------------------------------------------------------------------
-- Title      : memory Interface Controller Entity
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : memory_interface_controller.vhd
-- Author     : 
-- Company    : 
-- Created    : 2012-12-13
-- Last update: 2014-02-18
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2012 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-12-13  1.0      ghibaudi        Created
-- 2013-09-19  2.0      ghibaudi        Redesigned
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.external_memory_interface_definitions.all;

entity memory_interface_controller is
  generic (D_SIZE  : integer := 512;
            A_SIZE : integer := 29);
  port (  -- Interface to the Xilinx Memory Controller
    clk_mem           : in  std_logic;
    calib_done        : in  std_logic;
    MI_rdy_in         : in  std_logic;
    MI_wdf_rdy        : in  std_logic;
    MI_rd_data_vld_in : in  std_logic;
    MI_rd_data_end_in : in  std_logic;
    MI_data_in        : in  std_logic_vector (D_SIZE-1 downto 0);
    -- 
    MI_cmd_out        : out std_logic_vector (2 downto 0);
    MI_data_out       : out std_logic_vector (D_SIZE-1 downto 0);
    MI_addr_out       : out std_logic_vector (A_SIZE-1 downto 0);
    MI_en_out         : out std_logic;
    MI_rd_en          : out std_logic;
    MI_wr_wren_out    : out std_logic;
    MI_wr_end_out     : out std_logic;
    MI_wdf_mask       : out std_logic_vector (31 downto 0);
    -- Signals from the user logic
    -- operations to and from the BC clock domain
    clk_bc            : in  std_logic;
    rst_bc            : in  std_logic;
    -- Internal write FIFOs
    info_to_wr_int    : in  DDR3_FULL_INFO_TRIG_TYPE;
    wr_int_rdy        : out std_logic;
    -- Internal read FIFO
    addr_to_rd_int    : in  DDR3_ADDR_TRIG_TYPE;
    rd_int_rdy        : out std_logic;
    ----- Read data
    info_rd_int       : out DDR3_FULL_INFO_TRIG_TYPE;
    -- operations to and from the ext interface domain
    clk_ext_intf      : in  std_logic;
    rst_ext_intf      : in  std_logic;
    -- External write FIFOs
    info_to_wr_ext    : in  DDR3_FULL_INFO_TRIG_TYPE;
    wr_ext_rdy        : out std_logic;
    -- External read FIFO
    addr_to_rd_ext    : in  DDR3_ADDR_TRIG_TYPE;
    rd_ext_rdy        : out std_logic;
    info_rd_ext       : out DDR3_FULL_INFO_TRIG_TYPE);

end entity memory_interface_controller;


architecture behavioural of memory_interface_controller is

  signal rst_mem : std_logic := '1';

  constant FULL_INFO_FIFO_SIZE : integer := 288;

  --------------------------------------------------------------------                
  -- BC clock domain handling               
  -------------------------------------------------------------------- 
  -- Internal write buffer
  signal int_fifo_info_wr_out : DDR3_FULL_INFO_TRIG_TYPE;
  signal int_wr_buff_occ      : MI_FIFO_OCC_TYPE;
  signal int_wr_buff_din      : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);
  signal int_wr_buff_dout     : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);

  -- Internal read buffer
  signal int_fifo_addr_rd_out : DDR3_ADDR_TRIG_TYPE;
  signal int_rd_buff_occ      : MI_FIFO_OCC_TYPE;
  signal int_rd_buff_din      : std_logic_vector (31 downto 0);
  signal int_rd_buff_dout     : std_logic_vector (31 downto 0);

  -- Internal readout buffer
  signal int_rdout_buff_rden : std_logic;
  signal int_rdout_empty     : std_logic;
  signal info_rd_in          : DDR3_FULL_INFO_TRIG_TYPE;
  signal int_rdout_buff_din  : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);
  signal int_rdout_buff_dout : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);

  --------------------------------------------------------------------                
  -- External clock domain handling               
  -------------------------------------------------------------------- 

  -- Internal write buffer
  signal ext_fifo_info_wr_out : DDR3_FULL_INFO_TRIG_TYPE;
  signal ext_wr_buff_occ      : MI_FIFO_OCC_TYPE;
  signal ext_wr_buff_din      : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);
  signal ext_wr_buff_dout     : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);

  -- External read buffer
  signal ext_fifo_addr_rd_out : DDR3_ADDR_TRIG_TYPE;
  signal ext_rd_buff_occ      : MI_FIFO_OCC_TYPE;
  signal ext_rd_buff_din      : std_logic_vector (31 downto 0);
  signal ext_rd_buff_dout     : std_logic_vector (31 downto 0);

  -- External readout buffer
  signal ext_rdout_buff_rden : std_logic;
  signal ext_rdout_empty     : std_logic;
  signal info_rd_ex          : DDR3_FULL_INFO_TRIG_TYPE;
  signal ext_rdout_buff_din  : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);
  signal ext_rdout_buff_dout : std_logic_vector (FULL_INFO_FIFO_SIZE-1 downto 0);


  -- Unconnected signals
  signal buf1_unc  : std_logic_vector (287-D_SIZE-A_SIZE downto 0);
  signal buf2_unc  : std_logic_vector (287-D_SIZE-A_SIZE downto 0);
  signal buf3_unc  : std_logic_vector (287-D_SIZE-A_SIZE downto 0);
  signal buf4_unc  : std_logic_vector (287-D_SIZE-A_SIZE downto 0);
  signal buf1b_unc : std_logic_vector (31-A_SIZE downto 0);
  signal buf2b_unc : std_logic_vector (31-A_SIZE downto 0);


--------------------------------------------------------------------
-- u_DDR3_operations_scheduler
--------------------------------------------------------------------
  signal DDR3_next_operation : DDR3_OPERATION_TYPE;

--------------------------------------------------------------------
-- u_DDR3_operations_queuer
--------------------------------------------------------------------
  signal pop_fifo_wr_int : std_logic;
  signal pop_fifo_rd_int : std_logic;
  signal pop_fifo_wr_ext : std_logic;
  signal pop_fifo_rd_ext : std_logic;
  signal MI_cmd_next     : UD_MEM_CMD_TRIG_TYPE;
  signal MI_data_next    : DDR3_DATA_TRIG_TYPE;
  signal MI_addr_next    : DDR3_ADDR_WT_SRC_TRIG_TYPE;

--------------------------------------------------------------------
-- u_DDR3_MI_interface
--------------------------------------------------------------------
  signal MI_bsy     : std_logic;
  --signal MI_rdy_in         : std_logic;
  --signal MI_wdf_rdy        : std_logic;
  --signal MI_rd_data_vld_in : std_logic;
  signal data_to_UL : DDR3_DATA_TRIG_TYPE;
  signal addr_to_UL : DDR3_ADDR_WT_SRC_TRIG_TYPE;


  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------
COMPONENT FIFO_ddr3_intf_data_addr
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(287 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(287 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    rd_data_count : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
  );
END COMPONENT;

COMPONENT FIFO_ddr3_intf_addr
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    rd_data_count : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
  );
END COMPONENT;
  

begin

  -- Generating an internal reset signal
  process (clk_mem)
  begin
    if rising_edge(clk_mem) then
      if (calib_done = '1') then
        rst_mem <= '0';
      else
        rst_mem <= '1';
      end if;
    end if;
  end process;

-----------------------------------
-- LAYER 1 -- User Interface
-----------------------------------
  -- @TODO, change last stage FIFO
  u_DDR3_MI_interface : entity work.DDR3_MI_interface
    port map (clk               => clk_mem,
              rst               => rst_mem,
              cmd_in            => MI_cmd_next,
              data_in           => MI_data_next,
              addr_in           => MI_addr_next,
              -- Controls Signals from the Memory Interface
              MI_rdy_in         => MI_rdy_in,
              MI_wdf_rdy        => MI_wdf_rdy,
              MI_rd_data_vld_in => MI_rd_data_vld_in,
              MI_rd_data_end_in => '0',
              -- Data read from the Memory Interface
              MI_data_in        => MI_data_in,
              -- Control Signals to the Memory Interface
              MI_cmd_out        => MI_cmd_out,
              MI_data_out       => MI_data_out,
              MI_addr_out       => MI_addr_out,
              MI_en_out         => MI_en_out,
              MI_rd_en          => open,
              MI_wr_wren_out    => MI_wr_wren_out,
              MI_wr_end_out     => MI_wr_end_out,
              -- Data and control signals to the User Logic
              data_to_UL        => data_to_UL,
              addr_to_UL        => addr_to_UL,
              -- Memory Interface busy signal
              MI_bsy            => MI_bsy);
  -- Signal assignments
  MI_wdf_mask <= (others => '0');


  -- FIFO status generator
  u_fifo_status : entity work.fifo_status
    generic map (CRITICAL_THRESHOLD => 2**(INPUT_BUFFS_ADD_WIDTH-1-1))  -- half fifo size
    port map (clk             => clk_mem,
              rst             => rst_mem,
              -- Fifos utilization
              fifo_wr_int_occ => int_wr_buff_occ,
              fifo_rd_int_occ => int_rd_buff_occ,
              fifo_wr_ext_occ => ext_wr_buff_occ,
              fifo_rd_ext_occ => ext_rd_buff_occ,
              -- Status of the FIFOs
              fifo_wr_int_rdy => wr_int_rdy,
              fifo_rd_int_rdy => rd_int_rdy,
              fifo_wr_ext_rdy => wr_ext_rdy,
              fifo_rd_ext_rdy => rd_ext_rdy);

  --------------------------------------------------------------------                
  -- BC clock domain handling               
  --------------------------------------------------------------------                

  ---- Input buffers
  -- Write buffer
  int_wr_buff : FIFO_ddr3_intf_data_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_bc,
              rd_clk        => clk_mem,
              din           => int_wr_buff_din,
              wr_en         => info_to_wr_int.trg,
              rd_en         => pop_fifo_wr_int,
              dout          => int_wr_buff_dout,
              full          => open,
              empty         => open,
              valid         => int_fifo_info_wr_out.trg,
              rd_data_count => int_wr_buff_occ);
  
  int_wr_buff_din(FULL_INFO_FIFO_SIZE-1 downto A_SIZE+D_SIZE) <= (others => '0'); -- PV 2015.02.12
  int_wr_buff_din(A_SIZE+D_SIZE-1 downto 0) <= info_to_wr_int.addr & info_to_wr_int.data; 
  int_fifo_info_wr_out.data                 <= int_wr_buff_dout(D_SIZE-1 downto 0);
  int_fifo_info_wr_out.addr                 <= int_wr_buff_dout(D_SIZE+A_SIZE-1 downto D_SIZE);

  -- Read buffer
  int_rd_buff : FIFO_ddr3_intf_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_bc,
              rd_clk        => clk_mem,
              din           => int_rd_buff_din,
              wr_en         => addr_to_rd_int.trg,
              rd_en         => pop_fifo_rd_int,
              dout          => int_rd_buff_dout,
              full          => open,
              empty         => open,
              valid         => int_fifo_addr_rd_out.trg,
              rd_data_count => int_rd_buff_occ);
  
  int_rd_buff_din(31 downto A_SIZE) <= (others => '0'); -- PV 2015.02.12
  int_rd_buff_din(A_SIZE-1 downto 0) <= addr_to_rd_int.data;
  int_fifo_addr_rd_out.data          <= int_rd_buff_dout(A_SIZE-1 downto 0);

  ---- Output buffer
  -- Readout buffer
  int_rdout_buff : FIFO_ddr3_intf_data_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_mem,
              rd_clk        => clk_bc,
              din           => int_rdout_buff_din,
              wr_en         => info_rd_in.trg,
              rd_en         => int_rdout_buff_rden,
              dout          => int_rdout_buff_dout,
              full          => open,
              empty         => int_rdout_empty,
              valid         => info_rd_int.trg,
              rd_data_count => open);
  
  
  int_rdout_buff_din(FULL_INFO_FIFO_SIZE-1 downto A_SIZE+D_SIZE) <= (others => '0'); -- PV 2015.02.12
  int_rdout_buff_din(A_SIZE+D_SIZE-1 downto 0) <= info_rd_in.addr & info_rd_in.data;
  info_rd_int.data                             <= int_rdout_buff_dout(D_SIZE-1 downto 0);
  info_rd_int.addr                             <= int_rdout_buff_dout(D_SIZE+A_SIZE-1 downto D_SIZE);

  int_rdout_buff_rden <= not int_rdout_empty;
  --------------------------------------------------------------------                
  -- External Interface clock domain handling               
  --------------------------------------------------------------------                

  ---- Input buffers
  -- Write buffer
  ext_wr_buff : FIFO_ddr3_intf_data_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_ext_intf,
              rd_clk        => clk_mem,
              din           => ext_wr_buff_din,
              wr_en         => info_to_wr_ext.trg,
              rd_en         => pop_fifo_wr_ext,
              dout          => ext_wr_buff_dout,
              full          => open,
              empty         => open,
              valid         => ext_fifo_info_wr_out.trg,
              rd_data_count => ext_wr_buff_occ);
  
  ext_wr_buff_din(FULL_INFO_FIFO_SIZE-1 downto A_SIZE+D_SIZE) <= (others => '0'); -- PV 2015.02.12
  ext_wr_buff_din(A_SIZE+D_SIZE-1 downto 0) <= info_to_wr_ext.addr & info_to_wr_ext.data;
  ext_fifo_info_wr_out.data                 <= ext_wr_buff_dout(D_SIZE-1 downto 0);
  ext_fifo_info_wr_out.addr                 <= ext_wr_buff_dout(D_SIZE+A_SIZE-1 downto D_SIZE);

  -- Read buffer
  ext_rd_buff : FIFO_ddr3_intf_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_ext_intf,
              rd_clk        => clk_mem,
              din           => ext_rd_buff_din,
              wr_en         => addr_to_rd_ext.trg,
              rd_en         => pop_fifo_rd_ext,
              dout          => ext_rd_buff_dout,
              full          => open,
              empty         => open,
              valid         => ext_fifo_addr_rd_out.trg,
              rd_data_count => ext_rd_buff_occ);
  
  ext_rd_buff_din(31 downto A_SIZE) <= (others => '0'); -- PV 2015.02.12
  ext_rd_buff_din(A_SIZE-1 downto 0) <= addr_to_rd_ext.data;
  ext_fifo_addr_rd_out.data          <= ext_rd_buff_dout(A_SIZE-1 downto 0);

  ---- Output buffer
  -- Readout buffer
  ext_rdout_buff : FIFO_ddr3_intf_data_addr
    port map (rst           => rst_mem,
              wr_clk        => clk_mem,
              rd_clk        => clk_ext_intf,
              din           => ext_rdout_buff_din,
              wr_en         => info_rd_ex.trg,
              rd_en         => ext_rdout_buff_rden,
              dout          => ext_rdout_buff_dout,
              full          => open,
              empty         => ext_rdout_empty,
              valid         => info_rd_ext.trg,
              rd_data_count => open);
  
  ext_rdout_buff_din(FULL_INFO_FIFO_SIZE-1 downto A_SIZE+D_SIZE) <= (others => '0'); -- PV 2015.02.12
  ext_rdout_buff_din(A_SIZE+D_SIZE-1 downto 0) <= info_rd_ex.addr & info_rd_ex.data;
  info_rd_ext.data                             <= ext_rdout_buff_dout(D_SIZE-1 downto 0);
  info_rd_ext.addr                             <= ext_rdout_buff_dout(D_SIZE+A_SIZE-1 downto D_SIZE);

  ext_rdout_buff_rden <= not ext_rdout_empty;

  ------------------------------------------
  -- Memory Interface
  -- Scheduling of the commands
  u_DDR3_operations_scheduler : entity work.DDR3_operations_scheduler
    generic map(EXT_BUS_ANTI_SVTION_THD => 16,
                MI_NUM_MAX_QUEUED_OPS   => INTERNAL_WRITE_BURST_LENGTH*16,
                BURST_SIZE              => INTERNAL_WRITE_BURST_LENGTH*2)
    port map (rst            => rst_mem,
              clk            => clk_mem,
              -- Request signals
              int_wr_occ     => int_wr_buff_occ,
              int_rd_occ     => int_rd_buff_occ,
              ext_wr_occ     => ext_wr_buff_occ,
              ext_rd_occ     => ext_rd_buff_occ,
              -- Signals from DDR3_MI_interface
              MI_bsy         => MI_bsy,
              -- DDR3 operation to be scheduled next
              DDR3_operation => DDR3_next_operation);

  -- Queueing of address and data together with the commands      
  u_DDR3_operations_queuer : entity work.DDR3_operations_queuer
    port map (rst             => rst_mem,
              clk             => clk_mem,
              DDR3_operation  => DDR3_next_operation,
              -- Addresses and Data in
              wr_int_info     => int_fifo_info_wr_out,
              rd_int_addr     => int_fifo_addr_rd_out,
              wr_ext_info     => ext_fifo_info_wr_out,
              rd_ext_addr     => ext_fifo_addr_rd_out,
              -- Request data/addresses from the different interface
              pop_fifo_wr_int => pop_fifo_wr_int,
              pop_fifo_rd_int => pop_fifo_rd_int,
              pop_fifo_wr_ext => pop_fifo_wr_ext,
              pop_fifo_rd_ext => pop_fifo_rd_ext,
              -- Send commands, data and addresses
              MI_cmd_out      => MI_cmd_next,
              MI_data_out     => MI_data_next,
              MI_addr_out     => MI_addr_next);


  -- Aligns data and address and differentiate between data for internal and
  -- external interface.
  u_RAM_read_data_handler : entity work.RAM_read_data_handler
    port map (rst             => rst_mem,
              clk             => clk_mem,
              data_in         => data_to_UL,
              addr_in         => addr_to_UL,
              int_rd_info_out => info_rd_in,
              ext_rd_info_out => info_rd_ex);

  -------------------------------------------------------------
  ------- PROBING COMPONENTS ---------------------------
  -------------------------------------------------------------
  -- synthesis translate_off     
  -- u_instruction_logging : entity work.instruction_logging
  -- port map (rst            => rst_mem,
  -- clk            => clk_mem,
  -- memc_cmd_en    => MI_en_out,
  -- memc_cmd_instr => app_cmd,
  -- memc_cmd_addr  => app_addr,
  -- memc_wr_data   => app_wdf_data); 

  -- u_RAM_throughput_monitor : entity work.RAM_throughput_monitor
  -- port map (rst            => rst_mem,
  -- clk            => clk_mem,
  -- memc_cmd_rdy   => app_rdy,
  -- memc_cmd_en    => MI_en_out,
  -- memc_cmd_instr => app_cmd);
  -- synthesis translate_on  


end behavioural;
