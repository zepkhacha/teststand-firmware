-------------------------------------------------------------------------------
-- Title      : Low Level Signals Handler
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : low_level_operations_manager.vhd
-- Author     : 
-- Company    : 
-- Created    : 2013-01-07
-- Last update: 2014-02-07
-- Platform   : Windows 7 64bits, Modelsim 10.2a, Xilinx ISE 16.4
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-01-07  1.0      ghibaudi        Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Definitions
use work.external_memory_interface_definitions.all;


entity DDR3_MI_interface is
  port
    (
      rst               : in  std_logic;
      clk               : in  std_logic;
      cmd_in            : in  UD_MEM_CMD_TRIG_TYPE;
      data_in           : in  DDR3_DATA_TRIG_TYPE;
      addr_in           : in  DDR3_ADDR_WT_SRC_TRIG_TYPE;
      -- Controls Signals from the Memory Interface
      MI_rdy_in         : in  std_logic;
      MI_wdf_rdy        : in  std_logic;
      MI_rd_data_vld_in : in  std_logic;
      MI_rd_data_end_in : in  std_logic;
      -- Data read from the Memory Interface
      MI_data_in        : in  DDR3_DATA_TYPE;
      -- Control Signals to the Memory Interface
      MI_cmd_out        : out UD_MEM_CMD_TYPE;
      MI_data_out       : out DDR3_DATA_TYPE;
      MI_addr_out       : out DDR3_ADDR_TYPE;
      MI_en_out         : out std_logic;
      MI_rd_en          : out std_logic;
      MI_wr_wren_out    : out std_logic;
      MI_wr_end_out     : out std_logic;
      -- Data and control signals to the User Logic
      data_to_UL        : out DDR3_DATA_TRIG_TYPE;
      addr_to_UL        : out DDR3_ADDR_WT_SRC_TRIG_TYPE;
      -- Memory Interface busy signal
      MI_bsy            : out std_logic
      );
end entity DDR3_MI_interface;

