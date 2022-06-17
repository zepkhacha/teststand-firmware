-- Wrapper to instantiate trigger_sequencer.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity trigger_sequencer_wrapper is
port (
  -- clock and reset
  clk : in std_logic;
  rst : in std_logic;

  -- reset interface
  post_rst_delay_evt_cnt   : in std_logic_vector(31 downto 0);
  post_rst_delay_timestamp : in std_logic_vector(31 downto 0);
  post_rst_delay_async     : in std_logic_vector(23 downto 0);

  -- trigger interface
  run_enable            : in  std_logic;
  run_pause             : in  std_logic;
  abort_run             : in  std_logic;
  no_beam_structure     : in std_logic;
  enable_async_storage  : in  std_logic;
  global_count          : in  std_logic_vector( 3 downto 0);
  ofw_cycle_threshold   : in  std_logic_vector(23 downto 0);
  cycle_start_threshold : in  std_logic_vector(31 downto 0);
  eor_wait_count        : in  std_logic_vector(31 downto 0);
  trigger               : in  std_logic;
  send_ofw_boc          : in  std_logic;
  begin_of_cycle        : out std_logic;
  internal_trigger_strt : in  std_logic;
  internal_trigger_stop : in  std_logic;
  a6_missed_restart     : in  std_logic;
  trigger_clear         : out std_logic;

  -- transceiver checks
  eeprom_channel_sel : out std_logic_vector(  7 downto 0);
  eeprom_map_sel     : out std_logic;
  eeprom_start_adr   : out std_logic_vector(  7 downto 0);
  eeprom_num_regs    : out std_logic_vector(  5 downto 0);
  eeprom_read_start  : out std_logic;
  eeprom_reg         : in  std_logic_vector(127 downto 0);
  eeprom_reg_valid   : in  std_logic;
  
  -- sequence information
  trig_count_seq   : in array_16x4bit;
  trig_type_seq    : in array_16x16x5bit;
  pre_trig_gap_seq : in array_16x16x32bit;

  -- TTC interface
  channel_a       : out std_logic;
  channel_b_data  : out std_logic_vector(7 downto 0);
  channel_b_valid : out std_logic;

  -- trigger FIFO interface
  trig_timestamp  : out std_logic_vector(43 downto 0);
  trig_num        : out std_logic_vector(23 downto 0);
  trig_type_num   : out array_32x24bit;
  trig_type       : out std_logic_vector( 4 downto 0);
  trig_delay      : out std_logic_vector(31 downto 0);
  trig_index      : out std_logic_vector( 3 downto 0);
  trig_sub_index  : out std_logic_vector( 3 downto 0);
  trig_info_valid : out std_logic;

  -- status signals
  overflow_warning        : in  std_logic;
  sfp_enabled_ports       : in  std_logic_vector( 7 downto 0);
  state                   : out std_logic_vector(17 downto 0);
  run_timer               : out std_logic_vector(63 downto 0);
  ofw_cycle_count_running : out std_logic_vector(23 downto 0);
  ofw_cycle_count         : out std_logic_vector(23 downto 0);
  ofw_limit_reached       : out std_logic;
  run_in_progress         : out std_logic;
  doing_run_checks        : out std_logic;
  resetting_clients       : out std_logic;
  finding_cycle_start     : out std_logic;
  run_aborted             : out std_logic;
  missing_trigger         : out std_logic;
  async_enable_sent       : out std_logic
);
end trigger_sequencer_wrapper;

