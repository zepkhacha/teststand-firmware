-------------------------------------------------------------------------------
-- Title      : memory Interface Wrapper Entity
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : memory_interface_wrapper.vhd
-- Author     : 
-- Company    : 
-- Created    : 2012-12-13
-- Last update: 2014-02-13
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

entity external_memory_interface_wrapper is
  
  port (------- Layer 0, Physical Interface ---------         
    sys_clk        : in    std_logic;
    clk_ref        : in    std_logic;
    sys_rst        : in    std_logic;
    -- Inouts -----
    ddr3_dq        : inout std_logic_vector (DQ_WIDTH-1 downto 0);
    ddr3_dqs_n     : inout std_logic_vector (DQS_WIDTH-1 downto 0);
    ddr3_dqs_p     : inout std_logic_vector (DQS_WIDTH-1 downto 0);
    -- Outputs -----
    ddr3_addr      : out   std_logic_vector (ROW_WIDTH-1 downto 0);
    ddr3_ba        : out   std_logic_vector (BANK_WIDTH-1 downto 0);
    ddr3_ras_n     : out   std_logic;
    ddr3_cas_n     : out   std_logic;
    ddr3_we_n      : out   std_logic;
    ddr3_reset_n   : out   std_logic;
    ddr3_ck_p      : out   std_logic_vector (CK_WIDTH-1 downto 0);
    ddr3_ck_n      : out   std_logic_vector (CK_WIDTH-1 downto 0);
    ddr3_cke       : out   std_logic_vector (CKE_WIDTH-1 downto 0);
    ddr3_cs_n      : out   std_logic_vector (CS_WIDTH*nCS_PER_RANK-1 downto 0);
    ddr3_dm        : out   std_logic_vector (DM_WIDTH-1 downto 0);
    ddr3_odt       : out   std_logic_vector (ODT_WIDTH-1 downto 0);
    -- Clock out and Control signals
    mem_clk_out    : out   std_logic;
    calib_done     : out   std_logic;
    
	 --------- Layer 1, User Interface  ---------      
    -- port a
    port_a_clk     : in    std_logic;
    port_a_rst     : in    std_logic;
    port_a_wr      : in    DDR3_FULL_INFO_TRIG_TYPE;
    port_a_wr_rdy  : out   std_logic;
    port_a_rd_ctrl : in    DDR3_ADDR_TRIG_TYPE;
    port_a_rd_rdy  : out   std_logic;
    port_a_rd      : out   DDR3_FULL_INFO_TRIG_TYPE;
    -- port b
    port_b_clk     : in    std_logic;
    port_b_rst     : in    std_logic;
    port_b_wr      : in    DDR3_FULL_INFO_TRIG_TYPE;
    port_b_wr_rdy  : out   std_logic;
    port_b_rd_ctrl : in    DDR3_ADDR_TRIG_TYPE;
    port_b_rd_rdy  : out   std_logic;
    port_b_rd      : out   DDR3_FULL_INFO_TRIG_TYPE);

end entity external_memory_interface_wrapper;


architecture behavioural of external_memory_interface_wrapper is

  -- Constants renaming
  constant D_WIDTH : integer := DDR3_DATA_WIDTH;
  constant A_WIDTH : integer := DDR3_ADDR_WIDTH;

  constant TIED_LOW  : std_logic := '0';
  constant TIED_HIGH : std_logic := '1';


-- Level 0 control signals
  signal app_rdy           : std_logic;
  signal app_en            : std_logic;
  signal app_cmd           : UD_MEM_CMD_TYPE;
  signal app_addr          : DDR3_ADDR_TYPE;
  signal app_wdf_data      : DDR3_DATA_TYPE;
  signal app_wdf_wren      : std_logic;
  signal app_wdf_end       : std_logic;
  signal app_wdf_rdy       : std_logic;
  signal app_rd_data       : DDR3_DATA_TYPE;
  signal app_rd_data_end   : std_logic;
  signal app_rd_data_valid : std_logic;
  signal app_wdf_mask      : std_logic_vector(31 downto 0);
  signal app_sr_active     : std_logic;
  signal app_ref_ack       : std_logic;
  signal app_zq_ack        : std_logic;

  signal calib_done_i : std_logic;
  signal clk_mem      : std_logic := '0';