architecture RTL of DDR3_MI_interface is

  constant FULL_CMD_SIZE : integer := DDR3_DATA_WIDTH + DDR3_ADDR_WT_SRC_WIDTH +
                                      UD_MEM_CMD_WIDTH;
  constant FULL_CMD_PADDING : std_logic_vector (288 - FULL_CMD_SIZE-1 downto 0) := (others => '0');

  constant UD_MEM_CMD_ADD_WIDTH : integer := 11;  -- 2048
  constant ADDR_FIFO_ADD_WIDTH  : integer := 11;  -- 2048
  constant DATA_FIFO_ADD_WIDTH  : integer := 9;

  -- Next command FIFO
  signal next_cmd_fifo_wr_en : std_logic;
  signal next_cmd_fifo_req   : std_logic;
  signal next_cmd_fifo_out   : UD_MEM_CMD_TYPE;
  signal next_cmd_fifo_empty : std_logic;
  signal next_cmd_fifo_valid : std_logic;
  signal next_cmd_fifo_full  : std_logic;

  -- FIFO for Data/Address Sync coherent commands
  signal cmd_coher_fifo_req   : std_logic;
  signal cmd_coher_fifo_wr_en : std_logic;
  signal cmd_coher_fifo_out   : UD_MEM_CMD_TYPE;
  signal cmd_coher_fifo_empty : std_logic;
  signal cmd_coher_fifo_valid : std_logic;
  signal cmd_coher_fifo_full  : std_logic;

  signal addr_fifo_wr_en : std_logic;
  signal addr_fifo_out   : DDR3_ADDR_WT_SRC_TYPE;
  signal addr_fifo_empty : std_logic;
  signal addr_fifo_valid : std_logic;
  signal addr_fifo_req   : std_logic;
  signal addr_fifo_full  : std_logic;

  signal data_fifo_out   : DDR3_DATA_TYPE;
  signal data_fifo_empty : std_logic;
  signal data_fifo_valid : std_logic;
  signal data_fifo_req   : std_logic;
  signal data_fifo_full  : std_logic;
  signal data_fifo_wr_en : std_logic;

  signal last_was_valid         : std_logic;
  signal last_was_read          : std_logic;
  signal full_cmd               : std_logic_vector(FULL_CMD_SIZE - 1 downto 0);
  signal full_cmd_new           : std_logic;
  signal full_cmd_fifo_data_in  : std_logic_vector(287 downto 0);
  signal full_cmd_fifo_wr_en    : std_logic;
  signal full_cmd_fifo_rd_en    : std_logic;
  signal full_cmd_fifo_data_out : std_logic_vector(287 downto 0);

  signal full_cmd_fifo_almost_full : std_logic;
  signal full_cmd_fifo_empty       : std_logic;
  signal full_cmd_fifo_valid       : std_logic;

  -- Fifo utilization signals. Can be substituted with opens.
  signal cmd_coher_fifo_data_count : std_logic_vector(UD_MEM_CMD_ADD_WIDTH-1 downto 0);
  signal addr_fifo_data_count      : std_logic_vector(ADDR_FIFO_ADD_WIDTH-1 downto 0);
  signal data_fifo_data_count      : std_logic_vector(DATA_FIFO_ADD_WIDTH-1 downto 0);

  -- Used for identifying fifos overutilization scenarios
  constant CRIT_THR_CMD : std_logic_vector(UD_MEM_CMD_ADD_WIDTH-1 downto 0) :=
    std_logic_vector(to_unsigned(2**UD_MEM_CMD_ADD_WIDTH-50, UD_MEM_CMD_ADD_WIDTH));
  constant CRIT_THR_ADD : std_logic_vector(ADDR_FIFO_ADD_WIDTH-1 downto 0) :=
    std_logic_vector(to_unsigned(2**ADDR_FIFO_ADD_WIDTH-50, ADDR_FIFO_ADD_WIDTH));
  constant CRIT_THR_DAT : std_logic_vector(DATA_FIFO_ADD_WIDTH-1 downto 0) :=
    std_logic_vector(to_unsigned(2**DATA_FIFO_ADD_WIDTH-50, DATA_FIFO_ADD_WIDTH));
  
  signal fifos_critical_occupancy : std_logic;
  signal fifos_data_lost          : std_logic;

  ---------------------------------------------------------------------------------
  -- Components
  component FIFO_sclk_288b_32w_FWFT
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      din         : in  std_logic_vector(287 downto 0);
      wr_en       : in  std_logic;
      rd_en       : in  std_logic;
      dout        : out std_logic_vector(287 downto 0);
      full        : out std_logic;
      almost_full : out std_logic;
      empty       : out std_logic;
      valid       : out std_logic
      );
  end component;




  