architecture Behavioral of trigger_sequencer_wrapper is

  component trigger_sequencer is 
  port (
    -- clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- reset interface
    post_rst_delay_evt_cnt   : in std_logic_vector(31 downto 0);
    post_rst_delay_timestamp : in std_logic_vector(31 downto 0);
    post_rst_delay_async     : in std_logic_vector(23 downto 0);

    -- trigger interface
    run_enable            : in  std_logic;
    run_pause             : in  std_logic;
    abort_run             : in  std_logic;
    no_beam_structure     : in  std_logic;
    enable_async_storage  : in  std_logic;
    global_count          : in  std_logic_vector( 3 downto 0);
    ofw_cycle_threshold   : in  std_logic_vector(23 downto 0);
    cycle_start_threshold : in  std_logic_vector(31 downto 0);
    eor_wait_count        : in  std_logic_vector(31 downto 0);
    trigger               : in  std_logic;
    send_ofw_boc          : in  std_logic;
    begin_of_cycle        : out std_logic;
    internal_trigger_strt : in  std_logic;
    internal_trigger_stop : in  std_logic;
    a6_missed_restart     : in  std_logic;
    trigger_clear         : out std_logic;

    -- transceiver checks
    eeprom_channel_sel : out std_logic_vector(  7 downto 0);
    eeprom_map_sel     : out std_logic;
    eeprom_start_adr   : out std_logic_vector(  7 downto 0);
    eeprom_num_regs    : out std_logic_vector(  5 downto 0);
    eeprom_read_start  : out std_logic;
    eeprom_reg         : in  std_logic_vector(127 downto 0);
    eeprom_reg_valid   : in  std_logic;

    -- trigger counts
    trig_count_seq0 : in std_logic_vector(3 downto 0);
    trig_count_seq1 : in std_logic_vector(3 downto 0);
    trig_count_seq2 : in std_logic_vector(3 downto 0);
    trig_count_seq3 : in std_logic_vector(3 downto 0);
    trig_count_seq4 : in std_logic_vector(3 downto 0);
    trig_count_seq5 : in std_logic_vector(3 downto 0);
    trig_count_seq6 : in std_logic_vector(3 downto 0);
    trig_count_seq7 : in std_logic_vector(3 downto 0);
    trig_count_seq8 : in std_logic_vector(3 downto 0);
    trig_count_seq9 : in std_logic_vector(3 downto 0);
    trig_count_seqa : in std_logic_vector(3 downto 0);
    trig_count_seqb : in std_logic_vector(3 downto 0);
    trig_count_seqc : in std_logic_vector(3 downto 0);
    trig_count_seqd : in std_logic_vector(3 downto 0);
    trig_count_seqe : in std_logic_vector(3 downto 0);
    trig_count_seqf : in std_logic_vector(3 downto 0);
    
    -- fill types
    trig_type_seq0 : in std_logic_vector(79 downto 0);
    trig_type_seq1 : in std_logic_vector(79 downto 0);
    trig_type_seq2 : in std_logic_vector(79 downto 0);
    trig_type_seq3 : in std_logic_vector(79 downto 0);
    trig_type_seq4 : in std_logic_vector(79 downto 0);
    trig_type_seq5 : in std_logic_vector(79 downto 0);
    trig_type_seq6 : in std_logic_vector(79 downto 0);
    trig_type_seq7 : in std_logic_vector(79 downto 0);
    trig_type_seq8 : in std_logic_vector(79 downto 0);
    trig_type_seq9 : in std_logic_vector(79 downto 0);
    trig_type_seqa : in std_logic_vector(79 downto 0);
    trig_type_seqb : in std_logic_vector(79 downto 0);
    trig_type_seqc : in std_logic_vector(79 downto 0);
    trig_type_seqd : in std_logic_vector(79 downto 0);
    trig_type_seqe : in std_logic_vector(79 downto 0);
    trig_type_seqf : in std_logic_vector(79 downto 0);

    -- pre-trigger gaps
    pre_trig_gap_seq0 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq1 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq2 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq3 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq4 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq5 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq6 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq7 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq8 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seq9 : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqa : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqb : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqc : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqd : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqe : in std_logic_vector(511 downto 0);
    pre_trig_gap_seqf : in std_logic_vector(511 downto 0);

    -- TTC interface
    channel_a       : out std_logic;
    channel_b_data  : out std_logic_vector(7 downto 0);
    channel_b_valid : out std_logic;

    -- trigger FIFO interface
    trig_timestamp    : out std_logic_vector( 43 downto 0);
    trig_num          : out std_logic_vector( 23 downto 0);
    trig_type_num_vec : out std_logic_vector(767 downto 0);
    trig_type         : out std_logic_vector(  4 downto 0);
    trig_delay        : out std_logic_vector( 31 downto 0);
    trig_index        : out std_logic_vector(  3 downto 0);
    trig_sub_index    : out std_logic_vector(  3 downto 0);
    trig_info_valid   : out std_logic;

    -- status signals
    overflow_warning        : in  std_logic;
    sfp_enabled_ports       : in  std_logic_vector( 7 downto 0);
    state                   : out std_logic_vector(17 downto 0);
    run_timer               : out std_logic_vector(63 downto 0);
    ofw_cycle_count_running : out std_logic_vector(23 downto 0);
    ofw_cycle_count         : out std_logic_vector(23 downto 0);
    ofw_limit_reached       : out std_logic;
    run_in_progress         : out std_logic;
    doing_run_checks        : out std_logic;
    resetting_clients       : out std_logic;
    finding_cycle_start     : out std_logic;
    run_aborted             : out std_logic;
    missing_trigger         : out std_logic;
    async_enable_sent       : out std_logic
  );
  end component;

  -- function to collapse a 16x16x5-bit array to a vector
  function collapse (matrix : array_16x16x5bit; index : integer) return std_logic_vector is
    variable vector : std_logic_vector(79 downto 0) := (others => '0');
  begin
    for i in 0 to 15 loop
      vector((5*i + 4) downto (5*i)) := matrix(index,i);
    end loop;
    return vector;
  end collapse;

  -- function to collapse a 16x16x32-bit array to a vector
  function collapse (matrix : array_16x16x32bit; index : integer) return std_logic_vector is
    variable vector : std_logic_vector(511 downto 0) := (others => '0');
  begin
    for i in 0 to 15 loop
      vector((32*i + 31) downto (32*i)) := matrix(index,i);
    end loop;
    return vector;
  end collapse;

  -- fill types
  signal trig_type_seq0 : std_logic_vector(79 downto 0);
  signal trig_type_seq1 : std_logic_vector(79 downto 0);
  signal trig_type_seq2 : std_logic_vector(79 downto 0);
  signal trig_type_seq3 : std_logic_vector(79 downto 0);
  signal trig_type_seq4 : std_logic_vector(79 downto 0);
  signal trig_type_seq5 : std_logic_vector(79 downto 0);
  signal trig_type_seq6 : std_logic_vector(79 downto 0);
  signal trig_type_seq7 : std_logic_vector(79 downto 0);
  signal trig_type_seq8 : std_logic_vector(79 downto 0);
  signal trig_type_seq9 : std_logic_vector(79 downto 0);
  signal trig_type_seqa : std_logic_vector(79 downto 0);
  signal trig_type_seqb : std_logic_vector(79 downto 0);
  signal trig_type_seqc : std_logic_vector(79 downto 0);
  signal trig_type_seqd : std_logic_vector(79 downto 0);
  signal trig_type_seqe : std_logic_vector(79 downto 0);
  signal trig_type_seqf : std_logic_vector(79 downto 0);

  -- pre-trigger gaps
  signal pre_trig_gap_seq0 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq1 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq2 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq3 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq4 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq5 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq6 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq7 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq8 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seq9 : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqa : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqb : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqc : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqd : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqe : std_logic_vector(511 downto 0);
  signal pre_trig_gap_seqf : std_logic_vector(511 downto 0);

  -- trigger type numbers
  signal trig_type_num_vec : std_logic_vector(767 downto 0);