-------------------------------------------------------------------
-- Buffers 
-------------------------------------------------------------------

  --------------------------------------------------------------------                
  -- BC clock domain handling               
  -------------------------------------------------------------------- 

  -- Internal write buffer
  signal int_fifo_info_wr_out : DDR3_FULL_INFO_TRIG_TYPE;
  signal int_wr_buff_occ      : MI_FIFO_OCC_TYPE;
  -- Internal read buffer
  signal int_fifo_addr_rd_out : DDR3_ADDR_TRIG_TYPE;
  signal int_rd_buff_occ      : MI_FIFO_OCC_TYPE;
  -- Internal readout buffer
  signal int_rdout_buff_rden  : std_logic;
  signal int_rdout_empty      : std_logic;
  signal info_rd_in           : DDR3_FULL_INFO_TRIG_TYPE;

  --------------------------------------------------------------------                
  -- External clock domain handling               
  -------------------------------------------------------------------- 

  -- Internal write buffer
  signal ext_fifo_info_wr_out : DDR3_FULL_INFO_TRIG_TYPE;
  signal ext_wr_buff_occ      : MI_FIFO_OCC_TYPE;
  -- External read buffer
  signal ext_fifo_addr_rd_out : DDR3_ADDR_TRIG_TYPE;
  signal ext_rd_buff_occ      : MI_FIFO_OCC_TYPE;
  -- External readout buffer
  signal ext_rdout_buff_rden  : std_logic;
  signal ext_rdout_empty      : std_logic;
  signal info_rd_ex           : DDR3_FULL_INFO_TRIG_TYPE;

  -- Unconnected signals
  signal buf1_unc  : std_logic_vector (559-D_WIDTH-A_WIDTH downto 0);
  signal buf2_unc  : std_logic_vector (559-D_WIDTH-A_WIDTH downto 0);
  signal buf3_unc  : std_logic_vector (559-D_WIDTH-A_WIDTH downto 0);
  signal buf4_unc  : std_logic_vector (559-D_WIDTH-A_WIDTH downto 0);
  signal buf1b_unc : std_logic_vector (31-A_WIDTH downto 0);
  signal buf2b_unc : std_logic_vector (31-A_WIDTH downto 0);


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
  signal MI_bsy            : std_logic;
  signal MI_rdy_in         : std_logic;
  signal MI_wdf_rdy        : std_logic;
  signal MI_rd_data_vld_in : std_logic;
  signal data_to_UL        : DDR3_DATA_TRIG_TYPE;
  signal addr_to_UL        : DDR3_ADDR_WT_SRC_TRIG_TYPE;

--------------------------------------------------------------------------------
-- Components declaration
--------------------------------------------------------------------------------

  component ddr3_controller is
    port (
      ddr3_dq    : inout std_logic_vector(31 downto 0);
      ddr3_dqs_p : inout std_logic_vector(3 downto 0);
      ddr3_dqs_n : inout std_logic_vector(3 downto 0);

      ddr3_addr           : out std_logic_vector(13 downto 0);
      ddr3_ba             : out std_logic_vector(2 downto 0);
      ddr3_ras_n          : out std_logic;
      ddr3_cas_n          : out std_logic;
      ddr3_we_n           : out std_logic;
      ddr3_reset_n        : out std_logic;
      ddr3_ck_p           : out std_logic_vector(0 downto 0);
      ddr3_ck_n           : out std_logic_vector(0 downto 0);
      ddr3_cke            : out std_logic_vector(0 downto 0);
      ddr3_cs_n           : out std_logic_vector(0 downto 0);
      ddr3_dm             : out std_logic_vector(3 downto 0);
      ddr3_odt            : out std_logic_vector(0 downto 0);
      app_addr            : in  std_logic_vector(27 downto 0);
      app_cmd             : in  std_logic_vector(2 downto 0);
      app_en              : in  std_logic;
      app_wdf_data        : in  std_logic_vector(255 downto 0);
      app_wdf_end         : in  std_logic;
      app_wdf_mask        : in  std_logic_vector(31 downto 0);
      app_wdf_wren        : in  std_logic;
      app_rd_data         : out std_logic_vector(255 downto 0);
      app_rd_data_end     : out std_logic;
      app_rd_data_valid   : out std_logic;
      app_rdy             : out std_logic;
      app_wdf_rdy         : out std_logic;
      app_sr_req          : in  std_logic;
      app_ref_req         : in  std_logic;
      app_zq_req          : in  std_logic;
      app_sr_active       : out std_logic;
      app_ref_ack         : out std_logic;
      app_zq_ack          : out std_logic;
      ui_clk              : out std_logic;
      ui_clk_sync_rst     : out std_logic;
      init_calib_complete : out std_logic;
      -- System Clock Ports
      sys_clk_i           : in  std_logic;
      clk_ref_i           : in  std_logic;
      sys_rst             : in  std_logic
      );
  end component;

  
