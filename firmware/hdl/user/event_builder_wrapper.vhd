-- Wrapper to instantiate event_builder.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity event_builder_wrapper is
port (
  clk : in std_logic;
  rst : in std_logic;

  -- data connections
  m_trig_info_fifo_tvalid : in  std_logic;
  m_trig_info_fifo_tready : out std_logic;
  m_trig_info_fifo_tdata  : in  std_logic_vector(127 downto 0);

  m_pulse_info_fifo_tvalid : in  std_logic;
  m_pulse_info_fifo_tready : out std_logic;
  m_pulse_info_fifo_tdata  : in  std_logic_vector(2047 downto 0);

  -- controls
  ttc_trigger : in std_logic;

  -- static event information
  fc7_type           : in std_logic_vector( 1 downto 0);
  major_rev          : in std_logic_vector( 7 downto 0);
  minor_rev          : in std_logic_vector( 7 downto 0);
  patch_rev          : in std_logic_vector( 7 downto 0);
  board_id           : in std_logic_vector(10 downto 0);
  l12_fmc_id         : in std_logic_vector( 7 downto 0);
  l8_fmc_id          : in std_logic_vector( 7 downto 0);
  otrig_disable_a    : in std_logic;
  otrig_disable_b    : in std_logic;
  otrig_delay_a      : in std_logic_vector(31 downto 0);
  otrig_delay_b      : in std_logic_vector(31 downto 0);
  otrig_width_a      : in std_logic_vector( 7 downto 0);
  otrig_width_b      : in std_logic_vector( 7 downto 0);
  tts_lock_thres     : in std_logic_vector(31 downto 0);
  ofw_watchdog_thres : in std_logic_vector(23 downto 0);
  l12_enabled_ports  : in std_logic_vector( 7 downto 0);
  l8_enabled_ports   : in std_logic_vector( 7 downto 0);
  l12_tts_mask       : in std_logic_vector( 7 downto 0);
  l8_tts_mask        : in std_logic_vector( 7 downto 0);
  l12_ttc_delays     : in array_8x8bit;
  l8_ttc_delays      : in array_8x8bit;
  l12_sfp_sn         : in array_8x128bit;
  l8_sfp_sn          : in array_8x128bit;

  -- variable event information
  l12_tts_state             : in std_logic_vector(31 downto 0);
  l8_tts_state              : in std_logic_vector(31 downto 0);
  l12_tts_lock              : in std_logic_vector( 7 downto 0);
  l8_tts_lock               : in std_logic_vector( 7 downto 0);
  l12_tts_lock_mux          : in std_logic;
  l8_tts_lock_mux           : in std_logic;
  ext_clk_lock              : in std_logic;
  ttc_clk_lock              : in std_logic;
  ttc_ready                 : in std_logic;
  xadc_alarms               : in std_logic_vector( 3 downto 0);
  error_flag                : in std_logic;
  error_l12_fmc_absent      : in std_logic;
  error_l8_fmc_absent       : in std_logic;
  change_error_l12_mod_abs  : in std_logic_vector( 7 downto 0);
  change_error_l8_mod_abs   : in std_logic_vector( 7 downto 0);
  change_error_l12_tx_fault : in std_logic_vector( 7 downto 0);
  change_error_l8_tx_fault  : in std_logic_vector( 7 downto 0);
  change_error_l12_rx_los   : in std_logic_vector( 7 downto 0);
  change_error_l8_rx_los    : in std_logic_vector( 7 downto 0);

  -- interface to AMC13 DAQ Link
  daq_ready       : in  std_logic;
  daq_almost_full : in  std_logic;
  daq_valid       : out std_logic;
  daq_header      : out std_logic;
  daq_trailer     : out std_logic;
  daq_data        : out std_logic_vector(63 downto 0);

  -- status
  state : out std_logic_vector(18 downto 0)
);
end event_builder_wrapper;