begin

  -- collapse fill type matrix
  trig_type_seq0 <= collapse(trig_type_seq,  0);
  trig_type_seq1 <= collapse(trig_type_seq,  1);
  trig_type_seq2 <= collapse(trig_type_seq,  2);
  trig_type_seq3 <= collapse(trig_type_seq,  3);
  trig_type_seq4 <= collapse(trig_type_seq,  4);
  trig_type_seq5 <= collapse(trig_type_seq,  5);
  trig_type_seq6 <= collapse(trig_type_seq,  6);
  trig_type_seq7 <= collapse(trig_type_seq,  7);
  trig_type_seq8 <= collapse(trig_type_seq,  8);
  trig_type_seq9 <= collapse(trig_type_seq,  9);
  trig_type_seqa <= collapse(trig_type_seq, 10);
  trig_type_seqb <= collapse(trig_type_seq, 11);
  trig_type_seqc <= collapse(trig_type_seq, 12);
  trig_type_seqd <= collapse(trig_type_seq, 13);
  trig_type_seqe <= collapse(trig_type_seq, 14);
  trig_type_seqf <= collapse(trig_type_seq, 15);

  -- collapse pre-trigger gap matrix
  pre_trig_gap_seq0 <= collapse(pre_trig_gap_seq,  0);
  pre_trig_gap_seq1 <= collapse(pre_trig_gap_seq,  1);
  pre_trig_gap_seq2 <= collapse(pre_trig_gap_seq,  2);
  pre_trig_gap_seq3 <= collapse(pre_trig_gap_seq,  3);
  pre_trig_gap_seq4 <= collapse(pre_trig_gap_seq,  4);
  pre_trig_gap_seq5 <= collapse(pre_trig_gap_seq,  5);
  pre_trig_gap_seq6 <= collapse(pre_trig_gap_seq,  6);
  pre_trig_gap_seq7 <= collapse(pre_trig_gap_seq,  7);
  pre_trig_gap_seq8 <= collapse(pre_trig_gap_seq,  8);
  pre_trig_gap_seq9 <= collapse(pre_trig_gap_seq,  9);
  pre_trig_gap_seqa <= collapse(pre_trig_gap_seq, 10);
  pre_trig_gap_seqb <= collapse(pre_trig_gap_seq, 11);
  pre_trig_gap_seqc <= collapse(pre_trig_gap_seq, 12);
  pre_trig_gap_seqd <= collapse(pre_trig_gap_seq, 13);
  pre_trig_gap_seqe <= collapse(pre_trig_gap_seq, 14);
  pre_trig_gap_seqf <= collapse(pre_trig_gap_seq, 15);

  -- fill in trigger type number matrix
  trig_num_gen: for i in 0 to 31 generate
  begin
    trig_type_num(i) <= trig_type_num_vec((24*i + 23) downto (24*i));
  end generate;

  -- instaniate trigger_sequencer
  sequencer: trigger_sequencer
  port map (
    -- clock and reset
    clk => clk,
    rst => rst,

    -- reset interface
    post_rst_delay_evt_cnt   => post_rst_delay_evt_cnt,
    post_rst_delay_timestamp => post_rst_delay_timestamp,
    post_rst_delay_async     => post_rst_delay_async,

    -- trigger interface
    run_enable            => run_enable,
    run_pause             => run_pause,
    abort_run             => abort_run,
    no_beam_structure     => no_beam_structure,
    enable_async_storage  => enable_async_storage,
    global_count          => global_count,
    ofw_cycle_threshold   => ofw_cycle_threshold,
    cycle_start_threshold => cycle_start_threshold,
    eor_wait_count        => eor_wait_count,
    trigger               => trigger,
    send_ofw_boc          => send_ofw_boc,
    begin_of_cycle        => begin_of_cycle,
    internal_trigger_strt => internal_trigger_strt,
    internal_trigger_stop => internal_trigger_stop,
    a6_missed_restart     => a6_missed_restart,
    trigger_clear         => trigger_clear,

    -- transceiver checks
    eeprom_channel_sel => eeprom_channel_sel,
    eeprom_map_sel     => eeprom_map_sel,
    eeprom_start_adr   => eeprom_start_adr,
    eeprom_num_regs    => eeprom_num_regs,
    eeprom_read_start  => eeprom_read_start,
    eeprom_reg         => eeprom_reg,
    eeprom_reg_valid   => eeprom_reg_valid,

    -- trigger counts
    trig_count_seq0 => trig_count_seq( 0),
    trig_count_seq1 => trig_count_seq( 1),
    trig_count_seq2 => trig_count_seq( 2),
    trig_count_seq3 => trig_count_seq( 3),
    trig_count_seq4 => trig_count_seq( 4),
    trig_count_seq5 => trig_count_seq( 5),
    trig_count_seq6 => trig_count_seq( 6),
    trig_count_seq7 => trig_count_seq( 7),
    trig_count_seq8 => trig_count_seq( 8),
    trig_count_seq9 => trig_count_seq( 9),
    trig_count_seqa => trig_count_seq(10),
    trig_count_seqb => trig_count_seq(11),
    trig_count_seqc => trig_count_seq(12),
    trig_count_seqd => trig_count_seq(13),
    trig_count_seqe => trig_count_seq(14),
    trig_count_seqf => trig_count_seq(15),
    
    -- fill types
    trig_type_seq0 => trig_type_seq0,
    trig_type_seq1 => trig_type_seq1,
    trig_type_seq2 => trig_type_seq2,
    trig_type_seq3 => trig_type_seq3,
    trig_type_seq4 => trig_type_seq4,
    trig_type_seq5 => trig_type_seq5,
    trig_type_seq6 => trig_type_seq6,
    trig_type_seq7 => trig_type_seq7,
    trig_type_seq8 => trig_type_seq8,
    trig_type_seq9 => trig_type_seq9,
    trig_type_seqa => trig_type_seqa,
    trig_type_seqb => trig_type_seqb,
    trig_type_seqc => trig_type_seqc,
    trig_type_seqd => trig_type_seqd,
    trig_type_seqe => trig_type_seqe,
    trig_type_seqf => trig_type_seqf,

    -- pre-trigger gaps
    pre_trig_gap_seq0 => pre_trig_gap_seq0,
    pre_trig_gap_seq1 => pre_trig_gap_seq1,
    pre_trig_gap_seq2 => pre_trig_gap_seq2,
    pre_trig_gap_seq3 => pre_trig_gap_seq3,
    pre_trig_gap_seq4 => pre_trig_gap_seq4,
    pre_trig_gap_seq5 => pre_trig_gap_seq5,
    pre_trig_gap_seq6 => pre_trig_gap_seq6,
    pre_trig_gap_seq7 => pre_trig_gap_seq7,
    pre_trig_gap_seq8 => pre_trig_gap_seq8,
    pre_trig_gap_seq9 => pre_trig_gap_seq9,
    pre_trig_gap_seqa => pre_trig_gap_seqa,
    pre_trig_gap_seqb => pre_trig_gap_seqb,
    pre_trig_gap_seqc => pre_trig_gap_seqc,
    pre_trig_gap_seqd => pre_trig_gap_seqd,
    pre_trig_gap_seqe => pre_trig_gap_seqe,
    pre_trig_gap_seqf => pre_trig_gap_seqf,

    -- TTC interface
    channel_a       => channel_a,
    channel_b_data  => channel_b_data,
    channel_b_valid => channel_b_valid,

    -- trigger FIFO interface
    trig_timestamp    => trig_timestamp,
    trig_num          => trig_num,
    trig_type_num_vec => trig_type_num_vec,
    trig_type         => trig_type,
    trig_delay        => trig_delay,
    trig_index        => trig_index,
    trig_sub_index    => trig_sub_index,
    trig_info_valid   => trig_info_valid,

    -- status signals
    overflow_warning        => overflow_warning,
    sfp_enabled_ports       => sfp_enabled_ports,
    state                   => state,
    run_timer               => run_timer,
    ofw_cycle_count_running => ofw_cycle_count_running,
    ofw_cycle_count         => ofw_cycle_count,
    ofw_limit_reached       => ofw_limit_reached,
    doing_run_checks        => doing_run_checks,
    run_in_progress         => run_in_progress,
    resetting_clients       => resetting_clients,
    finding_cycle_start     => finding_cycle_start,
    run_aborted             => run_aborted,
    missing_trigger         => missing_trigger,
    async_enable_sent       => async_enable_sent
  );

end Behavioral;