begin

  -- Outputting Memory Interface clock
  mem_clk_out <= clk_mem;


-----------------------------------
-- LAYER 0 -- Memory Interface
-----------------------------------

  u_ddr3_controller : ddr3_controller
    port map (  -- Memory interface ports
                ddr3_addr           => ddr3_addr,
                ddr3_ba             => ddr3_ba,
                ddr3_cas_n          => ddr3_cas_n,
                ddr3_ck_n           => ddr3_ck_n,
                ddr3_ck_p           => ddr3_ck_p,
                ddr3_cke            => ddr3_cke,
                ddr3_ras_n          => ddr3_ras_n,
                ddr3_reset_n        => ddr3_reset_n,
                ddr3_we_n           => ddr3_we_n,
                ddr3_dq             => ddr3_dq,
                ddr3_dqs_n          => ddr3_dqs_n,
                ddr3_dqs_p          => ddr3_dqs_p,
                init_calib_complete => calib_done_i,
                ddr3_cs_n           => ddr3_cs_n,
                ddr3_dm             => ddr3_dm,
                ddr3_odt            => ddr3_odt,
                -- Application interface ports
                app_addr            => app_addr,
                app_cmd             => app_cmd,
                app_en              => app_en,
                app_wdf_data        => app_wdf_data,
                app_wdf_end         => app_wdf_end,
                app_wdf_wren        => app_wdf_wren,
                app_rd_data         => app_rd_data,
                app_rd_data_end     => app_rd_data_end,
                app_rd_data_valid   => app_rd_data_valid,
                app_rdy             => app_rdy,
                app_wdf_rdy         => app_wdf_rdy,
                app_sr_req          => TIED_LOW,
                app_ref_req         => TIED_LOW,
                app_zq_req          => TIED_LOW,
                app_sr_active       => app_sr_active,
                app_ref_ack         => app_ref_ack,
                app_zq_ack          => app_zq_ack,
                ui_clk              => clk_mem,
                ui_clk_sync_rst     => open,
                app_wdf_mask        => app_wdf_mask,
                -- System Clock Ports
                sys_clk_i           => sys_clk,
                clk_ref_i           => clk_ref,
                sys_rst             => sys_rst);
  calib_done <= calib_done_i;


  u_memory_interface_controller : entity work.memory_interface_controller
    generic map ( D_SIZE => D_WIDTH,
                  A_SIZE => A_WIDTH)
  port map (  -- Interface to the Xilinx Memory Controller
              clk_mem           => clk_mem,
              calib_done        => calib_done_i,
              MI_rdy_in         => app_rdy,
              MI_wdf_rdy        => app_wdf_rdy,
              MI_rd_data_vld_in => app_rd_data_valid,
              MI_rd_data_end_in => '0',
              MI_data_in        => app_rd_data,
              -- 
              MI_cmd_out        => app_cmd,
              MI_data_out       => app_wdf_data,
              MI_addr_out       => app_addr,
              MI_en_out         => app_en,
              MI_rd_en          => open,
              MI_wr_wren_out    => app_wdf_wren,
              MI_wr_end_out     => app_wdf_end,
              MI_wdf_mask       => app_wdf_mask,
              -----------------
              -- port a
              clk_bc            => port_a_clk,
              rst_bc            => port_a_rst,
              info_to_wr_int    => port_a_wr,
              wr_int_rdy        => port_a_wr_rdy,
              addr_to_rd_int    => port_a_rd_ctrl,
              rd_int_rdy        => port_a_rd_rdy,
              info_rd_int       => port_a_rd,
              -- port b
              clk_ext_intf      => port_b_clk,
              rst_ext_intf      => port_b_rst,
              info_to_wr_ext    => port_b_wr,
              wr_ext_rdy        => port_b_wr_rdy,
              addr_to_rd_ext    => port_b_rd_ctrl,
              rd_ext_rdy        => port_b_rd_rdy,
              info_rd_ext       => port_b_rd );

  
end architecture behavioural;