architecture Behavioral of event_builder_wrapper is

  component event_builder is 
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- data connections
    m_trig_info_fifo_tvalid : in  std_logic;
    m_trig_info_fifo_tready : out std_logic;
    m_trig_info_fifo_tdata  : in  std_logic_vector(127 downto 0);

    m_pulse_info_fifo_tvalid : in  std_logic;
    m_pulse_info_fifo_tready : out std_logic;
    m_pulse_info_fifo_tdata  : in  std_logic_vector(2047 downto 0);

    -- controls
    ttc_trigger : in std_logic;

    -- static event information
    fc7_type             : in std_logic_vector(   1 downto 0);
    major_rev            : in std_logic_vector(   7 downto 0);
    minor_rev            : in std_logic_vector(   7 downto 0);
    patch_rev            : in std_logic_vector(   7 downto 0);
    board_id             : in std_logic_vector(  10 downto 0);
    l12_fmc_id           : in std_logic_vector(   7 downto 0);
    l8_fmc_id            : in std_logic_vector(   7 downto 0);
    otrig_disable_a      : in std_logic;
    otrig_disable_b      : in std_logic;
    otrig_delay_a        : in std_logic_vector(  31 downto 0);
    otrig_delay_b        : in std_logic_vector(  31 downto 0);
    otrig_width_a        : in std_logic_vector(   7 downto 0);
    otrig_width_b        : in std_logic_vector(   7 downto 0);
    tts_lock_thres       : in std_logic_vector(  31 downto 0);
    ofw_watchdog_thres   : in std_logic_vector(  23 downto 0);
    l12_enabled_ports    : in std_logic_vector(   7 downto 0);
    l8_enabled_ports     : in std_logic_vector(   7 downto 0);
    l12_tts_mask         : in std_logic_vector(   7 downto 0);
    l8_tts_mask          : in std_logic_vector(   7 downto 0);
    l12_ttc_delays       : in std_logic_vector(  63 downto 0);
    l8_ttc_delays        : in std_logic_vector(  63 downto 0);
    l12_sfp_sn_vec       : in std_logic_vector(1023 downto 0);
    l8_sfp_sn_vec        : in std_logic_vector(1023 downto 0);

    -- variable event information
    l12_tts_state             : in std_logic_vector(31 downto 0);
    l8_tts_state              : in std_logic_vector(31 downto 0);
    l12_tts_lock              : in std_logic_vector( 7 downto 0);
    l8_tts_lock               : in std_logic_vector( 7 downto 0);
    l12_tts_lock_mux          : in std_logic;
    l8_tts_lock_mux           : in std_logic;
    ext_clk_lock              : in std_logic;
    ttc_clk_lock              : in std_logic;
    ttc_ready                 : in std_logic;
    xadc_alarms               : in std_logic_vector( 3 downto 0);
    error_flag                : in std_logic;
    error_l12_fmc_absent      : in std_logic;
    error_l8_fmc_absent       : in std_logic;
    change_error_l12_mod_abs  : in std_logic_vector( 7 downto 0);
    change_error_l8_mod_abs   : in std_logic_vector( 7 downto 0);
    change_error_l12_tx_fault : in std_logic_vector( 7 downto 0);
    change_error_l8_tx_fault  : in std_logic_vector( 7 downto 0);
    change_error_l12_rx_los   : in std_logic_vector( 7 downto 0);
    change_error_l8_rx_los    : in std_logic_vector( 7 downto 0);

    -- interface to AMC13 DAQ Link
    daq_ready       : in  std_logic;
    daq_almost_full : in  std_logic;
    daq_valid       : out std_logic;
    daq_header      : out std_logic;
    daq_trailer     : out std_logic;
    daq_data        : out std_logic_vector(63 downto 0);

    -- status
    state : out std_logic_vector(18 downto 0)
  );
  end component;

  -- function to collapse an 8x8-bit array to a vector
  function collapse (matrix : array_8x8bit) return std_logic_vector is
    variable vector : std_logic_vector(63 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      vector((8*i + 7) downto (8*i)) := matrix(i);
    end loop;
    return vector;
  end collapse;

  -- function to collapse an 8x128-bit array to a vector
  function collapse (matrix : array_8x128bit) return std_logic_vector is
    variable vector : std_logic_vector(1023 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      vector((128*i + 127) downto (128*i)) := matrix(i);
    end loop;
    return vector;
  end collapse;

  -- function to collapse an 32x32-bit array to a vector
  function collapse (matrix : array_32x32bit) return std_logic_vector is
    variable vector : std_logic_vector(1023 downto 0) := (others => '0');
  begin
    for i in 0 to 31 loop
      vector((32*i + 31) downto (32*i)) := matrix(i);
    end loop;
    return vector;
  end collapse;

  signal fc7_type_sync                  : std_logic_vector(   1 downto 0); 
  signal major_rev_sync                 : std_logic_vector(   7 downto 0);
  signal minor_rev_sync                 : std_logic_vector(   7 downto 0);
  signal patch_rev_sync                 : std_logic_vector(   7 downto 0);
  signal board_id_sync                  : std_logic_vector(  10 downto 0);
  signal l12_fmc_id_sync                : std_logic_vector(   7 downto 0);
  signal l8_fmc_id_sync                 : std_logic_vector(   7 downto 0);
  signal otrig_disable_a_sync           : std_logic;
  signal otrig_disable_b_sync           : std_logic;
  signal otrig_delay_a_sync             : std_logic_vector(  31 downto 0);
  signal otrig_delay_b_sync             : std_logic_vector(  31 downto 0);
  signal otrig_width_a_sync             : std_logic_vector(   7 downto 0);
  signal otrig_width_b_sync             : std_logic_vector(   7 downto 0);
  signal tts_lock_thres_sync            : std_logic_vector(  31 downto 0);
  signal ofw_watchdog_thres_sync        : std_logic_vector(  23 downto 0);
  signal l12_enabled_ports_sync         : std_logic_vector(   7 downto 0);
  signal l8_enabled_ports_sync          : std_logic_vector(   7 downto 0);
  signal l12_tts_mask_sync              : std_logic_vector(   7 downto 0);
  signal l8_tts_mask_sync               : std_logic_vector(   7 downto 0);
  signal l12_ttc_delays_vec             : std_logic_vector(  63 downto 0);
  signal l8_ttc_delays_vec              : std_logic_vector(  63 downto 0);
  signal l12_ttc_delays_vec_sync        : std_logic_vector(  63 downto 0);
  signal l8_ttc_delays_vec_sync         : std_logic_vector(  63 downto 0);
  signal l12_sfp_sn_vec                 : std_logic_vector(1023 downto 0);
  signal l8_sfp_sn_vec                  : std_logic_vector(1023 downto 0);
  signal l12_sfp_sn_vec_sync            : std_logic_vector(1023 downto 0);
  signal l8_sfp_sn_vec_sync             : std_logic_vector(1023 downto 0);
  signal l12_tts_state_sync             : std_logic_vector(  31 downto 0);
  signal l8_tts_state_sync              : std_logic_vector(  31 downto 0);
  signal l12_tts_lock_sync              : std_logic_vector(   7 downto 0);
  signal l8_tts_lock_sync               : std_logic_vector(   7 downto 0);
  signal l12_tts_lock_mux_sync          : std_logic;
  signal l8_tts_lock_mux_sync           : std_logic;
  signal ext_clk_lock_sync              : std_logic;
  signal ttc_clk_lock_sync              : std_logic;
  signal ttc_ready_sync                 : std_logic;
  signal xadc_alarms_sync               : std_logic_vector(   3 downto 0);
  signal error_flag_sync                : std_logic;
  signal error_l12_fmc_absent_sync      : std_logic;
  signal error_l8_fmc_absent_sync       : std_logic;
  signal change_error_l12_mod_abs_sync  : std_logic_vector(   7 downto 0);
  signal change_error_l8_mod_abs_sync   : std_logic_vector(   7 downto 0);
  signal change_error_l12_tx_fault_sync : std_logic_vector(   7 downto 0);
  signal change_error_l8_tx_fault_sync  : std_logic_vector(   7 downto 0);
  signal change_error_l12_rx_los_sync   : std_logic_vector(   7 downto 0);
  signal change_error_l8_rx_los_sync    : std_logic_vector(   7 downto 0);

begin

  -- --------------
  -- array collapse
  -- --------------

  l12_ttc_delays_vec <= collapse(l12_ttc_delays);
  l8_ttc_delays_vec  <= collapse(l8_ttc_delays );
  l12_sfp_sn_vec     <= collapse(l12_sfp_sn    );
  l8_sfp_sn_vec      <= collapse(l8_sfp_sn     );


  -- ---------------
  -- synchronization
  -- ---------------

  sync00_inst: entity work.sync_2stage generic map (nbr_bits =>    2) port map ( clk => clk, sig_i    => fc7_type,                  sig_o    => fc7_type_sync                  );
  sync01_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => major_rev,                 sig_o    => major_rev_sync                 );
  sync02_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => minor_rev,                 sig_o    => minor_rev_sync                 );
  sync03_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => patch_rev,                 sig_o    => patch_rev_sync                 );
  sync04_inst: entity work.sync_2stage generic map (nbr_bits =>   11) port map ( clk => clk, sig_i    => board_id,                  sig_o    => board_id_sync                  );
  sync05_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l12_fmc_id,                sig_o    => l12_fmc_id_sync                );
  sync06_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l8_fmc_id,                 sig_o    => l8_fmc_id_sync                 );
  sync07_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => otrig_disable_a,           sig_o(0) => otrig_disable_a_sync           );
  sync08_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => otrig_disable_b,           sig_o(0) => otrig_disable_b_sync           );
  sync09_inst: entity work.sync_2stage generic map (nbr_bits =>   32) port map ( clk => clk, sig_i    => otrig_delay_a,             sig_o    => otrig_delay_a_sync             );
  sync10_inst: entity work.sync_2stage generic map (nbr_bits =>   32) port map ( clk => clk, sig_i    => otrig_delay_b,             sig_o    => otrig_delay_b_sync             );
  sync11_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => otrig_width_a,             sig_o    => otrig_width_a_sync             );
  sync12_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => otrig_width_b,             sig_o    => otrig_width_b_sync             );
  sync13_inst: entity work.sync_2stage generic map (nbr_bits =>   32) port map ( clk => clk, sig_i    => tts_lock_thres,            sig_o    => tts_lock_thres_sync            );
  sync14_inst: entity work.sync_2stage generic map (nbr_bits =>   24) port map ( clk => clk, sig_i    => ofw_watchdog_thres,        sig_o    => ofw_watchdog_thres_sync        );
  sync15_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l12_enabled_ports,         sig_o    => l12_enabled_ports_sync         );
  sync16_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l8_enabled_ports,          sig_o    => l8_enabled_ports_sync          );
  sync17_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l12_tts_mask,              sig_o    => l12_tts_mask_sync              );
  sync18_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l8_tts_mask,               sig_o    => l8_tts_mask_sync               );
  sync19_inst: entity work.sync_2stage generic map (nbr_bits =>   64) port map ( clk => clk, sig_i    => l12_ttc_delays_vec,        sig_o    => l12_ttc_delays_vec_sync        );
  sync20_inst: entity work.sync_2stage generic map (nbr_bits =>   64) port map ( clk => clk, sig_i    => l8_ttc_delays_vec,         sig_o    => l8_ttc_delays_vec_sync         );
  sync21_inst: entity work.sync_2stage generic map (nbr_bits => 1024) port map ( clk => clk, sig_i    => l12_sfp_sn_vec,            sig_o    => l12_sfp_sn_vec_sync            );
  sync22_inst: entity work.sync_2stage generic map (nbr_bits => 1024) port map ( clk => clk, sig_i    => l8_sfp_sn_vec,             sig_o    => l8_sfp_sn_vec_sync             );
  sync23_inst: entity work.sync_2stage generic map (nbr_bits =>   32) port map ( clk => clk, sig_i    => l12_tts_state,             sig_o    => l12_tts_state_sync             );
  sync24_inst: entity work.sync_2stage generic map (nbr_bits =>   32) port map ( clk => clk, sig_i    => l8_tts_state,              sig_o    => l8_tts_state_sync              );
  sync25_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l12_tts_lock,              sig_o    => l12_tts_lock_sync              );
  sync26_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => l8_tts_lock,               sig_o    => l8_tts_lock_sync               );
  sync27_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => l12_tts_lock_mux,          sig_o(0) => l12_tts_lock_mux_sync          );
  sync28_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => l8_tts_lock_mux,           sig_o(0) => l8_tts_lock_mux_sync           );
  sync29_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => ext_clk_lock,              sig_o(0) => ext_clk_lock_sync              );
  sync30_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => ttc_clk_lock,              sig_o(0) => ttc_clk_lock_sync              );
  sync31_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => ttc_ready,                 sig_o(0) => ttc_ready_sync                 );
  sync32_inst: entity work.sync_2stage generic map (nbr_bits =>    4) port map ( clk => clk, sig_i    => xadc_alarms,               sig_o    => xadc_alarms_sync               );
  sync33_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => error_flag,                sig_o(0) => error_flag_sync                );
  sync34_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => error_l12_fmc_absent,      sig_o(0) => error_l12_fmc_absent_sync      );
  sync35_inst: entity work.sync_2stage generic map (nbr_bits =>    1) port map ( clk => clk, sig_i(0) => error_l8_fmc_absent,       sig_o(0) => error_l8_fmc_absent_sync       );
  sync36_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l12_mod_abs,  sig_o    => change_error_l12_mod_abs_sync  );
  sync37_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l8_mod_abs,   sig_o    => change_error_l8_mod_abs_sync   );
  sync38_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l12_tx_fault, sig_o    => change_error_l12_tx_fault_sync );
  sync39_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l8_tx_fault,  sig_o    => change_error_l8_tx_fault_sync  );
  sync40_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l12_rx_los,   sig_o    => change_error_l12_rx_los_sync   );
  sync41_inst: entity work.sync_2stage generic map (nbr_bits =>    8) port map ( clk => clk, sig_i    => change_error_l8_rx_los,    sig_o    => change_error_l8_rx_los_sync    );

  -- ---------------
  -- module instance
  -- ---------------

  event_builder_inst: event_builder
  port map (
    clk => clk,
    rst => rst,

    -- data connections
    m_trig_info_fifo_tvalid => m_trig_info_fifo_tvalid,
    m_trig_info_fifo_tready => m_trig_info_fifo_tready,
    m_trig_info_fifo_tdata  => m_trig_info_fifo_tdata,

    m_pulse_info_fifo_tvalid => m_pulse_info_fifo_tvalid,
    m_pulse_info_fifo_tready => m_pulse_info_fifo_tready,
    m_pulse_info_fifo_tdata  => m_pulse_info_fifo_tdata,

    -- controls
    ttc_trigger => ttc_trigger,

    -- static event information
    fc7_type           => fc7_type_sync,
    major_rev          => major_rev_sync,
    minor_rev          => minor_rev_sync,
    patch_rev          => patch_rev_sync,
    board_id           => board_id_sync,
    l12_fmc_id         => l12_fmc_id_sync,
    l8_fmc_id          => l8_fmc_id_sync,
    otrig_disable_a    => otrig_disable_a_sync,
    otrig_disable_b    => otrig_disable_b_sync,
    otrig_delay_a      => otrig_delay_a_sync,
    otrig_delay_b      => otrig_delay_b_sync,
    otrig_width_a      => otrig_width_a_sync,
    otrig_width_b      => otrig_width_b_sync,
    tts_lock_thres     => tts_lock_thres_sync,
    ofw_watchdog_thres => ofw_watchdog_thres_sync,
    l12_enabled_ports  => l12_enabled_ports_sync,
    l8_enabled_ports   => l8_enabled_ports_sync,
    l12_tts_mask       => l12_tts_mask_sync,
    l8_tts_mask        => l8_tts_mask_sync,
    l12_ttc_delays     => l12_ttc_delays_vec_sync,
    l8_ttc_delays      => l8_ttc_delays_vec_sync,
    l12_sfp_sn_vec     => l12_sfp_sn_vec_sync,
    l8_sfp_sn_vec      => l8_sfp_sn_vec_sync,

    -- variable event information
    l12_tts_state             => l12_tts_state_sync,
    l8_tts_state              => l8_tts_state_sync,
    l12_tts_lock              => l12_tts_lock_sync,
    l8_tts_lock               => l8_tts_lock_sync,
    l12_tts_lock_mux          => l12_tts_lock_mux_sync,
    l8_tts_lock_mux           => l8_tts_lock_mux_sync,
    ext_clk_lock              => ext_clk_lock_sync,
    ttc_clk_lock              => ttc_clk_lock_sync,
    ttc_ready                 => ttc_ready_sync,
    xadc_alarms               => xadc_alarms_sync,
    error_flag                => error_flag_sync,
    error_l12_fmc_absent      => error_l12_fmc_absent_sync,
    error_l8_fmc_absent       => error_l8_fmc_absent_sync,
    change_error_l12_mod_abs  => change_error_l12_mod_abs_sync,
    change_error_l8_mod_abs   => change_error_l8_mod_abs_sync,
    change_error_l12_tx_fault => change_error_l12_tx_fault_sync,
    change_error_l8_tx_fault  => change_error_l8_tx_fault_sync,
    change_error_l12_rx_los   => change_error_l12_rx_los_sync,
    change_error_l8_rx_los    => change_error_l8_rx_los_sync,

    -- interface to AMC13 DAQ Link
    daq_ready       => daq_ready,
    daq_almost_full => daq_almost_full,
    daq_valid       => daq_valid,
    daq_header      => daq_header,
    daq_trailer     => daq_trailer,
    daq_data        => daq_data,

    -- status
    state => state
  );

end Behavioral;