begin

  -- Checks the fifos utilizations
  buff_overflow_check : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        fifos_critical_occupancy <= '0';
        fifos_data_lost          <= '0';
      else
        fifos_data_lost <= (cmd_coher_fifo_full or next_cmd_fifo_full) or
                           (addr_fifo_full or data_fifo_full);
        if (data_fifo_data_count > CRIT_THR_DAT) or (addr_fifo_data_count > CRIT_THR_ADD) or
          (cmd_coher_fifo_data_count > CRIT_THR_CMD) then
          fifos_critical_occupancy <= '1';
        else
          fifos_critical_occupancy <= '0';
        end if;
      end if;
    end if;
  end process buff_overflow_check;


  -------------------
  -- Path to MEMORY
  next_CMD_fifo_user_logic : entity work.syncfifo
    generic map (width   => UD_MEM_CMD_WIDTH,
                 widthad => UD_MEM_CMD_ADD_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => cmd_in.data,
      wrreq    => next_cmd_fifo_wr_en,
      rdreq    => next_cmd_fifo_req,
      data_out => next_cmd_fifo_out,
      full     => next_cmd_fifo_full,
      empty    => next_cmd_fifo_empty,
      valid    => next_cmd_fifo_valid,
      usedw    => open); 
  next_cmd_fifo_wr_en <= cmd_in.trg and (not rst);


  CMD_coher_fifo_user_logic : entity work.syncfifo
    generic map (width   => UD_MEM_CMD_WIDTH,
                 widthad => UD_MEM_CMD_ADD_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => cmd_in.data,
      wrreq    => cmd_coher_fifo_wr_en,
      rdreq    => cmd_coher_fifo_req,
      data_out => cmd_coher_fifo_out,
      full     => cmd_coher_fifo_full,
      empty    => cmd_coher_fifo_empty,
      valid    => cmd_coher_fifo_valid,
      usedw    => cmd_coher_fifo_data_count); 
  cmd_coher_fifo_wr_en <= cmd_in.trg and (not rst);


  ADDR_fifo_user_logic : entity work.syncfifo
    generic map (width   => DDR3_ADDR_WT_SRC_WIDTH,
                 widthad => ADDR_FIFO_ADD_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => addr_in.data,
      wrreq    => addr_fifo_wr_en,
      rdreq    => addr_fifo_req,
      data_out => addr_fifo_out,
      full     => addr_fifo_full,
      empty    => addr_fifo_empty,
      valid    => addr_fifo_valid,
      usedw    => addr_fifo_data_count); 
  addr_fifo_wr_en <= addr_in.trg and (not rst);

  DATA_fifo_user_logic : entity work.syncfifo
    generic map (width   => DDR3_DATA_WIDTH,
                 widthad => DATA_FIFO_ADD_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => data_in.data,
      wrreq    => data_fifo_wr_en,
      rdreq    => data_fifo_req,
      data_out => data_fifo_out,
      full     => data_fifo_full,
      empty    => data_fifo_empty,
      valid    => data_fifo_valid,
      usedw    => data_fifo_data_count); 
  data_fifo_wr_en <= data_in.trg and (not rst);


  pop_data_addr : process (clk)
    variable last_accepted  : std_logic;
    variable last_stage_rdy : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        data_fifo_req      <= '0';
        addr_fifo_req      <= '0';
        next_cmd_fifo_req  <= '0';
        cmd_coher_fifo_req <= '0';
        last_accepted      := '1';
      else
        last_stage_rdy    := (last_was_valid and (not full_cmd_fifo_almost_full)) or full_cmd_fifo_empty;
        next_cmd_fifo_req <= (not next_cmd_fifo_empty) and (last_stage_rdy and last_accepted);
        if (next_cmd_fifo_valid = '1') or (last_accepted = '0') then
          case next_cmd_fifo_out is
            when DDR3_WR_CMD_CODE =>
              last_accepted      := not (addr_fifo_empty or data_fifo_empty);
              data_fifo_req      <= last_accepted;
              addr_fifo_req      <= last_accepted;
              cmd_coher_fifo_req <= last_accepted;
            when DDR3_RD_CMD_CODE =>
              last_accepted      := not (addr_fifo_empty);
              data_fifo_req      <= '0';
              addr_fifo_req      <= last_accepted;
              cmd_coher_fifo_req <= last_accepted;
            when others =>
              last_accepted      := '1';
              data_fifo_req      <= '0';
              addr_fifo_req      <= '0';
              cmd_coher_fifo_req <= '0';
          end case;
        else
          data_fifo_req      <= '0';
          addr_fifo_req      <= '0';
          cmd_coher_fifo_req <= '0';
        end if;
      end if;
    end if;
  end process pop_data_addr;


  gen_full_cmd : process (rst, clk)
  begin
    if (rst = '1') then
      full_cmd     <= (others => '0');
      full_cmd_new <= '0';
    elsif (rising_edge(clk)) then
      full_cmd <= cmd_coher_fifo_out &
                  addr_fifo_out & data_fifo_out;
      case cmd_coher_fifo_out is
        when DDR3_WR_CMD_CODE =>
          full_cmd_new <= data_fifo_valid and addr_fifo_valid;
        when DDR3_RD_CMD_CODE =>
          full_cmd_new <= addr_fifo_valid;
        when others =>
          full_cmd_new <= '0';
      end case;
    end if;
  end process gen_full_cmd;


  bufferize_cmd : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        full_cmd_fifo_data_in <= (others => '0');
        full_cmd_fifo_wr_en   <= '0';
      else
        full_cmd_fifo_data_in <= FULL_CMD_PADDING & full_cmd;
        full_cmd_fifo_wr_en   <= full_cmd_new;
      end if;
    end if;
  end process bufferize_cmd;


  full_cmd_fifo : FIFO_sclk_288b_32w_FWFT
    port map (
      clk         => clk,
      rst         => rst,
      din         => full_cmd_fifo_data_in,
      wr_en       => full_cmd_fifo_wr_en,
      rd_en       => full_cmd_fifo_rd_en,
      dout        => full_cmd_fifo_data_out,
      full        => open,
      almost_full => full_cmd_fifo_almost_full,
      empty       => full_cmd_fifo_empty,
      valid       => full_cmd_fifo_valid
      );


  pop_full_cmd_fifo : process (clk)
    variable exec_cmd : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        MI_bsy         <= '0';
        last_was_valid <= '1';
        last_was_read  <= '0';
      else
        exec_cmd := (not (full_cmd_fifo_empty and full_cmd_fifo_empty))
                          and (MI_rdy_in and MI_wdf_rdy);
        last_was_valid <= exec_cmd;
        MI_bsy         <= exec_cmd;
        if (full_cmd_fifo_data_out(UD_MEM_CMD_WIDTH + DDR3_DATA_WIDTH +
                                   DDR3_ADDR_WT_SRC_WIDTH -1 downto DDR3_DATA_WIDTH +
                                   DDR3_ADDR_WT_SRC_WIDTH) = DDR3_RD_CMD_CODE) then       
          last_was_read <= '1';
        else
          last_was_read <= '0';
        end if;
      end if;
    end if;
  end process pop_full_cmd_fifo;

  -- Pay attention to this asynchronous logic.
  gen_ext_rqsts : process (full_cmd_fifo_data_out, full_cmd_fifo_empty,
                           full_cmd_fifo_valid, MI_rdy_in, MI_wdf_rdy)
    variable is_read, is_write : std_logic;
  begin
    -- lowest bit of the cmd is '0' for write operations and '1' for read ones.
    is_read  := full_cmd_fifo_data_out(DDR3_DATA_WIDTH + DDR3_ADDR_WT_SRC_WIDTH);
    is_write := not is_read;
    MI_cmd_out <= full_cmd_fifo_data_out(UD_MEM_CMD_WIDTH + DDR3_DATA_WIDTH +
                                         DDR3_ADDR_WT_SRC_WIDTH -1 downto
                                         DDR3_DATA_WIDTH + DDR3_ADDR_WT_SRC_WIDTH);

    MI_data_out <= full_cmd_fifo_data_out(DDR3_DATA_WIDTH-1 downto 0);
    MI_addr_out <= full_cmd_fifo_data_out(DDR3_DATA_WIDTH + DDR3_ADDR_WIDTH-1
                                          downto DDR3_DATA_WIDTH);
    full_cmd_fifo_rd_en <= (not full_cmd_fifo_empty) and (MI_rdy_in and (MI_wdf_rdy or is_read));

    MI_en_out      <= full_cmd_fifo_valid and (MI_rdy_in and (MI_wdf_rdy or is_read));
    MI_wr_wren_out <= full_cmd_fifo_valid and (MI_rdy_in and (MI_wdf_rdy and is_write));
    MI_wr_end_out  <= full_cmd_fifo_valid and (MI_rdy_in and (MI_wdf_rdy and is_write));
    -- Note: memory can be always read.
    MI_rd_en       <= '1';
  end process gen_ext_rqsts;


  -------------------
  -- Path from MEMORY
  -- Generates outputs 
  process_rspns_signals : process (clk)
    variable addr_out_d : DDR3_ADDR_WT_SRC_TYPE;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        addr_to_UL <= (data   => (others => '0'), trg => '0');
        data_to_UL <= (data   => (others => '0'), trg => '0');
        addr_out_d := (others => '0');
      else
        -- Delaying Address out
        addr_to_UL.data <= addr_out_d;
        addr_to_UL.trg  <= last_was_read and last_was_valid;
        data_to_UL      <= (data => MI_data_in, trg => MI_rd_data_vld_in);
        addr_out_d := full_cmd_fifo_data_out(DDR3_DATA_WIDTH + DDR3_ADDR_WT_SRC_WIDTH-1
                                             downto DDR3_DATA_WIDTH);
      end if;
    end if;
  end process process_rspns_signals;
  
  
end architecture RTL;
