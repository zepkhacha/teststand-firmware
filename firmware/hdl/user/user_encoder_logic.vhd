-- Top-level module for the Encoder FC7 user logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

-- user packages
use work.ipbus.all;
use work.system_package.all;
use work.user_package.all;
use work.user_version_package.all;

library unisim;
use unisim.vcomponents.all;

entity user_encoder_logic is 
port (
    -- clocks
    fmc_header_n : in std_logic_vector(31 downto 0); -- taken by example from user_trigger_logic.vhd -- 40.00 MHz
    ipb_clk : in std_logic; -- 31.25 MHz

    fabric_clk_p : in std_logic;
    fabric_clk_n : in std_logic;

    osc125_a_bufg      : in std_logic;
    osc125_a_mgtrefclk : in std_logic;
    osc125_b_bufg      : in std_logic;
    osc125_b_mgtrefclk : in std_logic;

    -- LEDs
    top_led3 : out std_logic_vector(2 downto 0);
    top_led2 : out std_logic_vector(2 downto 0);
    bot_led1 : out std_logic_vector(2 downto 0);
    bot_led2 : out std_logic_vector(2 downto 0);

    fmc_l8_led1 : out std_logic_vector(1 downto 0);
    fmc_l8_led2 : out std_logic_vector(1 downto 0);
    fmc_l8_led  : out std_logic_vector(8 downto 3);

    -- FMC status
    fmc_l12_absent : in std_logic;
    fmc_l8_absent  : in std_logic;

    -- FMC LEMOs
    aux_lemo_a : in  std_logic;
    aux_lemo_b : out std_logic;
    tr0_lemo_p : in  std_logic;
    tr0_lemo_n : in  std_logic;
    tr1_lemo_p : in  std_logic;
    tr1_lemo_n : in  std_logic;

    -- FMC SFP
    sfp_l12_rx_p : in  std_logic_vector(7 downto 0);
    sfp_l12_rx_n : in  std_logic_vector(7 downto 0);
    sfp_l12_tx_p : out std_logic_vector(7 downto 0);
    sfp_l12_tx_n : out std_logic_vector(7 downto 0);

    -- FMC I2C
    i2c_fmc_scl : inout std_logic;
    i2c_fmc_sda : inout std_logic;

    i2c_l12_scl : inout std_logic;
    i2c_l12_sda : inout std_logic;
    i2c_l12_rst : out   std_logic;
    i2c_l12_int : in    std_logic;

    i2c_l8_scl : inout std_logic;
    i2c_l8_sda : inout std_logic;
    i2c_l8_rst : out   std_logic;

    -- DAQ link
    daq_rxp : in  std_logic;
    daq_rxn : in  std_logic;
    daq_txp : out std_logic;
    daq_txn : out std_logic;
    
    -- TTC signal
    ttc_rx_p : in std_logic;
    ttc_rx_n : in std_logic;

    -- CDCE
    cdce_ref_sel_o  : out std_logic;
    cdce_pwrdown_o  : out std_logic;
    cdce_sync_o     : out std_logic;
    cdce_sync_clk_o : out std_logic;
    
    -- IPbus
    ipb_rst_i  : in  std_logic;
    ipb_mosi_i : in  ipb_wbus_array(0 to nbr_usr_enc_slaves-1);
    ipb_miso_o : out ipb_rbus_array(0 to nbr_usr_enc_slaves-1);

    -- other
    reprog_fpga : out std_logic;
    user_reset  : out std_logic;
    board_id    : in  std_logic_vector(10 downto 0)
);
end user_encoder_logic;

architecture usr of user_encoder_logic is

    -- clocks
    signal ext_clk_x4  : std_logic;
    signal ttc_clk     : std_logic;
    signal ttc_clk_x2  : std_logic;
    signal ttc_clk_x5  : std_logic;
    signal ttc_clk_x10 : std_logic;

    -- clock wizard locks
    signal ext_clk_lock : std_logic;
    signal ttc_clk_lock : std_logic;

    -- resets
    signal rst_ext_n           : std_logic;
    signal rst_ext_x4          : std_logic;
    signal rst_from_ipbus      : std_logic;
    signal soft_rst_from_ipbus : std_logic;
    signal rst_ipb             : std_logic;
    signal rst_ipb_stretch     : std_logic;
    signal init_rst_ipb        : std_logic;
    signal sys_rst_ipb         : std_logic;

    signal rst_osc125, hard_rst_osc125, soft_rst_osc125, auto_soft_rst_osc125 : std_logic;
    signal rst_ttc,    hard_rst_ttc,    soft_rst_ttc,    auto_soft_rst_ttc    : std_logic;
    signal rst_ext,    hard_rst_ext,    soft_rst_ext,    auto_soft_rst_ext    : std_logic;

    signal auto_soft_rst         : std_logic;
    signal auto_soft_rst_sync1   : std_logic;
    signal auto_soft_rst_sync2   : std_logic;
    signal auto_soft_rst_sync3   : std_logic;
    signal auto_soft_rst_stretch : std_logic;
    signal auto_soft_rst_delay   : std_logic;

    signal i2c_l12_rst_from_ipb     : std_logic;
    signal i2c_l8_rst_from_ipb      : std_logic;
    signal tts_rx_rst_l12_from_ipb  : std_logic;
    signal ttc_decoder_rst_from_ipb : std_logic;
    signal ttc_decoder_rst          : std_logic;

    -- triggers
    signal tr0_lemo,       tr0_lemo_inv     : std_logic;
    signal tr1_lemo,       tr1_lemo_inv     : std_logic;
    signal trx_lemo_sel,   trx_lemo_inv     : std_logic;
    signal acc_trigger,    trigger_from_ttc : std_logic;
    signal trigger_from_ttc_esync           : std_logic;
    signal measured_trigger                 : std_logic;
    signal latched_trigger                  : std_logic;
    signal clear_latched_trigger            : std_logic;
    signal latch_clock_enable               : std_logic;
    signal clear_latched_trigger_delayed    : std_logic;
    signal clear_latched_trigger_pulse      : std_logic;
    signal trig_latch_clear_delay           : std_logic_vector(31 downto 0);
    signal trigger_out_a,  trigger_out_b    : std_logic;
    signal trig_clk125,    trig_clk125_sync : std_logic;
    signal ttc_raw_trigger                  : std_logic;
    signal begin_of_cycle                   : std_logic;
    signal internal_trigger_strt            : std_logic;
    signal internal_trigger_stop            : std_logic;
    signal missed_a6_seq_restart            : std_logic;
    signal missed_a6_trigger_fc7            : std_logic;
    signal internal_trigger_strt_pulse      : std_logic;
    signal internal_trigger_stop_pulse      : std_logic;
    signal missing_a6                       : std_logic;
    signal missed_A6_count                  : std_logic_vector(7 downto 0);
    signal oosync_gap_threshold             : std_logic_vector(31 downto 0);
    signal boc_oos                          : std_logic;
    signal reset_local_counter              : std_logic;
    signal fill_count_local                 : std_logic_vector(4 downto 0);
    signal async_enable_sent                : std_logic;

    -- IPbus slave registers
    signal stat_reg : stat_reg_t;
    signal ctrl_reg : ctrl_reg_t;
    signal seqr_reg : array_16x32x32bit;
    
    -- delays
    signal trigger_delay_a, trigger_delay_a_ext : std_logic_vector(31 downto 0);
    signal trigger_delay_b, trigger_delay_b_ext : std_logic_vector(31 downto 0);

    signal l12_ttc_encoded_delay, l12_ttc_encoded_delay_ttc : array_8x8bit;

    -- TTC encoding
    signal ttc_data    : std_logic_vector(15 downto 0);
    signal ttc_encoded : std_logic;

    signal sfp_l12_tx, sfp_l12_tx_delay : std_logic_vector(7 downto 0);

    -- TTC decoder
    signal ttc_bcnt_reset   : std_logic;
    signal ttc_evt_reset    : std_logic;
    signal ttc_ready        : std_logic;
    signal ttc_sbit_error   : std_logic;
    signal ttc_mbit_error   : std_logic;
    signal ttc_chan_b_valid : std_logic;
    signal ttc_chan_b_info  : std_logic_vector(7 downto 2);

    signal ttc_sbit_error_cnt_global, ttc_mbit_error_cnt_global : std_logic_vector(31 downto 0);
    signal ttc_sbit_error_cnt,        ttc_mbit_error_cnt        : std_logic_vector(31 downto 0);
    signal ttc_sbit_error_threshold,  ttc_mbit_error_threshold  : std_logic_vector(31 downto 0);
    signal error_ttc_sbit_limit,      error_ttc_mbit_limit      : std_logic;

    signal trig_out_disable_a, trig_out_disable_a_ext : std_logic;
    signal trig_out_disable_b, trig_out_disable_b_ext : std_logic;

    signal var_width_a, var_width_a_ext : std_logic_vector(7 downto 0);
    signal var_width_b, var_width_b_ext : std_logic_vector(7 downto 0);

    -- DAQ link
    signal daq_data        : std_logic_vector(63 downto 0);
    signal daq_almost_full : std_logic;
    signal daq_ready       : std_logic;
    signal daq_valid       : std_logic;
    signal daq_header      : std_logic;
    signal daq_trailer     : std_logic;
    signal daq_link_trig   : std_logic_vector( 7 downto 0);

    -- finite state machine states
    signal ts_state  : std_logic_vector(17 downto 0);
    signal eb_state  : std_logic_vector(18 downto 0);
    signal tis_state : std_logic_vector( 1 downto 0);
    signal fe_state  : std_logic_vector(11 downto 0);

    signal l8_fs_state,  l12_fs_state  : std_logic_vector(27 downto 0);
    signal l8_sgr_state, l12_sgr_state : std_logic_vector( 6 downto 0);
    signal l8_ssc_state, l12_ssc_state : std_logic_vector(10 downto 0);
    signal l8_st_state,  l12_st_state  : std_logic_vector(32 downto 0);

    -- trigger sequencer information
    signal run_enable, run_enable_sync : std_logic;
    signal run_pause,  run_pause_sync  : std_logic;
    signal no_beam_structure           : std_logic;

    signal force_exit : std_logic;

    signal enable_async_storage      : std_logic;
    signal enable_async_storage_sync : std_logic;

    signal seq_trig_type,    seq_trig_type_sync,    seq_trig_type_sync1,    seq_trig_type_sync2    : array_16x16x5bit;
    signal seq_pre_trig_gap, seq_pre_trig_gap_sync, seq_pre_trig_gap_sync1, seq_pre_trig_gap_sync2 : array_16x16x32bit;
    signal seq_count,        seq_count_sync,        seq_count_sync1,        seq_count_sync2        : array_16x4bit;

    signal global_seq_count      : std_logic_vector(3 downto 0);
    signal global_seq_count_sync : std_logic_vector(3 downto 0);

    signal trig_info_valid : std_logic;
    signal trig_num        : std_logic_vector(23 downto 0);
    signal trig_type_num   : array_32x24bit;
    signal trig_timestamp  : std_logic_vector(43 downto 0);
    signal trig_type       : std_logic_vector( 4 downto 0);
    signal trig_delay      : std_logic_vector(31 downto 0);
    signal trig_index      : std_logic_vector( 3 downto 0);
    signal trig_sub_index  : std_logic_vector( 3 downto 0);

    signal channel_a_from_seq : std_logic;
    signal a_channel          : std_logic;
    signal a_channel1         : std_logic;
    signal a_channel2         : std_logic;
    signal a_channel3         : std_logic;
    signal a_channel_sync     : std_logic;

    signal channel_b_data_from_seq : std_logic_vector(7 downto 0);
    signal b_channel               : std_logic_vector(7 downto 0);
    signal b_channel1              : std_logic_vector(7 downto 0);
    signal b_channel2              : std_logic_vector(7 downto 0);

    signal channel_b_valid_from_seq : std_logic;
    signal b_channel_valid          : std_logic;
    signal b_channel_valid1         : std_logic;
    signal b_channel_valid2         : std_logic;
    signal b_channel_valid3         : std_logic;
    signal b_channel_valid_sync     : std_logic;

    signal run_timer           : std_logic_vector(63 downto 0);
    signal run_in_progress     : std_logic;
    signal doing_run_checks    : std_logic;
    signal resetting_clients   : std_logic;
    signal finding_cycle_start : std_logic;
    signal run_aborted         : std_logic;

    signal seq_eeprom_channel_sel : std_logic_vector(7 downto 0);
    signal seq_eeprom_map_sel     : std_logic;
    signal seq_eeprom_start_adr   : std_logic_vector(7 downto 0);
    signal seq_eeprom_num_regs    : std_logic_vector(5 downto 0);
    signal seq_eeprom_read_start  : std_logic;

    signal seq_eeprom_channel_sel_sync : std_logic_vector(7 downto 0);
    signal seq_eeprom_map_sel_sync     : std_logic;
    signal seq_eeprom_start_adr_sync   : std_logic_vector(7 downto 0);
    signal seq_eeprom_num_regs_sync    : std_logic_vector(5 downto 0);
    signal seq_eeprom_read_start_sync  : std_logic;

    signal mux_eeprom_channel_sel : std_logic_vector(7 downto 0);
    signal mux_eeprom_map_sel     : std_logic;
    signal mux_eeprom_start_adr   : std_logic_vector(7 downto 0);
    signal mux_eeprom_num_regs    : std_logic_vector(5 downto 0);
    signal mux_eeprom_read_start  : std_logic;

    signal ofw_limit_reached          : std_logic;
    signal ofw_cycle_count            : std_logic_vector(23 downto 0);
    signal ofw_cycle_count_running    : std_logic_vector(23 downto 0);
    signal ofw_watchdog_theshold      : std_logic_vector(23 downto 0);
    signal ofw_watchdog_theshold_sync : std_logic_vector(23 downto 0);

    signal send_ofw_boc      : std_logic;
    signal send_ofw_boc_sync : std_logic;

    signal cycle_start_theshold      : std_logic_vector(31 downto 0);
    signal cycle_start_theshold_sync : std_logic_vector(31 downto 0);

    signal eor_wait_count      : std_logic_vector(31 downto 0);
    signal eor_wait_count_sync : std_logic_vector(31 downto 0);

    signal post_rst_delay_evt_cnt,   post_rst_delay_evt_cnt_sync   : std_logic_vector(31 downto 0);
    signal post_rst_delay_timestamp, post_rst_delay_timestamp_sync : std_logic_vector(31 downto 0);
    signal post_rst_delay_async,     post_rst_delay_async_sync     : std_logic_vector(23 downto 0);

    -- Trigger Information FIFO
    signal s_trig_info_fifo_tdata,  m_trig_info_fifo_tdata  : std_logic_vector(127 downto 0);
    signal s_trig_info_fifo_tvalid, m_trig_info_fifo_tvalid : std_logic;
    signal s_trig_info_fifo_tready, m_trig_info_fifo_tready : std_logic;
    signal wr_rst_busy_trig                                 : std_logic;
    signal rd_rst_busy_trig                                 : std_logic;
    
    signal trig_info_sm_state  : std_logic;
    signal trig_info_fifo_full : std_logic;

    -- FMC SFP configuration
    signal i2c_l12_en_start : std_logic;
    signal i2c_l12_rd_start : std_logic;

    signal sfp_l12_requested_ports   : std_logic_vector(7 downto 0);
    signal sfp_l12_enabled_ports     : std_logic_vector(7 downto 0);
    signal sfp_l12_enabled_ports_ttc : std_logic_vector(7 downto 0);
    signal sfp_l12_enabled_ports_ext : std_logic_vector(7 downto 0);

    signal sfp_l12_sn       : array_8x128bit;
    signal sfp_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal sfp_l12_tx_fault : std_logic_vector(7 downto 0);
    signal sfp_l12_rx_los   : std_logic_vector(7 downto 0);

    signal change_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal change_l12_tx_fault : std_logic_vector(7 downto 0);
    signal change_l12_rx_los   : std_logic_vector(7 downto 0);

    signal change_error_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal change_error_l12_tx_fault : std_logic_vector(7 downto 0);
    signal change_error_l12_rx_los   : std_logic_vector(7 downto 0);

    signal error_l8_fmc_absent,   error_l12_fmc_absent   : std_logic;
    signal error_l8_fmc_mod_type, error_l12_fmc_mod_type : std_logic;
    signal error_l8_fmc_int_n,    error_l12_fmc_int_n    : std_logic;
    signal error_l8_startup_i2c,  error_l12_startup_i2c  : std_logic;

    signal sfp_en_error_l12_mod_abs    : std_logic_vector(7 downto 0);
    signal sfp_en_error_l12_sfp_type   : std_logic_vector(1 downto 0);
    signal sfp_en_error_l12_tx_fault   : std_logic_vector(7 downto 0);
    signal sfp_en_error_l12_sfp_alarms : std_logic;
    signal sfp_en_error_l12_i2c_chip   : std_logic;

    signal sfp_en_alarm_l12_temp_high     : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_temp_low      : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_vcc_high      : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_vcc_low       : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_tx_bias_high  : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_tx_bias_low   : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_tx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_tx_power_low  : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_rx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l12_rx_power_low  : std_logic_vector(7 downto 0);

    signal sfp_en_warning_l12_temp_high     : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_temp_low      : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_vcc_high      : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_vcc_low       : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_tx_bias_high  : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_tx_bias_low   : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_tx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_tx_power_low  : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_rx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l12_rx_power_low  : std_logic_vector(7 downto 0);

    signal sfp_channel_sel_in      : std_logic_vector(7 downto 0);
    signal sfp_eeprom_map_sel_in   : std_logic;
    signal sfp_eeprom_start_adr_in : std_logic_vector(7 downto 0);
    signal sfp_eeprom_num_regs_in  : std_logic_vector(5 downto 0);

    signal l12_eeprom_reg_out               : std_logic_vector(127 downto 0);
    signal l12_eeprom_reg_out_valid         : std_logic;
    signal l12_eeprom_reg_out_sync          : std_logic_vector(127 downto 0);
    signal l12_eeprom_reg_out_valid_stretch : std_logic;
    signal l12_eeprom_reg_out_valid_sync    : std_logic;

    -- FMC I2C
    signal i2c_fmc_scl_o,   i2c_l8_scl_o,   i2c_l12_scl_o   : std_logic;
    signal i2c_fmc_scl_oen, i2c_l8_scl_oen, i2c_l12_scl_oen : std_logic;
    signal i2c_fmc_sda_o,   i2c_l8_sda_o,   i2c_l12_sda_o   : std_logic;
    signal i2c_fmc_sda_oen, i2c_l8_sda_oen, i2c_l12_sda_oen : std_logic;

    signal fmcs_ready                                  : std_logic;
    signal fmc_eeprom_error_i2c,  fmc_eeprom_error_id  : std_logic;
    signal fmc_ids_wr_start,      fmc_ids_wr_start_osc : std_logic;
    signal fmc_ids_wr_start_pulse                      : std_logic;
    signal fmc_ids_valid                               : std_logic;

    signal l8_fmc_id_request,     l12_fmc_id_request     : std_logic_vector(7 downto 0);
    signal l8_fmc_id_request_osc, l12_fmc_id_request_osc : std_logic_vector(7 downto 0);
    signal l8_fmc_id,             l12_fmc_id             : std_logic_vector(7 downto 0);

    -- TTS RX
    signal l12_aligned_a       : std_logic_vector(  7 downto 0);
    signal l12_idelay_tap_a    : std_logic_vector( 39 downto 0);
    signal l12_idelay_locked_a : std_logic;
    signal l12_stats_cnt_a     : std_logic_vector(255 downto 0);

    signal l12_tts_state          : std_logic_vector(31 downto 0);
    signal l12_tts_state_out      : std_logic_vector(63 downto 0);
    signal l12_tts_state_valid    : std_logic_vector( 7 downto 0);
    signal l12_tts_state_mask     : std_logic_vector( 7 downto 0);
    signal l12_tts_state_mask_ttc : std_logic_vector( 7 downto 0);

    signal tts_rx_realign   : std_logic;
    signal tts_rx_realign_i : std_logic_vector(7 downto 0);

    signal sfp_tap_delay_strobe   : std_logic;
    signal sfp_tap_delay_strobe_i : std_logic_vector( 7 downto 0);
    signal sfp_tap_delay          : std_logic_vector( 4 downto 0);
    signal sfp_tap_delay_i        : std_logic_vector(39 downto 0);
    signal sfp_tap_delay_manual   : std_logic;

    -- TTS lock
    signal tts_lock_mux                : std_logic;
    signal l12_tts_lock                : std_logic_vector( 7 downto 0);
    signal l12_tts_lock_cnt            : array_8x32bit;
    signal tts_lock_threshold          : std_logic_vector(31 downto 0);
    signal tts_lock_threshold_sync     : std_logic_vector(31 downto 0);
    signal tts_misaligned_allowed      : std_logic_vector(31 downto 0);
    signal tts_misaligned_allowed_sync : std_logic_vector(31 downto 0);

    signal tts_msa : std_logic_vector(7 downto 0);
    signal tts_dis : std_logic_vector(7 downto 0);
    signal tts_err : std_logic_vector(7 downto 0);
    signal tts_syl : std_logic_vector(7 downto 0);
    signal tts_bsy : std_logic_vector(7 downto 0);
    signal tts_ofw : std_logic_vector(7 downto 0);
    signal tts_rdy : std_logic_vector(7 downto 0);

    signal l12_tts_state_prev   : std_logic_vector(31 downto 0);
    signal l12_tts_update_timer : array_8x64bit;

    signal local_tts_state : std_logic_vector(3 downto 0);
    signal l12_tts_status  : std_logic_vector(5 downto 0);
    signal system_status   : std_logic_vector(5 downto 0);
    signal local_error     : std_logic;
    signal local_sync_lost : std_logic;
    signal local_overflow  : std_logic;

    signal abort_run             : std_logic;
    signal overflow_warning      : std_logic;
    signal overflow_warning_sync : std_logic;
    signal overflow_warning_tfc7 : std_logic; -- a long pulse to combine with the boc external output to inform
                                              -- the trigger FC7 that triggers are being throttled
    signal ofw_handshake         : std_logic;
    signal ofw_latch             : std_logic;

    -- handshake with DAQ frontends when they need the trigger throttled
    signal daq_frontend_ofw_throttle    : std_logic_vector(28 downto 0);
    signal daq_throttle_requested       : std_logic;
    signal daq_throttle_requested_sync  : std_logic;
    signal combined_overflow_warning    : std_logic;
    signal enable_daq_fe_throttle       : std_logic;

    -- LED signals
    signal blink : std_logic;

    -- XADC measurements
    signal measured_temp    : std_logic_vector(15 downto 0);
    signal measured_vccint  : std_logic_vector(15 downto 0);
    signal measured_vccaux  : std_logic_vector(15 downto 0);
    signal measured_vccbram : std_logic_vector(15 downto 0);

    -- XADC alarms
    signal over_temp     : std_logic;
    signal alarm_temp    : std_logic;
    signal alarm_vccint  : std_logic;
    signal alarm_vccaux  : std_logic;
    signal alarm_vccbram : std_logic;
    signal xadc_alarms   : std_logic_vector(3 downto 0);

    -- FPGA
    signal reprog_fpga_from_ipb : std_logic;
    
    -- helps keep signals present to allow timing studies within Vivadp debugs
    signal ttc_esync_counter : std_logic_vector(31 downto 0);
    signal channel_a_counter : std_logic_vector(31 downto 0);

    -- debugs
    -- attribute mark_debug : string;
    -- attribute keep : string;
    -- attribute mark_debug of measured_trigger : signal is "true";
    -- attribute keep       of measured_trigger : signal is "true";
    -- attribute mark_debug of acc_trigger : signal is "true";
    -- attribute keep       of acc_trigger : signal is "true";
    -- attribute mark_debug of clear_latched_trigger : signal is "true";
    -- attribute keep       of clear_latched_trigger : signal is "true";
    -- attribute mark_debug of latched_trigger : signal is "true";
    -- attribute keep       of latched_trigger : signal is "true";
    -- attribute mark_debug of fill_count_local : signal is "true";
    -- attribute keep       of fill_count_local : signal is "true";
    -- attribute mark_debug of boc_oos : signal is "true";
    -- attribute keep       of boc_oos : signal is "true";
    -- attribute mark_debug of aux_lemo_a : signal is "true";
    -- attribute keep       of aux_lemo_a : signal is "true";
    -- attribute mark_debug of missed_a6_trigger_fc7 : signal is "true";
    -- attribute keep       of missed_a6_trigger_fc7 : signal is "true";

begin

    -- ----------
    -- CDCE logic
    -- ----------

    -- --------------------------------------
    cdce_synch: entity work.cdce_synchronizer
    generic map (
        pwrdown_delay   => 1000,
        sync_delay      => 1000000
    )
    port map (
        reset_i         => ipb_rst_i,
        ipbus_ctrl_i    => '1',
        ipbus_sel_i     => '0',
        ipbus_pwrdown_i => '1',
        ipbus_sync_i    => '1',
        user_sel_i      => '1',
        user_pwrdown_i  => '1',
        user_sync_i     => '1',
        pri_clk_i       => '0',
        sec_clk_i       => ttc_clk,
        pwrdown_o       => cdce_pwrdown_o,
        sync_o          => cdce_sync_o,
        ref_sel_o       => cdce_ref_sel_o,
        sync_clk_o      => cdce_sync_clk_o
    );


    -- --------------
    -- XADC interface
    -- --------------

    -- -----------------------------------------
    xadc_usr: entity work.xadc_interface_wrapper
    port map (
        -- clock and reset
        dclk  => ipb_clk,
        reset => ipb_rst_i,

        -- measurements
        measured_temp    => measured_temp,
        measured_vccint  => measured_vccint,
        measured_vccaux  => measured_vccaux,
        measured_vccbram => measured_vccbram,

        -- alarms
        over_temp     => over_temp,
        alarm_temp    => alarm_temp,
        alarm_vccint  => alarm_vccint,
        alarm_vccaux  => alarm_vccaux,
        alarm_vccbram => alarm_vccbram
    );


    -- ------
    -- clocks
    -- ------

    -- ---------------------------------
    clk_wiz_ext: entity work.clk_wiz_ext
    port map (
        clk_in1  => fmc_header_n(0),
        clk_out1 => ext_clk_x4,
        locked   => ext_clk_lock
    );

    -- ---------------------------------
    clk_wiz_ttc: entity work.clk_wiz_ttc
    port map (
        clk_in1  => ttc_clk,
        clk_out1 => ttc_clk_x2,
        clk_out2 => open,
        clk_out3 => ttc_clk_x5,
        clk_out4 => ttc_clk_x10,
        locked   => ttc_clk_lock
    );


    -- ------
    -- resets
    -- ------

    -- -----------------------------------------
    startup_reset_usr: entity work.startup_reset
    port map (
        clk   => ipb_clk,
        reset => init_rst_ipb,
        hold  => rst_from_ipbus
    );

    sys_rst_ipb <= init_rst_ipb or rst_from_ipbus;

    -- -------------------------
    rst: entity work.ipbus_reset
    port map (
        clk_ipb => ipb_clk,
        clk_125 => osc125_b_bufg,
        rst_in  => sys_rst_ipb,
        rst_ipb => rst_ipb,
        rst_125 => hard_rst_osc125
    );

    -- stretch reset signal
    rst_ipb_stretch_inst: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => rst_ipb,
        sig_o    => rst_ipb_stretch
    );

    -- ----------------------------------
    rst_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => hard_rst_ext
    );

    -- -------------------------------------
    rst_ext_x4_sync: entity work.sync_2stage
    port map (
        clk      => ext_clk_x4,
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => rst_ext_x4
    );

    -- ----------------------------------
    rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => hard_rst_ttc
    );

    -- ---------------------------------------
    soft_rst_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => soft_rst_from_ipbus,
        sig_o(0) => soft_rst_ext
    );

    -- ---------------------------------------
    soft_rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => soft_rst_from_ipbus,
        sig_o(0) => soft_rst_ttc
    );

    -- ---------------------------------------
    soft_rst_osc_sync: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => soft_rst_from_ipbus,
        sig_o(0) => soft_rst_osc125
    );

    user_reset <= rst_ipb or soft_rst_from_ipbus;

    -- automatic soft reset generation
    -- to recover from any spurious outputs from the TTC decoder
    process(osc125_b_bufg)
    begin
        if rising_edge(osc125_b_bufg) then
            auto_soft_rst_sync1 <= ttc_clk_lock and ttc_ready;
            auto_soft_rst_sync2 <= auto_soft_rst_sync1;
            auto_soft_rst_sync3 <= auto_soft_rst_sync2;

            -- rising-edge detect
            if auto_soft_rst_sync2 = '1' and auto_soft_rst_sync3 = '0' then
                auto_soft_rst <= '1';
            else
                auto_soft_rst <= '0';
            end if;
        end if;
    end process;

    -- stretch reset signal
    auto_soft_rst_stretch_inst: entity work.signal_stretch
    port map (
        clk      => osc125_b_bufg,
        n_cycles => x"10",
        sig_i    => auto_soft_rst,
        sig_o    => auto_soft_rst_stretch
    );

    -- delay reset signal
    l12_ttc_delay_inst: entity work.pulse_delay
    generic map (nbr_bits => 8)
    port map (
        clock     => osc125_b_bufg,
        delay     => x"7C", -- 1-us delay
        pulse_in  => auto_soft_rst_stretch,
        pulse_out => auto_soft_rst_delay
    );

    -- --------------------------------------------
    auto_soft_rst_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => auto_soft_rst_delay,
        sig_o(0) => auto_soft_rst_ext
    );

    -- --------------------------------------------
    auto_soft_rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => auto_soft_rst_delay,
        sig_o(0) => auto_soft_rst_ttc
    );

    -- --------------------------------------------
    auto_soft_rst_osc_sync: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => auto_soft_rst_delay,
        sig_o(0) => auto_soft_rst_osc125
    );

    rst_osc125 <= hard_rst_osc125 or soft_rst_osc125 or auto_soft_rst_osc125;
    rst_ttc    <= hard_rst_ttc    or soft_rst_ttc    or auto_soft_rst_ttc;
    rst_ext    <= hard_rst_ext    or soft_rst_ext    or auto_soft_rst_ext;
    rst_ext_n  <= not rst_ext;


    -- -----------
    -- LED mapping
    -- -----------

    -- ------------------------------------------
    signal_toggle_inst: entity work.signal_toggle
    port map (
        clk   => osc125_b_bufg,
        sig_o => blink
    );

    -- FC7 baseboard
    top_led2(0) <= not error_l12_fmc_absent and not error_l12_fmc_mod_type and not error_l12_fmc_int_n and tts_lock_mux and l12_tts_status(5);
    top_led2(1) <= error_l12_fmc_absent or error_l12_fmc_mod_type or error_l12_fmc_int_n or not tts_lock_mux or not l12_tts_status(5);
    top_led2(2) <= '1';

    top_led3(0) <= not error_l8_fmc_absent and not error_l8_fmc_mod_type and not error_l8_fmc_int_n and ext_clk_lock;
    top_led3(1) <= error_l8_fmc_absent or error_l8_fmc_mod_type or error_l8_fmc_int_n or not ext_clk_lock;
    top_led3(2) <= '1';

    bot_led1(0) <= ext_clk_lock and ttc_clk_lock and ttc_ready;
    bot_led1(1) <= not ext_clk_lock or not ttc_clk_lock or not ttc_ready;
    bot_led1(2) <= '1';

    bot_led2(0) <= tts_lock_mux;
    bot_led2(1) <= not tts_lock_mux;
    bot_led2(2) <= '1';

    -- EDA-02708 FMC
    fmc_l8_led(8) <= ttc_clk_lock and system_status(0); -- misaligned or disconnected
    fmc_l8_led(7) <= ttc_clk_lock and system_status(1); -- error
    fmc_l8_led(6) <= ttc_clk_lock and system_status(2); -- sync lost
    fmc_l8_led(5) <= ttc_clk_lock and system_status(3); -- busy
    fmc_l8_led(4) <= ttc_clk_lock and system_status(4); -- overflow warning
    fmc_l8_led(3) <= ttc_clk_lock and system_status(5); -- ready

    fmc_l8_led2(0) <= '1'   when run_in_progress = '1' and run_aborted = '0' and run_pause = '0' else
                      blink when run_in_progress = '1' and run_aborted = '0' and run_pause = '1' else '0';
    fmc_l8_led2(1) <= run_aborted;
    
    fmc_l8_led1(0) <= '0';
    fmc_l8_led1(1) <= doing_run_checks or resetting_clients or finding_cycle_start;


    -- -----------------
    -- IPbus user slaves
    -- -----------------

    -- ---------------------------------------------
    stat_regs_inst: entity work.ipb_user_status_regs
    port map (
        clk       => ipb_clk,
        reset     => rst_ipb,
        ipbus_in  => ipb_mosi_i(user_ipb_stat_regs),
        ipbus_out => ipb_miso_o(user_ipb_stat_regs),
        regs_i    => stat_reg
    );

    -- ----------------------------------------------
    ctrl_regs_inst: entity work.ipb_user_control_regs
    port map (
        clk             => ipb_clk,
        reset           => rst_ipb,
        run_in_progress => run_in_progress,
        ipbus_in        => ipb_mosi_i(user_ipb_ctrl_regs),
        ipbus_out       => ipb_miso_o(user_ipb_ctrl_regs),
        regs_o          => ctrl_reg
    );

    -- ------------------------------------------------
    seqr_regs_inst: entity work.ipb_user_sequencer_regs
    port map (
        clk             => ipb_clk,
        reset           => rst_ipb,
        run_in_progress => run_in_progress,
        ipbus_in        => ipb_mosi_i(user_ipb_seqr_regs),
        ipbus_out       => ipb_miso_o(user_ipb_seqr_regs),
        regs_o          => seqr_reg
    );


    -- ----------------
    -- register mapping
    -- ----------------

    -- status register
    -- two-stage synchronization is performed in slave module
    stat_reg( 0) <= "01" & "00" & x"0" & usr_ver_major & usr_ver_minor & usr_ver_patch;
    stat_reg( 1) <= x"0" & l8_fmc_id & l12_fmc_id & '0' & board_id;
    stat_reg( 2) <= x"000" & async_enable_sent & '0' & trig_info_fifo_full & fmc_ids_valid & fmc_eeprom_error_id & fmc_eeprom_error_i2c & fmcs_ready & '0' & tts_lock_mux & ttc_ready & ext_clk_lock & ttc_clk_lock; -- PARTLY RESERVED FOR FANOUT, TRIGGER USE
    stat_reg( 3) <= measured_vccint  & measured_temp;
    stat_reg( 4) <= measured_vccbram & measured_vccaux;
    stat_reg( 5) <= x"000000" & "000" & alarm_vccbram & alarm_vccaux & alarm_vccint & alarm_temp & over_temp;
    stat_reg( 6) <= l12_eeprom_reg_out( 31 downto  0);
    stat_reg( 7) <= l12_eeprom_reg_out( 63 downto 32);
    stat_reg( 8) <= l12_eeprom_reg_out( 95 downto 64);
    stat_reg( 9) <= l12_eeprom_reg_out(127 downto 96);
    stat_reg(10) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(11) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(12) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(13) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(14) <= x"00" & sfp_en_error_l12_i2c_chip & sfp_en_error_l12_sfp_alarms & sfp_en_error_l12_tx_fault & sfp_en_error_l12_sfp_type & sfp_en_error_l12_mod_abs & error_l12_startup_i2c & error_l12_fmc_int_n & error_l12_fmc_mod_type & error_l12_fmc_absent;
    stat_reg(15) <= x"0000000" & error_l8_startup_i2c & error_l8_fmc_int_n & error_l8_fmc_mod_type & error_l8_fmc_absent; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(16) <= sfp_en_alarm_l12_vcc_low & sfp_en_alarm_l12_vcc_high & sfp_en_alarm_l12_temp_low & sfp_en_alarm_l12_temp_high;
    stat_reg(17) <= sfp_en_alarm_l12_tx_power_low & sfp_en_alarm_l12_tx_power_high & sfp_en_alarm_l12_tx_bias_low & sfp_en_alarm_l12_tx_bias_high;
    stat_reg(18) <= x"0000" & sfp_en_alarm_l12_rx_power_low & sfp_en_alarm_l12_rx_power_high;
    stat_reg(19) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(20) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(21) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(22) <= sfp_en_warning_l12_vcc_low & sfp_en_warning_l12_vcc_high & sfp_en_warning_l12_temp_low & sfp_en_warning_l12_temp_high;
    stat_reg(23) <= sfp_en_warning_l12_tx_power_low & sfp_en_warning_l12_tx_power_high & sfp_en_warning_l12_tx_bias_low & sfp_en_warning_l12_tx_bias_high;
    stat_reg(24) <= x"0000" & sfp_en_warning_l12_rx_power_low & sfp_en_warning_l12_rx_power_high;
    stat_reg(25) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(26) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(27) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(28) <= x"000000" & sfp_l12_enabled_ports; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(29) <= x"00" & change_error_l12_mod_abs & change_l12_mod_abs & sfp_l12_mod_abs;
    stat_reg(30) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(31) <= x"00" & change_error_l12_tx_fault & change_l12_tx_fault & sfp_l12_tx_fault;
    stat_reg(32) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(33) <= x"00" & change_error_l12_rx_los & change_l12_rx_los & sfp_l12_rx_los;
    stat_reg(34) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(35) <= x"000000" & l12_tts_lock; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(36) <= l12_tts_state;
    stat_reg(37) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(38) <= x"00" & '0' & l12_tts_status & local_tts_state & system_status; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(39) <= eb_state(15 downto  0) & ts_state(15 downto 0);
    stat_reg(40) <= eb_state(17 downto 16) & l12_st_state(32) & l12_fs_state;
    stat_reg(41) <= "0" & ts_state(17 downto 16) & l8_st_state(32) & l8_fs_state;
    stat_reg(42) <= l12_st_state(31 downto 0);
    stat_reg(43) <= l8_st_state(31 downto 0);
    stat_reg(44) <= x"00" & tis_state & l8_ssc_state & l12_ssc_state;
    stat_reg(45) <= x"0" & "000" & fe_state & l8_sgr_state & l12_sgr_state;
    stat_reg(46) <= x"0000" & "000" & trig_sub_index & trig_index & run_aborted & finding_cycle_start & resetting_clients & doing_run_checks & run_in_progress;
    stat_reg(47) <= x"00" & trig_num;
    stat_reg(48) <= trig_timestamp(31 downto 0);
    stat_reg(49) <= x"00000" & trig_timestamp(43 downto 32);
    stat_reg(50) <= ttc_sbit_error_cnt;
    stat_reg(51) <= ttc_mbit_error_cnt;
    stat_reg(52) <= x"0" & ofw_cycle_count_running & "00" & error_ttc_mbit_limit & error_ttc_sbit_limit;
    stat_reg(53) <= x"0" & "000" & ofw_limit_reached & ofw_cycle_count;
    stat_reg(54) <= x"000" & l12_idelay_tap_a(19 downto  0);
    stat_reg(55) <= x"000" & l12_idelay_tap_a(39 downto 20);
    stat_reg(56) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(57) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(58) <= l12_tts_state_prev;
    stat_reg(59) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(60) <= run_timer(31 downto  0);
    stat_reg(61) <= run_timer(63 downto 32);
    stat_reg(62) <= ttc_sbit_error_cnt_global;
    stat_reg(63) <= ttc_mbit_error_cnt_global;
    -- stat_reg( to ) <= (others => (others => '0')); -- fill the unused registers with zeros

    sfp_sn_regs: for i in 0 to 7 generate
    begin
        stat_reg(64 + 4*i) <= sfp_l12_sn(i)( 31 downto  0);
        stat_reg(65 + 4*i) <= sfp_l12_sn(i)( 63 downto 32);
        stat_reg(66 + 4*i) <= sfp_l12_sn(i)( 95 downto 64);
        stat_reg(67 + 4*i) <= sfp_l12_sn(i)(127 downto 96);

        stat_reg(96 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(97 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(98 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(99 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
    end generate;
	
    trig_type_num_regs: for i in 0 to 31 generate
    begin
        stat_reg(128 + i) <= x"00" & trig_type_num(i);
    end generate;

    tts_timer_regs: for i in 0 to 7 generate
    begin
        stat_reg(160 + 2*i) <= l12_tts_update_timer(i)(31 downto  0);
        stat_reg(161 + 2*i) <= l12_tts_update_timer(i)(63 downto 32);

        stat_reg(176 + 2*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(177 + 2*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
    end generate;
    stat_reg(192 to 193) <= (others => (others => '0')); -- RESERVED FOR TRIGGER USE
    stat_reg(194)        <= x"0000000" & "000" & internal_trigger_strt;
    stat_reg(195 to 197) <= (others => (others => '0')); -- RESERVED FOR TRIGGER USE
    stat_reg(198)        <= x"00000" & missed_A6_count & "000" & missing_A6;
    stat_reg(199)(0)     <= ofw_latch;
    stat_reg(199)(1)     <= channel_a_from_seq;
    stat_reg(199)(2)     <= trigger_from_ttc_esync;
    stat_reg(200)        <= channel_a_counter;
    stat_reg(201)        <= ttc_esync_counter;
    stat_reg(202 to 208) <= (others => (others => '0')); -- UNASSIGNED ofw_latch

    -- control register
    rst_from_ipbus           <= ctrl_reg( 0)( 0);
    soft_rst_from_ipbus      <= ctrl_reg( 0)( 1);
    run_enable               <= ctrl_reg( 0)( 2);
    run_pause                <= ctrl_reg( 0)( 3);
    force_exit               <= ctrl_reg( 0)( 4);
    reprog_fpga_from_ipb     <= ctrl_reg( 0)( 5);
    send_ofw_boc             <= ctrl_reg( 1)( 0);
    -- RESERVED              <= ctrl_reg( 2)( 7 downto  0);
    l12_tts_state_mask       <= ctrl_reg( 2)(15 downto  8);
    -- UNUSED                <= ctrl_reg( 2)(31 downto 16);
    -- RESERVED              <= ctrl_reg( 3)( 7 downto  0); -- default set
    global_seq_count         <= ctrl_reg( 3)(11 downto  8);
    ofw_watchdog_theshold    <= ctrl_reg( 4)(23 downto  0); -- default set
    cycle_start_theshold     <= ctrl_reg( 5);               -- default set
    tts_lock_threshold       <= ctrl_reg( 6);               -- default set
    sfp_tap_delay_manual     <= ctrl_reg( 7)( 0);
    sfp_tap_delay_strobe     <= ctrl_reg( 7)( 1);
    sfp_tap_delay            <= ctrl_reg( 7)( 6 downto  2);
    tts_rx_realign           <= ctrl_reg( 7)( 7);
    tts_rx_rst_l12_from_ipb  <= ctrl_reg( 7)( 8);
    -- RESERVED              <= ctrl_reg( 7)( 9);
    sfp_channel_sel_in       <= ctrl_reg( 8)( 7 downto  0);
    sfp_eeprom_map_sel_in    <= ctrl_reg( 8)( 8);
    sfp_eeprom_start_adr_in  <= ctrl_reg( 8)(16 downto  9);
    sfp_eeprom_num_regs_in   <= ctrl_reg( 8)(22 downto 17);
    i2c_l12_rd_start         <= ctrl_reg( 8)(23);
    -- RESERVED              <= ctrl_reg( 8)(24);
    sfp_l12_requested_ports  <= ctrl_reg( 9)( 7 downto  0);
    -- RESERVED              <= ctrl_reg( 9)(15 downto  8);
    i2c_l12_en_start         <= ctrl_reg( 9)(16);
    -- RESERVED              <= ctrl_reg( 9)(17);
    i2c_l12_rst_from_ipb     <= ctrl_reg( 9)(18);           -- default set
    i2c_l8_rst_from_ipb      <= ctrl_reg( 9)(19);           -- default set
    -- RESERVED              <= ctrl_reg( 9)(20);
    -- RESERVED              <= ctrl_reg( 9)(24 downto 21);
    l12_fmc_id_request       <= ctrl_reg(10)( 7 downto  0);
    l8_fmc_id_request        <= ctrl_reg(10)(15 downto  8);
    fmc_ids_wr_start         <= ctrl_reg(10)(16);
    l12_ttc_encoded_delay(0) <= ctrl_reg(11)( 7 downto  0);
    l12_ttc_encoded_delay(1) <= ctrl_reg(11)(15 downto  8);
    l12_ttc_encoded_delay(2) <= ctrl_reg(11)(23 downto 16);
    l12_ttc_encoded_delay(3) <= ctrl_reg(11)(31 downto 24);
    l12_ttc_encoded_delay(4) <= ctrl_reg(12)( 7 downto  0);
    l12_ttc_encoded_delay(5) <= ctrl_reg(12)(15 downto  8);
    l12_ttc_encoded_delay(6) <= ctrl_reg(12)(23 downto 16);
    l12_ttc_encoded_delay(7) <= ctrl_reg(12)(31 downto 24);
    -- RESERVED              <= ctrl_reg(13)( 7 downto  0);
    -- RESERVED              <= ctrl_reg(13)(15 downto  8);
    -- RESERVED              <= ctrl_reg(13)(23 downto 16);
    -- RESERVED              <= ctrl_reg(13)(31 downto 24);
    -- RESERVED              <= ctrl_reg(14)( 7 downto  0);
    -- RESERVED              <= ctrl_reg(14)(15 downto  8);
    -- RESERVED              <= ctrl_reg(14)(23 downto 16);
    -- RESERVED              <= ctrl_reg(14)(31 downto 24);
    ttc_sbit_error_threshold <= ctrl_reg(15);
    ttc_mbit_error_threshold <= ctrl_reg(16);
    var_width_a              <= ctrl_reg(17)( 7 downto  0); -- default set
    var_width_b              <= ctrl_reg(17)(15 downto  8); -- default set
    ttc_decoder_rst_from_ipb <= ctrl_reg(18)(0);
    enable_async_storage     <= ctrl_reg(19)(0);            -- default set
    eor_wait_count           <= ctrl_reg(20);               -- default set
    trig_out_disable_a       <= ctrl_reg(21)(0);
    trig_out_disable_b       <= ctrl_reg(22)(0);
    trx_lemo_sel             <= ctrl_reg(23)(0);
    tts_misaligned_allowed   <= ctrl_reg(24);
    post_rst_delay_evt_cnt   <= ctrl_reg(25);               -- default set
    post_rst_delay_timestamp <= ctrl_reg(26);               -- default set
    trigger_delay_a          <= ctrl_reg(27);
    trigger_delay_b          <= ctrl_reg(28);
    -- RESERVED              <= ctrl_reg(29);
    -- RESERVED              <= ctrl_reg(30);
    -- RESERVED              <= ctrl_reg(31);
    -- RESERVED              <= ctrl_reg(32);
    -- RESERVED              <= ctrl_reg(33);
    -- RESERVED              <= ctrl_reg(34);
    -- RESERVED              <= ctrl_reg(35);
    -- RESERVED              <= ctrl_reg(36);
    -- RESERVED              <= ctrl_reg(37);
    oosync_gap_threshold     <= ctrl_reg(38);
    -- RESERVED              <= ctrl_reg(39);
    -- RESERVED              <= ctrl_reg(40);
    -- RESERVED              <= ctrl_reg(41);
    trig_latch_clear_delay   <= ctrl_reg(42);
    -- RESERVED              <= ctrl_reg(43);
    daq_frontend_ofw_throttle <= ctrl_reg(44)(28 downto 0);
    enable_daq_fe_throttle   <= ctrl_reg(44)(31);
    post_rst_delay_async     <= ctrl_reg(45)(23 downto 0);
    no_beam_structure        <= ctrl_reg(45)(24);

    -- sequencer registers
    seq_regs: for i in 0 to 15 generate
    begin
        seq_count(i)           <= seqr_reg(i, 0)( 3 downto  0);
        seq_trig_type(i, 0)    <= seqr_reg(i, 1)( 4 downto  0); -- default set
        seq_trig_type(i, 1)    <= seqr_reg(i, 1)(12 downto  8);
        seq_trig_type(i, 2)    <= seqr_reg(i, 1)(20 downto 16);
        seq_trig_type(i, 3)    <= seqr_reg(i, 1)(28 downto 24);
        seq_trig_type(i, 4)    <= seqr_reg(i, 2)( 4 downto  0);
        seq_trig_type(i, 5)    <= seqr_reg(i, 2)(12 downto  8);
        seq_trig_type(i, 6)    <= seqr_reg(i, 2)(20 downto 16);
        seq_trig_type(i, 7)    <= seqr_reg(i, 2)(28 downto 24);
        seq_trig_type(i, 8)    <= seqr_reg(i, 3)( 4 downto  0);
        seq_trig_type(i, 9)    <= seqr_reg(i, 3)(12 downto  8);
        seq_trig_type(i,10)    <= seqr_reg(i, 3)(20 downto 16);
        seq_trig_type(i,11)    <= seqr_reg(i, 3)(28 downto 24);
        seq_trig_type(i,12)    <= seqr_reg(i, 4)( 4 downto  0);
        seq_trig_type(i,13)    <= seqr_reg(i, 4)(12 downto  8);
        seq_trig_type(i,14)    <= seqr_reg(i, 4)(20 downto 16);
        seq_trig_type(i,15)    <= seqr_reg(i, 4)(28 downto 24);
        seq_pre_trig_gap(i, 0) <= seqr_reg(i, 5);
        seq_pre_trig_gap(i, 1) <= seqr_reg(i, 6);
        seq_pre_trig_gap(i, 2) <= seqr_reg(i, 7);
        seq_pre_trig_gap(i, 3) <= seqr_reg(i, 8);
        seq_pre_trig_gap(i, 4) <= seqr_reg(i, 9);
        seq_pre_trig_gap(i, 5) <= seqr_reg(i,10);
        seq_pre_trig_gap(i, 6) <= seqr_reg(i,11);
        seq_pre_trig_gap(i, 7) <= seqr_reg(i,12);
        seq_pre_trig_gap(i, 8) <= seqr_reg(i,13);
        seq_pre_trig_gap(i, 9) <= seqr_reg(i,14);
        seq_pre_trig_gap(i,10) <= seqr_reg(i,15);
        seq_pre_trig_gap(i,11) <= seqr_reg(i,16);
        seq_pre_trig_gap(i,12) <= seqr_reg(i,17);
        seq_pre_trig_gap(i,13) <= seqr_reg(i,18);
        seq_pre_trig_gap(i,14) <= seqr_reg(i,19);
        seq_pre_trig_gap(i,15) <= seqr_reg(i,20);
    end generate;


    -- --------------------------------
    -- control register synchronization
    -- --------------------------------

    -- -----------------------------------------
    run_enable_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => run_enable,
        sig_o(0) => run_enable_sync
    );

    -- ----------------------------------------
    run_pause_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => run_pause,
        sig_o(0) => run_pause_sync
    );

    -- delay signal by passing through 32-bit shift register (to allow time for IPbus ack)
    reprog_fpga_delay_inst: entity work.shift_register
    generic map (delay_width => 5)
    port map (
        clock    => ipb_clk,
        delay    => "11111",
        data_in  => reprog_fpga_from_ipb,
        data_out => reprog_fpga
    );

    trigger_delay_a_ext_sync: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => trigger_delay_a,
        sig_o => trigger_delay_a_ext
    );

    trigger_delay_b_ext_sync: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => trigger_delay_b,
        sig_o => trigger_delay_b_ext
    );

    -- --------------------------------------------
    send_ofw_boc_sync_inst: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => send_ofw_boc,
        sig_o(0) => send_ofw_boc_sync
    );

    -- -------------------------------------------------
    l12_tts_state_mask_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => l12_tts_state_mask,
        sig_o => l12_tts_state_mask_ttc
    );

    -- ------------------------------------------------
    global_seq_count_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 4)
    port map (
        clk   => fmc_header_n(0),
        sig_i => global_seq_count,
        sig_o => global_seq_count_sync
    );

    -- -----------------------------------------------------
    ofw_watchdog_theshold_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 24)
    port map (
        clk   => fmc_header_n(0),
        sig_i => ofw_watchdog_theshold,
        sig_o => ofw_watchdog_theshold_sync
    );

    -- ----------------------------------------------------
    cycle_start_theshold_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => cycle_start_theshold,
        sig_o => cycle_start_theshold_sync
    );

    -- --------------------------------------------------
    tts_lock_threshold_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => ttc_clk,
        sig_i => tts_lock_threshold,
        sig_o => tts_lock_threshold_sync
    );

    -- ------------------------------------------------------
    tts_misaligned_allowed_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => ttc_clk,
        sig_i => tts_misaligned_allowed,
        sig_o => tts_misaligned_allowed_sync
    );

    -- -------------------------------------------------
    l12_fmc_id_request_osc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => osc125_b_bufg,
        sig_i => l12_fmc_id_request,
        sig_o => l12_fmc_id_request_osc
    );

    -- ------------------------------------------------
    l8_fmc_id_request_osc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => osc125_b_bufg,
        sig_i => l8_fmc_id_request,
        sig_o => l8_fmc_id_request_osc
    );

    -- -----------------------------------------------
    fmc_ids_wr_start_osc_inst: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => fmc_ids_wr_start,
        sig_o(0) => fmc_ids_wr_start_osc
    );

    -- start trigger to FMC EEPROM interface
    fmc_ids_wr_start_osc_conv: entity work.level_to_pulse
    port map (
        clk   => osc125_b_bufg,
        sig_i => fmc_ids_wr_start_osc,
        sig_o => fmc_ids_wr_start_pulse
    );

    -- ------------------------------------------
    var_width_a_ext_sync: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => fmc_header_n(0),
        sig_i => var_width_a,
        sig_o => var_width_a_ext
    );

    -- ------------------------------------------
    var_width_b_ext_sync: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => fmc_header_n(0),
        sig_i => var_width_b,
        sig_o => var_width_b_ext
    );

    -- ------------------------------------------
    ttc_decoder_rst_inst: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => ttc_decoder_rst_from_ipb,
        sig_o(0) => ttc_decoder_rst
    );

    -- ----------------------------------------------
    eor_wait_count_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => eor_wait_count,
        sig_o => eor_wait_count_sync
    );

    -- -------------------------------------------------
    trig_out_disable_a_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => trig_out_disable_a,
        sig_o(0) => trig_out_disable_a_ext
    );

    -- -------------------------------------------------
    trig_out_disable_b_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => trig_out_disable_b,
        sig_o(0) => trig_out_disable_b_ext
    );

    -- ------------------------------------------------------
    post_rst_delay_evt_cnt_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => post_rst_delay_evt_cnt,
        sig_o => post_rst_delay_evt_cnt_sync
    );

    -- --------------------------------------------------------
    post_rst_delay_timestamp_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => fmc_header_n(0),
        sig_i => post_rst_delay_timestamp,
        sig_o => post_rst_delay_timestamp_sync
    );


    -- --------------------------------------------------------
    post_rst_delay_async_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 24)
    port map (
        clk   => fmc_header_n(0),
        sig_i => post_rst_delay_async,
        sig_o => post_rst_delay_async_sync
    );


    -- -------------
    -- trigger logic
    -- -------------

    -- look for any frontends that have issued a throttling request
    daq_throttle_requested <= or_reduce(daq_frontend_ofw_throttle) and enable_daq_fe_throttle;
    daq_throttle_requested_sync_inst : entity work.sync_2stage
    port map (
        clk   => fmc_header_n(0),
        sig_i(0) => daq_throttle_requested,
        sig_o(0) => daq_throttle_requested_sync
    );
    combined_overflow_warning <= overflow_warning_sync or daq_throttle_requested_sync;

    -- external trigger input
    TRIG0_IBUFGDS: IBUFDS port map (I => tr0_lemo_p, IB => tr0_lemo_n, O => tr0_lemo);
    TRIG1_IBUFGDS: IBUFDS port map (I => tr1_lemo_p, IB => tr1_lemo_n, O => tr1_lemo);

    -- select trigger input source
    tr0_lemo_inv <= not tr0_lemo;
    tr1_lemo_inv <= not tr1_lemo;
    trx_lemo_inv <= tr0_lemo_inv when trx_lemo_sel = '0' else tr1_lemo_inv;

    -- Internal triggering status based on length of trigger pulse passed by trigger FC7
    trx_lemo_measure: entity work.trigger_length_counter
    port map (
        clock          => fmc_header_n(0),
        reset          => hard_rst_ext,
        pulse_in       => aux_lemo_a,
        pulse_out      => measured_trigger,
        internal_start => internal_trigger_strt,
        internal_stop  => internal_trigger_stop,
        missed_a6      => missed_a6_trigger_fc7
    );
    -- trigger pulse (passed by trigger FC7) to trigger sequencer
    trx_lemo_conv: entity work.level_to_pulse
    port map (
        clk   => fmc_header_n(0),
        sig_i => measured_trigger,
        sig_o => acc_trigger
    );
    -- latch the A6 trigger, and pass the latched signal in to the encoder logic
    latch_clock_enable <= measured_trigger or acc_trigger;
    pulsify_clear: entity work.level_to_pulse
    port map (
        clk   => fmc_header_n(0),
        sig_i => clear_latched_trigger,
        sig_o => clear_latched_trigger_pulse
    );
    delay_clear_latch: entity work.pulse_delay
    port map (
        clock     => fmc_header_n(0),
        delay     => trig_latch_clear_delay,
        pulse_in  => clear_latched_trigger_pulse,
        pulse_out => clear_latched_trigger_delayed
    );
    trigger_latch_inst: FDCE
    generic map(
       INIT => '0' ) -- Initial value of latch ( '0' or '1' )
    port map (
        Q   => latched_trigger,       -- Data output
        C   => fmc_header_n(0),               -- Clock input
        CE  => latch_clock_enable,    -- Clock enable input
        CLR => clear_latched_trigger_delayed, -- Asynchronous clear / reset input
        D   => acc_trigger            -- Data input
    );
    -- End of trigger_latch_inst instantiation
    -- locally count sequence number
    reset_local_counter <= run_in_progress and ( doing_run_checks or resetting_clients or finding_cycle_start);
    local_sequence_counter: entity work.sequence_counter
    port map (
       clk     => fmc_header_n(0),
       reset   => reset_local_counter,
       input_pulse => acc_trigger,
       pulse_count => fill_count_local
    );

    -- monitor the timing of the a6 signal relative to the boc to see if we've gotten out of sync
    oos_check: entity work.sequence_sync_monitor
    port map (
       clock       => fmc_header_n(0),
       reset       => rst_ext,
       boc_in      => begin_of_cycle,
       a6_in       => acc_trigger,
       minimum_gap => oosync_gap_threshold,
       out_of_seq  => boc_oos
    );
    oos_count: entity work.input_counter
    generic map ( nbr_bits => 8 )
    port map (
        clk         => fmc_header_n(0),
        reset       => rst_ext,
        input_pulse => boc_oos,
        pulse_count => missed_A6_count
    );

    missed_a6_seq_restart <= missed_a6_trigger_fc7 or boc_oos;

    it_start_conv: entity work.level_to_pulse
    port map (
        clk   => fmc_header_n(0),
        sig_i => internal_trigger_strt,
        sig_o => internal_trigger_strt_pulse
    );

    it_stop_conv: entity work.level_to_pulse
    port map (
        clk   => fmc_header_n(0),
        sig_i => internal_trigger_stop,
        sig_o => internal_trigger_stop_pulse
    );

    -- it_a6mi_conv: entity work.level_to_pulse
    -- port map (
    --     clk   => fmc_header_n(0),
    --     sig_i => missed_a6_seq_restart,
    --     sig_o => missed_a6_seq_restart_pulse
    -- );
    -- -------------------------------------------
    trigger_from_ttc_sync: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => trigger_from_ttc,
        sig_o(0) => trig_clk125_sync
    );

    trigger_from_ttc_sync_ext: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => trigger_from_ttc,
        sig_o(0) => trigger_from_ttc_esync
    );

    -- trigger to event builder
    trig_clk125_conv: entity work.level_to_pulse
    port map (
        clk   => osc125_b_bufg,
        sig_i => trig_clk125_sync,
        sig_o => trig_clk125
    );


    -- -------------
    -- FMC I2C logic
    -- -------------

    mux_eeprom_channel_sel <= seq_eeprom_channel_sel_sync when run_in_progress = '1' else sfp_channel_sel_in;
    mux_eeprom_map_sel     <= seq_eeprom_map_sel_sync     when run_in_progress = '1' else sfp_eeprom_map_sel_in;
    mux_eeprom_start_adr   <= seq_eeprom_start_adr_sync   when run_in_progress = '1' else sfp_eeprom_start_adr_in;
    mux_eeprom_num_regs    <= seq_eeprom_num_regs_sync    when run_in_progress = '1' else sfp_eeprom_num_regs_in;
    mux_eeprom_read_start  <= seq_eeprom_read_start_sync  when run_in_progress = '1' else i2c_l12_rd_start;

    -- ---------------------------------------------
    i2c_l12_top_wrapper: entity work.i2c_top_wrapper
    port map (
        -- clock and reset
        clk   => osc125_b_bufg,
        reset => hard_rst_osc125,

        -- control signals
        fmc_loc               => "00",                    -- L12 LOC
        fmc_mod_type          => "00000011",              -- EDA-02707-V2 FMC
        fmc_absent            => fmc_l12_absent,          -- FMC absent signal
        sfp_requested_ports_i => sfp_l12_requested_ports, -- from IPbus
        i2c_en_start          => i2c_l12_en_start,        -- from IPbus
        i2c_rd_start          => mux_eeprom_read_start,   -- from IPbus

        -- generic read interface
        channel_sel_in       => mux_eeprom_channel_sel,   -- from IPbus
        eeprom_map_sel_in    => mux_eeprom_map_sel,       -- from IPbus
        eeprom_start_adr_in  => mux_eeprom_start_adr,     -- from IPbus
        eeprom_num_regs_in   => mux_eeprom_num_regs,      -- from IPbus
        eeprom_reg_out       => l12_eeprom_reg_out,       -- to IPbus
        eeprom_reg_out_valid => l12_eeprom_reg_out_valid,

        -- status signals
        sfp_enabled_ports => sfp_l12_enabled_ports,
        sfp_sn            => sfp_l12_sn,
        sfp_mod_abs       => sfp_l12_mod_abs,
        sfp_tx_fault      => sfp_l12_tx_fault,
        sfp_rx_los        => sfp_l12_rx_los,

        change_mod_abs  => change_l12_mod_abs,
        change_tx_fault => change_l12_tx_fault,
        change_rx_los   => change_l12_rx_los,

        fs_state  => l12_fs_state,
        st_state  => l12_st_state,
        ssc_state => l12_ssc_state,
        sgr_state => l12_sgr_state,

        -- warning signals
        change_error_mod_abs  => change_error_l12_mod_abs,
        change_error_tx_fault => change_error_l12_tx_fault,
        change_error_rx_los   => change_error_l12_rx_los,

        -- error signals
        error_fmc_absent   => error_l12_fmc_absent,
        error_fmc_mod_type => error_l12_fmc_mod_type,
        error_fmc_int_n    => error_l12_fmc_int_n,
        error_startup_i2c  => error_l12_startup_i2c,

        sfp_en_error_mod_abs    => sfp_en_error_l12_mod_abs,
        sfp_en_error_sfp_type   => sfp_en_error_l12_sfp_type,
        sfp_en_error_tx_fault   => sfp_en_error_l12_tx_fault,
        sfp_en_error_sfp_alarms => sfp_en_error_l12_sfp_alarms,
        sfp_en_error_i2c_chip   => sfp_en_error_l12_i2c_chip,

        -- SFP alarm flags
        sfp_alarm_temp_high     => sfp_en_alarm_l12_temp_high,
        sfp_alarm_temp_low      => sfp_en_alarm_l12_temp_low,
        sfp_alarm_vcc_high      => sfp_en_alarm_l12_vcc_high,
        sfp_alarm_vcc_low       => sfp_en_alarm_l12_vcc_low,
        sfp_alarm_tx_bias_high  => sfp_en_alarm_l12_tx_bias_high,
        sfp_alarm_tx_bias_low   => sfp_en_alarm_l12_tx_bias_low,
        sfp_alarm_tx_power_high => sfp_en_alarm_l12_tx_power_high,
        sfp_alarm_tx_power_low  => sfp_en_alarm_l12_tx_power_low,
        sfp_alarm_rx_power_high => sfp_en_alarm_l12_rx_power_high,
        sfp_alarm_rx_power_low  => sfp_en_alarm_l12_rx_power_low,
          
        -- SFP warning flags
        sfp_warning_temp_high     => sfp_en_warning_l12_temp_high,
        sfp_warning_temp_low      => sfp_en_warning_l12_temp_low,
        sfp_warning_vcc_high      => sfp_en_warning_l12_vcc_high,
        sfp_warning_vcc_low       => sfp_en_warning_l12_vcc_low,
        sfp_warning_tx_bias_high  => sfp_en_warning_l12_tx_bias_high,
        sfp_warning_tx_bias_low   => sfp_en_warning_l12_tx_bias_low,
        sfp_warning_tx_power_high => sfp_en_warning_l12_tx_power_high,
        sfp_warning_tx_power_low  => sfp_en_warning_l12_tx_power_low,
        sfp_warning_rx_power_high => sfp_en_warning_l12_rx_power_high,
        sfp_warning_rx_power_low  => sfp_en_warning_l12_rx_power_low,

        -- I2C signals
        i2c_int_n_i  => i2c_l12_int,     -- active-low I2C interrupt signal
        scl_pad_i    => i2c_l12_scl,     -- input from external pin
        scl_pad_o    => i2c_l12_scl_o,   -- output to tri-state driver
        scl_padoen_o => i2c_l12_scl_oen, -- enable signal for tri-state driver
        sda_pad_i    => i2c_l12_sda,     -- input from external pin
        sda_pad_o    => i2c_l12_sda_o,   -- output to tri-state driver
        sda_padoen_o => i2c_l12_sda_oen  -- enable signal for tri-state driver
    );

    -- L12 I2C signals
    i2c_l12_scl <= 'Z' when i2c_l12_scl_oen = '1' else i2c_l12_scl_o;
    i2c_l12_sda <= 'Z' when i2c_l12_sda_oen = '1' else i2c_l12_sda_o;
    i2c_l12_rst <= i2c_l12_rst_from_ipb; -- active-low reset

    -- ----------------------------------------------------
    sfp_l12_enabled_ports_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => sfp_l12_enabled_ports,
        sig_o => sfp_l12_enabled_ports_ttc
    );

    -- ----------------------------------------------------
    sfp_l12_enabled_ports_ext_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => fmc_header_n(0),
        sig_i => sfp_l12_enabled_ports,
        sig_o => sfp_l12_enabled_ports_ext
    );

    -- --------------------------------------------
    i2c_l8_top_wrapper: entity work.i2c_top_wrapper
    port map (
        -- clock and reset
        clk   => osc125_b_bufg,
        reset => hard_rst_osc125,

        -- control signals
        fmc_loc               => "11",          -- L8 LOC
        fmc_mod_type          => "00000001",    -- EDA-02708-V2 FMC
        fmc_absent            => fmc_l8_absent, -- FMC absent signal
        sfp_requested_ports_i => "00000000",    -- not used
        i2c_en_start          => '0',           -- not used
        i2c_rd_start          => '0',           -- not used

        -- generic read interface
        channel_sel_in       => "00000000",
        eeprom_map_sel_in    => '0',
        eeprom_start_adr_in  => "00000000",
        eeprom_num_regs_in   => "000000",
        eeprom_reg_out       => open,
        eeprom_reg_out_valid => open,

        -- status signals
        sfp_enabled_ports => open,
        sfp_sn            => open,
        sfp_mod_abs       => open,
        sfp_tx_fault      => open,
        sfp_rx_los        => open,

        change_mod_abs  => open,
        change_tx_fault => open,
        change_rx_los   => open,

        fs_state  => l8_fs_state,
        st_state  => l8_st_state,
        ssc_state => l8_ssc_state,
        sgr_state => l8_sgr_state,

        -- warning signals
        change_error_mod_abs  => open,
        change_error_tx_fault => open,
        change_error_rx_los   => open,

        -- error signals
        error_fmc_absent   => error_l8_fmc_absent,
        error_fmc_mod_type => error_l8_fmc_mod_type,
        error_fmc_int_n    => error_l8_fmc_int_n,
        error_startup_i2c  => error_l8_startup_i2c,

        sfp_en_error_mod_abs    => open,
        sfp_en_error_sfp_type   => open,
        sfp_en_error_tx_fault   => open,
        sfp_en_error_sfp_alarms => open,
        sfp_en_error_i2c_chip   => open,

        -- SFP alarm flags
        sfp_alarm_temp_high     => open,
        sfp_alarm_temp_low      => open,
        sfp_alarm_vcc_high      => open,
        sfp_alarm_vcc_low       => open,
        sfp_alarm_tx_bias_high  => open,
        sfp_alarm_tx_bias_low   => open,
        sfp_alarm_tx_power_high => open,
        sfp_alarm_tx_power_low  => open,
        sfp_alarm_rx_power_high => open,
        sfp_alarm_rx_power_low  => open,
          
        -- SFP warning flags
        sfp_warning_temp_high     => open,
        sfp_warning_temp_low      => open,
        sfp_warning_vcc_high      => open,
        sfp_warning_vcc_low       => open,
        sfp_warning_tx_bias_high  => open,
        sfp_warning_tx_bias_low   => open,
        sfp_warning_tx_power_high => open,
        sfp_warning_tx_power_low  => open,
        sfp_warning_rx_power_high => open,
        sfp_warning_rx_power_low  => open,

        -- I2C signals
        i2c_int_n_i  => '1',            -- active-low I2C interrupt signal (not used)
        scl_pad_i    => i2c_l8_scl,     -- input from external pin
        scl_pad_o    => i2c_l8_scl_o,   -- output to tri-state driver
        scl_padoen_o => i2c_l8_scl_oen, -- enable signal for tri-state driver
        sda_pad_i    => i2c_l8_sda,     -- input from external pin
        sda_pad_o    => i2c_l8_sda_o,   -- output to tri-state driver
        sda_padoen_o => i2c_l8_sda_oen  -- enable signal for tri-state driver
    );
    
    -- L8 I2C signals
    i2c_l8_scl <= 'Z' when i2c_l8_scl_oen = '1' else i2c_l8_scl_o;
    i2c_l8_sda <= 'Z' when i2c_l8_sda_oen = '1' else i2c_l8_sda_o;
    i2c_l8_rst <= i2c_l8_rst_from_ipb; -- active-low reset

    -- assert when I2C state machines are in their MONITOR state;
    -- except for L8 SSC state machine, which is held in reset
    fmcs_ready <= l8_fs_state(23) and l12_fs_state(23) and l8_ssc_state(0) and l12_ssc_state(9);

    -- -------------------------------------------
    fmc_eeprom_usr: entity work.fmc_eeprom_wrapper
    port map (
        -- clock and reset
        clk => osc125_b_bufg,
        rst => hard_rst_osc125,

        -- status
        l12_dev_active => '1',
        l08_dev_active => '1',
        l12_dev_ext => '0', -- Microchip 24AA025E48T-I/SN EEPROM
        l08_dev_ext => '0', -- Microchip 24AA025E48T-I/SN EEPROM
        fmcs_ready  => fmcs_ready,
        error_i2c   => fmc_eeprom_error_i2c,
        error_id    => fmc_eeprom_error_id,
        CS          => fe_state,

        -- write interface
        l12_fmc_id_request => l12_fmc_id_request_osc,
        l08_fmc_id_request => l8_fmc_id_request_osc,
        write_start        => fmc_ids_wr_start_pulse,

        -- read interface
        l12_fmc_id    => l12_fmc_id,
        l08_fmc_id    => l8_fmc_id,
        fmc_ids_valid => fmc_ids_valid,

        -- I2C signals
        scl_pad_i    => i2c_fmc_scl,
        scl_pad_o    => i2c_fmc_scl_o,
        scl_padoen_o => i2c_fmc_scl_oen,
        sda_pad_i    => i2c_fmc_sda,
        sda_pad_o    => i2c_fmc_sda_o,
        sda_padoen_o => i2c_fmc_sda_oen
    );

    -- FMC I2C signals
    i2c_fmc_scl <= 'Z' when i2c_fmc_scl_oen = '1' else i2c_fmc_scl_o;
    i2c_fmc_sda <= 'Z' when i2c_fmc_sda_oen = '1' else i2c_fmc_sda_o;


    -- ---------------
    -- FMC SFP outputs
    -- ---------------

    -- front panel mapping:
    -- --------- ||
    -- | H | G | ||
    -- | F | E | ||
    -- | D | C | ||
    -- | B | A | ||
    -- --------- ||
    
    sfp_tx_gen: for i in 0 to 7 generate
    begin
        -- synchronize delays
        l12_ttc_delay_sync: entity work.sync_2stage generic map (nbr_bits => 8) port map ( clk => ext_clk_x4, sig_i => l12_ttc_encoded_delay(i), sig_o => l12_ttc_encoded_delay_ttc(i) );

        -- delay data streams
        l12_ttc_delay_inst: entity work.shift_register generic map (delay_width => 8) port map ( clock => ext_clk_x4, delay => l12_ttc_encoded_delay_ttc(i), data_in => ttc_encoded, data_out => sfp_l12_tx_delay(i) );

        -- select enabled ports
        sfp_l12_tx(i) <= sfp_l12_tx_delay(i) when sfp_l12_enabled_ports(i) = '1' else '0';

        -- output data streams
        SFP_L12_TX_I_OBUFDS: OBUFDS port map ( I => sfp_l12_tx(i), O => sfp_l12_tx_p(i), OB => sfp_l12_tx_n(i) );
    end generate;


    -- ----------------
    -- FMC LEMO outputs
    -- ----------------

    -- control the output trigger specs
    boc_controller: entity work.boc_controller
    port map (
        clk               => fmc_header_n(0),
        trigger_in        => begin_of_cycle,
        trigger_disable_a => trig_out_disable_a_ext,
        trigger_disable_b => trig_out_disable_b_ext,
        var_width_a       => var_width_a_ext,
        var_width_b       => var_width_b_ext,
        trigger_delay_a   => trigger_delay_a_ext,
        trigger_delay_b   => trigger_delay_b_ext,
        trigger_out_a     => open,
        trigger_out_b     => trigger_out_b
    );

    -- send a handshake signal for the overflow_warning
    ofw_handshake_inst: entity work.ofw_handshake
    port map (
        clock        => fmc_header_n(0),
        reset        => hard_rst_ext,
        overflow     => combined_overflow_warning,
        basic_width  => var_width_b_ext,
        ofw_hshake   => ofw_handshake,
        ofw_latch    => ofw_latch
    );
    -- begin-of-cycle outputs.  MUX this with overflow_warning signals to allow throttling of appropriate analog triggers

    aux_lemo_b <= trigger_out_b or ofw_handshake;


    -- ------------------
    -- TTS receiver logic
    -- ------------------

    tts_rx_realign_i       <= (others => tts_rx_realign);
    sfp_tap_delay_i        <= sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay;
    sfp_tap_delay_strobe_i <= (others => sfp_tap_delay_strobe);

    -- -----------------------
    tts_rx: entity work.tts_rx
    generic map (
        idelayctrl_gen                  => true,
        idelaygroup                     => "l12_idelay_group",
        nbr_channels                    => 8,
        bitslip_delay                   => 1024,
        consecutive_valid_chars_to_lock => 1024,
        misaligned_state_code           => x"FF",
        allow_all_0000xxxx              => false
    )
    port map (
        -- clocks and reset
        reset_i         => tts_rx_rst_l12_from_ipb,
        clk_i           => ttc_clk,
        pclk_i          => ttc_clk_x2,              -- parallel clock
        sclk_i          => ttc_clk_x10,             -- serial clock
        -- alignment
        align_str_i     => tts_rx_realign_i,        -- when 0, in alignment cycle, to realign 0->1->0
        aligned_o       => l12_aligned_a,           -- when 1, bitslip is successful
        -- delays
        idelay_manual_i => sfp_tap_delay_manual,
        idelay_ld_i     => sfp_tap_delay_strobe_i,  -- strobe for loading input delay values
        idelay_tap_i    => sfp_tap_delay_i,         -- dynamically loadable delay tap value for input delay
        idelay_tap_o    => l12_idelay_tap_a,        -- delay tap value for monitoring input delay
        idelay_locked_o => l12_idelay_locked_a,     -- idelay ctrl locked
        idelay_clk_i    => ttc_clk_x5,              -- reference clock for idelayctrl, has to come from bufg
        -- statistics
        stats_clr       => x"00",
        stats_cnt       => l12_stats_cnt_a,         -- delay tap value for monitoring input delay
        -- inputs and outputs
        i               => sfp_l12_rx_p,
        ib              => sfp_l12_rx_n,
        o               => l12_tts_state_out,
        dv_o            => l12_tts_state_valid
    );

    -- TTS state update
    process(ttc_clk)
    begin
        if rising_edge(ttc_clk) then
            for i in 0 to 7 loop
                if l12_tts_state_valid(i) = '1' and l12_aligned_a(i) = '1' then
                    -- update TTS state
                    l12_tts_state(4*i+3 downto 4*i) <= l12_tts_state_out(8*i+3 downto 8*i);

                    -- record TTS state changes
                    if l12_tts_state(4*i+3 downto 4*i) /= l12_tts_state_out(8*i+3 downto 8*i) then
                        -- TTS state changed
                        l12_tts_state_prev(4*i+3 downto 4*i) <= l12_tts_state(4*i+3 downto 4*i);
                        l12_tts_update_timer(i) <= x"0000_0000_0000_0000"; -- clear timer
                    else
                        l12_tts_update_timer(i) <= l12_tts_update_timer(i) + 1;
                    end if;
                else
                    -- keep the same TTS state
                    l12_tts_state(4*i+3 downto 4*i) <= l12_tts_state(4*i+3 downto 4*i);
                    l12_tts_update_timer(i) <= l12_tts_update_timer(i) + 1;
                end if;
            end loop;
        end if;
    end process;

    -- TTS state lock
    process(ttc_clk)
    begin
        if rising_edge(ttc_clk) then
            -- loop over each port
            for i in 0 to 7 loop
                -- lock counter logic
                if l12_tts_state_valid(i) = '1' and l12_aligned_a(i) = '1' then
                    if l12_tts_lock_cnt(i) = tts_lock_threshold_sync then
                        l12_tts_lock_cnt(i) <= l12_tts_lock_cnt(i); -- keep value at threshold
                    else
                        l12_tts_lock_cnt(i) <= l12_tts_lock_cnt(i) + 1; -- increment lock counter
                    end if;
                else
                    if l12_tts_lock_cnt(i) > 0 then
                        l12_tts_lock_cnt(i) <= l12_tts_lock_cnt(i) - 1; -- decrement lock counter
                    end if;
                end if;

                -- locked logic
                if l12_tts_lock_cnt(i) >= (tts_lock_threshold_sync - tts_misaligned_allowed_sync) then
                    l12_tts_lock(i) <= '1'; -- locked
                else
                    l12_tts_lock(i) <= '0'; -- not locked
                end if;
            end loop;

            -- define system lock
            if ((l12_tts_lock xor (sfp_l12_enabled_ports_ttc xor l12_tts_state_mask_ttc)) and (sfp_l12_enabled_ports_ttc xor l12_tts_state_mask_ttc)) = x"00" then
                tts_lock_mux <= ttc_clk_lock and ttc_ready; -- lock only valid if ttc_clk is valid
            else
                tts_lock_mux <= '0';
            end if;
        end if;
    end process;

    -- TTS state interpreter
    process(ttc_clk)
    begin
        if rising_edge(ttc_clk) then
            -- loop over each port
            for i in 0 to 7 loop
                -- default
                tts_msa(i) <= '0';
                tts_dis(i) <= '0';
                tts_err(i) <= '0';
                tts_syl(i) <= '0';
                tts_bsy(i) <= '0';
                tts_ofw(i) <= '0';
                tts_rdy(i) <= '0';

                -- overwrite one of the bits, when state is valid and not masked off
                case l12_tts_state(4*i+3 downto 4*i) is
                    when "0000" => tts_dis(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "1111" => tts_dis(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "1100" => tts_err(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "0010" => tts_syl(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "0100" => tts_bsy(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "0001" => tts_ofw(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when "1000" => tts_rdy(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                    when others => tts_msa(i) <= tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l12_tts_state_mask_ttc(i));
                end case;
            end loop;

            -- define L12 state
            if    tts_dis /= x"00" then l12_tts_status <= "000001"; -- disconnected
            elsif tts_err /= x"00" then l12_tts_status <= "000010"; -- error
            elsif tts_syl /= x"00" then l12_tts_status <= "000100"; -- sync lost
            elsif tts_msa /= x"00" then l12_tts_status <= "000100"; -- sync lost / misaligned
            elsif tts_bsy /= x"00" then l12_tts_status <= "001000"; -- busy
            elsif tts_ofw /= x"00" then l12_tts_status <= "010000"; -- overflow warning
            else                        l12_tts_status <= "100000"; -- ready
            end if;
        end if;
    end process;

    -- combine local state conditions;
    -- they must be independent of TTS RX signals
    local_error     <= '1' when fmc_ids_valid        = '0' or over_temp              = '1' or
                                ext_clk_lock         = '0' or ttc_clk_lock           = '0' or
                                ttc_ready            = '0' or
                                error_l12_fmc_absent = '1' or error_l12_fmc_mod_type = '1' or error_l12_fmc_int_n = '1' or
                                error_l8_fmc_absent  = '1' or error_l8_fmc_mod_type  = '1' or error_l8_fmc_int_n  = '1' or
                                xadc_alarms               /= x"0"  or
                                change_error_l12_mod_abs  /= x"00" or
                                change_error_l12_tx_fault /= x"00" or
                                change_error_l12_rx_los   /= x"00" else '0';
    local_sync_lost <= not tts_lock_mux;
    local_overflow  <= trig_info_fifo_full;
    -- for encoder we do not care about the mbit/sbit errors
    --  from old local_error definition:          error_ttc_sbit_limit = '1' or error_ttc_mbit_limit   = '1' or 
    -- define local and system states
    process(osc125_b_bufg)
    begin
        if rising_edge(osc125_b_bufg) then
            -- local state, accounting for priority
            if    local_error     = '1' then local_tts_state <= "1100"; -- error
            elsif local_sync_lost = '1' then local_tts_state <= "0010"; -- sync lost
            --    local_busy      = '1' then local_tts_state <= "0100"; -- busy
            elsif local_overflow  = '1' then local_tts_state <= "0001"; -- overflow warning
            else                             local_tts_state <= "1000"; -- ready
            end if;

            -- system state, accounting for priority
            if                                l12_tts_status(0) = '1' then system_status <= "000001"; -- disconnected
            elsif local_tts_state = "1100" or l12_tts_status(1) = '1' then system_status <= "000010"; -- error
            elsif local_tts_state = "0010" or l12_tts_status(2) = '1' then system_status <= "000100"; -- sync lost
            elsif                             l12_tts_status(3) = '1' then system_status <= "001000"; -- busy
            elsif local_tts_state = "0001" or l12_tts_status(4) = '1' then system_status <= "010000"; -- overflow warning
            else                                                           system_status <= "100000"; -- ready
            end if;
        end if;
    end process;

    abort_run        <= '1' when system_status(3 downto 0) /= "0000" or ttc_clk_lock = '0' or ttc_ready = '0' or force_exit = '1' else '0';
    overflow_warning <= system_status(4);

    -- -----------------------------------------------
    overflow_warning_ext_sync: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => overflow_warning,
        sig_o(0) => overflow_warning_sync
    );


    -- -----------------
    -- TTC decoder logic
    -- -----------------

    -- ---------------------------------
    ttc_decoder: entity work.TTC_decoder
    port map (
        TTC_CLK_p   => fabric_clk_p,     -- backplane clock p
        TTC_CLK_n   => fabric_clk_n,     -- backplane clock n
        TTC_rst     => ttc_decoder_rst,  -- reset
        TTC_data_p  => ttc_rx_p,         -- input data p
        TTC_data_n  => ttc_rx_n,         -- input data n
        TTC_CLK_out => ttc_clk,          -- output clock
        TTCready    => ttc_ready,        -- module ready
        L1Accept    => ttc_raw_trigger,  -- trigger
        BCntRes     => ttc_bcnt_reset,   -- bunch count reset
        EvCntRes    => ttc_evt_reset,    -- event count reset
        SinErrStr   => ttc_sbit_error,   -- single-bit error
        DbErrStr    => ttc_mbit_error,   -- multi-bit error
        BrcstStr    => ttc_chan_b_valid, -- channel b valid
        Brcst       => ttc_chan_b_info   -- channel b data
    );

    trigger_from_ttc <= ttc_raw_trigger and ttc_ready;

    -- monitor single- and multi-bit errors
    process(ttc_clk)
    begin
        if rising_edge(ttc_clk) then
            -- count error occurances
            if rst_ttc = '1' then
                ttc_sbit_error_cnt_global <= (others => '0');
                ttc_mbit_error_cnt_global <= (others => '0');

                ttc_sbit_error_cnt <= (others => '0');
                ttc_mbit_error_cnt <= (others => '0');
            else
                -- global counter
                if ttc_sbit_error = '1' then
                    ttc_sbit_error_cnt_global <= ttc_sbit_error_cnt_global + 1;
                end if;

                if ttc_mbit_error = '1' then
                    ttc_mbit_error_cnt_global <= ttc_mbit_error_cnt_global + 1;
                end if;

                -- in-run counter
                if run_enable = '1' and ttc_sbit_error = '1' then
                    ttc_sbit_error_cnt <= ttc_sbit_error_cnt + 1;
                elsif run_enable = '0' then
                    ttc_sbit_error_cnt <= (others => '0'); -- clear count when run is disabled
                end if;

                if run_enable = '1' and ttc_mbit_error = '1' then
                    ttc_mbit_error_cnt <= ttc_mbit_error_cnt + 1;
                elsif run_enable = '0' then
                    ttc_mbit_error_cnt <= (others => '0'); -- clear count when run is disabled
                end if;
            end if;

            -- check threshold limits
            if ttc_sbit_error_cnt > ttc_sbit_error_threshold then
                error_ttc_sbit_limit <= '1';
            else
                error_ttc_sbit_limit <= '0';
            end if;
            
            if ttc_mbit_error_cnt > ttc_mbit_error_threshold then
                error_ttc_mbit_limit <= '1';
            else
                error_ttc_mbit_limit <= '0';
            end if;
        end if;
    end process;


    -- -----------------------
    -- trigger sequencer logic
    -- -----------------------

    -- 2-stage synchronizer
    process(fmc_header_n(0))
    begin
        if rising_edge(fmc_header_n(0)) then
            seq_trig_type_sync1 <= seq_trig_type;
            seq_trig_type_sync2 <= seq_trig_type_sync1;

            seq_pre_trig_gap_sync1 <= seq_pre_trig_gap;
            seq_pre_trig_gap_sync2 <= seq_pre_trig_gap_sync1;

            seq_count_sync1 <= seq_count;
            seq_count_sync2 <= seq_count_sync1;
        end if;
    end process;

    seq_trig_type_sync    <= seq_trig_type_sync2;
    seq_pre_trig_gap_sync <= seq_pre_trig_gap_sync2;
    seq_count_sync        <= seq_count_sync2;

    -- ----------------------------------------------------
    enable_async_storage_sync_inst: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => enable_async_storage,
        sig_o(0) => enable_async_storage_sync
    );

    -- --------------------------------------------------
    l12_eeprom_reg_out_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 128)
    port map (
        clk   => fmc_header_n(0),
        sig_i => l12_eeprom_reg_out,
        sig_o => l12_eeprom_reg_out_sync
    );

    -----------------------------------------------------------------
    l12_eeprom_reg_out_valid_stretch_inst: entity work.signal_stretch
    port map (
        clk      => osc125_b_bufg,
        n_cycles => x"08",
        sig_i    => l12_eeprom_reg_out_valid,
        sig_o    => l12_eeprom_reg_out_valid_stretch
    );

    -- --------------------------------------------------------
    l12_eeprom_reg_out_valid_sync_inst: entity work.sync_2stage
    port map (
        clk      => fmc_header_n(0),
        sig_i(0) => l12_eeprom_reg_out_valid_stretch,
        sig_o(0) => l12_eeprom_reg_out_valid_sync
    );

    -- trigger sequencer
    trigger_sequencer_usr: entity work.trigger_sequencer_wrapper
    port map (
        -- clock and reset
        clk => fmc_header_n(0),
        rst => rst_ext,

        -- reset interface
        post_rst_delay_evt_cnt    => post_rst_delay_evt_cnt_sync,
        post_rst_delay_timestamp  => post_rst_delay_timestamp_sync,
        post_rst_delay_async      => post_rst_delay_async_sync,

        -- trigger interface
        run_enable            => run_enable_sync,
        run_pause             => run_pause_sync,
        abort_run             => abort_run,
        no_beam_structure     => no_beam_structure,
        enable_async_storage  => enable_async_storage_sync,
        global_count          => global_seq_count_sync,
        ofw_cycle_threshold   => ofw_watchdog_theshold_sync,
        cycle_start_threshold => cycle_start_theshold_sync,
        eor_wait_count        => eor_wait_count_sync,
        trigger               => latched_trigger,
        send_ofw_boc          => send_ofw_boc_sync,
        begin_of_cycle        => begin_of_cycle,
        internal_trigger_strt => internal_trigger_strt,
        internal_trigger_stop => internal_trigger_stop,
        a6_missed_restart     => missed_a6_seq_restart,
        trigger_clear         => clear_latched_trigger,

        -- transceiver checks
        eeprom_channel_sel => seq_eeprom_channel_sel,
        eeprom_map_sel     => seq_eeprom_map_sel,
        eeprom_start_adr   => seq_eeprom_start_adr,
        eeprom_num_regs    => seq_eeprom_num_regs,
        eeprom_read_start  => seq_eeprom_read_start,
        eeprom_reg         => l12_eeprom_reg_out_sync,
        eeprom_reg_valid   => l12_eeprom_reg_out_valid_sync,

        -- sequence information
        trig_count_seq   => seq_count_sync,
        trig_type_seq    => seq_trig_type_sync,
        pre_trig_gap_seq => seq_pre_trig_gap_sync,

        -- TTC interface
        channel_a       => channel_a_from_seq,
        channel_b_data  => channel_b_data_from_seq,
        channel_b_valid => channel_b_valid_from_seq,

        -- trigger information interface
        trig_timestamp  => trig_timestamp,
        trig_num        => trig_num,
        trig_type_num   => trig_type_num,
        trig_type       => trig_type,
        trig_delay      => trig_delay,
        trig_index      => trig_index,
        trig_sub_index  => trig_sub_index,
        trig_info_valid => trig_info_valid,

        -- status signals
        overflow_warning        => combined_overflow_warning,
        sfp_enabled_ports       => sfp_l12_enabled_ports_ext,
        state                   => ts_state,
        run_timer               => run_timer,
        ofw_cycle_count_running => ofw_cycle_count_running,
        ofw_cycle_count         => ofw_cycle_count,
        ofw_limit_reached       => ofw_limit_reached,
        run_in_progress         => run_in_progress,
        doing_run_checks        => doing_run_checks,
        resetting_clients       => resetting_clients,
        finding_cycle_start     => finding_cycle_start,
        run_aborted             => run_aborted,
        missing_trigger         => missing_A6,
        async_enable_sent       => async_enable_sent
    );

    -- ------------------------------------------------------
    seq_eeprom_channel_sel_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => osc125_b_bufg,
        sig_i => seq_eeprom_channel_sel,
        sig_o => seq_eeprom_channel_sel_sync
    );

    -- --------------------------------------------------
    seq_eeprom_map_sel_sync_inst: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => seq_eeprom_map_sel,
        sig_o(0) => seq_eeprom_map_sel_sync
    );

    -- ----------------------------------------------------
    seq_eeprom_start_adr_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => osc125_b_bufg,
        sig_i => seq_eeprom_start_adr,
        sig_o => seq_eeprom_start_adr_sync
    );

    -- ---------------------------------------------------
    seq_eeprom_num_regs_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 6)
    port map (
        clk   => osc125_b_bufg,
        sig_i => seq_eeprom_num_regs,
        sig_o => seq_eeprom_num_regs_sync
    );

    -- -----------------------------------------------------
    seq_eeprom_read_start_sync_inst: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => seq_eeprom_read_start,
        sig_o(0) => seq_eeprom_read_start_sync
    );

    -- trigger information state machine
    process(fmc_header_n(0))
    begin
        if rising_edge(fmc_header_n(0)) then
            -- State 0
            if trig_info_sm_state = '0' then
                tis_state <= "01";
                if trig_info_valid = '1' then
                    s_trig_info_fifo_tdata( 43 downto   0) <= trig_timestamp;
                    s_trig_info_fifo_tdata( 67 downto  44) <= trig_num;
                    s_trig_info_fifo_tdata( 72 downto  68) <= trig_type;
                    s_trig_info_fifo_tdata(104 downto  73) <= trig_delay;
                    s_trig_info_fifo_tdata(108 downto 105) <= trig_index;
                    s_trig_info_fifo_tdata(112 downto 109) <= trig_sub_index;

                    trig_info_sm_state      <= '1';
                    s_trig_info_fifo_tvalid <= '1';
                else
                    trig_info_sm_state      <= '0';
                    s_trig_info_fifo_tvalid <= '0';
                end if;

            -- State 1
            else
                tis_state <= "10";
                if s_trig_info_fifo_tready = '1' then
                    trig_info_sm_state      <= '0';
                    s_trig_info_fifo_tvalid <= '0';
                else
                    trig_info_sm_state      <= '1';
                    s_trig_info_fifo_tvalid <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Trigger Information FIFO : 2048 depth, 2047 almost full threshold, 16-byte data width
    -- holds the trigger timestamp, trigger number, trigger type, pre-trigger delay, sequencer index, and sequencer sub-index
    trig_info_fifo: entity work.trig_info_fifo
    port map (
        wr_rst_busy    => wr_rst_busy_trig,
        rd_rst_busy    => rd_rst_busy_trig,
        m_aclk         => osc125_b_bufg,
        s_aclk         => fmc_header_n(0),
        s_aresetn      => rst_ext_n,
        s_axis_tvalid  => s_trig_info_fifo_tvalid,
        s_axis_tready  => s_trig_info_fifo_tready,
        s_axis_tdata   => s_trig_info_fifo_tdata,
        m_axis_tvalid  => m_trig_info_fifo_tvalid,
        m_axis_tready  => m_trig_info_fifo_tready,
        m_axis_tdata   => m_trig_info_fifo_tdata,
        axis_prog_full => trig_info_fifo_full
    );

    count_trigger_for_mark_debug: entity work.input_counter
    port map (
        clk                    => fmc_header_n(0),
        reset                  => rst_ext,
        input_pulse            => channel_a_from_seq,
        pulse_count            => channel_a_counter
    );

    count_ttc_trigger_for_mark_debug: entity work.input_counter
    port map (
        clk                    => fmc_header_n(0),
        reset                  => rst_ext,
        input_pulse            => trigger_from_ttc_esync,
        pulse_count            => ttc_esync_counter
    );

    -- ------------------
    -- TTC encoding logic
    -- ------------------

    -- 2-stage synchronizer
    process(ext_clk_x4)
    begin
        if rising_edge(ext_clk_x4) then
            a_channel1 <= channel_a_from_seq;
            a_channel2 <= a_channel1;
            a_channel3 <= a_channel2;

            -- rising-edge detect
            if a_channel2 = '1' and a_channel3 = '0' then
                a_channel_sync <= '1';
            else
                a_channel_sync <= '0';
            end if;

            b_channel1 <= channel_b_data_from_seq;
            b_channel2 <= b_channel1;

            b_channel_valid1 <= channel_b_valid_from_seq;
            b_channel_valid2 <= b_channel_valid1;
            b_channel_valid3 <= b_channel_valid2;

            -- rising-edge detect
            if b_channel_valid2 = '1' and b_channel_valid3 = '0' then
                b_channel_valid_sync <= '1';
            else
                b_channel_valid_sync <= '0';
            end if;
        end if;
    end process;

    -- ----------------------------------------------
    ttc_data_hamming: entity work.ttc_chan_b_data_mux
    port map (
        clk       => ext_clk_x4,
        b_channel => b_channel2,
        ttc_data  => ttc_data
    );

    -- ----------------------------------------
    ttc_signal: entity work.ttc_encoder_wrapper
    port map (
        clk            => ext_clk_x4,
        rst            => rst_ext_x4,
        a_channel      => a_channel_sync,
        ttc_data       => ttc_data,
        ttc_data_valid => b_channel_valid_sync,
        ttc_bit_out    => ttc_encoded
    );


    -- --------------
    -- DAQ link logic
    -- --------------

    xadc_alarms <= alarm_vccbram & alarm_vccaux & alarm_vccint & alarm_temp;

    -- -------------------------------------------------
    event_builder_usr: entity work.event_builder_wrapper
    port map (
        -- clock and reset
        clk => osc125_b_bufg,
        rst => rst_osc125,

        -- data connections
        m_trig_info_fifo_tvalid => m_trig_info_fifo_tvalid,
        m_trig_info_fifo_tready => m_trig_info_fifo_tready,
        m_trig_info_fifo_tdata  => m_trig_info_fifo_tdata,

        m_pulse_info_fifo_tvalid => '0',
        m_pulse_info_fifo_tready => open,
        m_pulse_info_fifo_tdata  => (others => '0'),

        -- controls
        ttc_trigger => trig_clk125,

        -- static event information
        fc7_type           => "01",
        major_rev          => usr_ver_major,
        minor_rev          => usr_ver_minor,
        patch_rev          => usr_ver_patch,
        board_id           => board_id,
        l12_fmc_id         => l12_fmc_id,
        l8_fmc_id          => l8_fmc_id,
        otrig_disable_a    => trig_out_disable_a,
        otrig_disable_b    => trig_out_disable_b,
        otrig_delay_a      => trigger_delay_a,
        otrig_delay_b      => trigger_delay_b,
        otrig_width_a      => var_width_a,
        otrig_width_b      => var_width_b,
        tts_lock_thres     => tts_lock_threshold,
        ofw_watchdog_thres => ofw_watchdog_theshold,
        l12_enabled_ports  => sfp_l12_enabled_ports,
        l8_enabled_ports   => x"00",
        l12_tts_mask       => l12_tts_state_mask,
        l8_tts_mask        => x"00",
        l12_ttc_delays     => l12_ttc_encoded_delay,
        l8_ttc_delays      => (others => (others => '0')),
        l12_sfp_sn         => sfp_l12_sn,
        l8_sfp_sn          => (others => (others => '0')),

        -- variable event information
        l12_tts_state             => l12_tts_state,
        l8_tts_state              => x"00000000",
        l12_tts_lock              => l12_tts_lock,
        l8_tts_lock               => x"00",
        l12_tts_lock_mux          => tts_lock_mux,
        l8_tts_lock_mux           => '0',
        ext_clk_lock              => ext_clk_lock,
        ttc_clk_lock              => ttc_clk_lock,
        ttc_ready                 => ttc_ready,
        xadc_alarms               => xadc_alarms,
        error_flag                => abort_run,
        error_l12_fmc_absent      => error_l12_fmc_absent,
        error_l8_fmc_absent       => error_l8_fmc_absent,
        change_error_l12_mod_abs  => change_error_l12_mod_abs,
        change_error_l8_mod_abs   => x"00",
        change_error_l12_tx_fault => change_error_l12_tx_fault,
        change_error_l8_tx_fault  => x"00",
        change_error_l12_rx_los   => change_error_l12_rx_los,
        change_error_l8_rx_los    => x"00",

        -- interface to AMC13 DAQ Link
        daq_ready       => daq_ready,
        daq_almost_full => daq_almost_full,
        daq_valid       => daq_valid,
        daq_header      => daq_header,
        daq_trailer     => daq_trailer,
        daq_data        => daq_data,

        -- status
        state => eb_state
    );

    daq_link_trig <= (others => trigger_from_ttc);

    -- ----------------------------------
    daq_link: entity work.DAQ_LINK_Kintex
    generic map (
        F_REFCLK         => 125,
        SYSCLK_IN_period => 8, -- unit is ns
        USE_TRIGGER_PORT => false
    )
    port map (
        reset => rst_osc125, -- asynchronous reset, assert reset until GTX REFCLK stable
        -- GTX signals
        GTX_REFCLK => osc125_a_mgtrefclk,
        GTX_RXN    => daq_rxn,
        GTX_RXP    => daq_rxp,
        GTX_TXN    => daq_txn,
        GTX_TXP    => daq_txp,
        -- trigger port
        TTCclk  => ttc_clk,
        BcntRes => ttc_bcnt_reset,
        trig    => daq_link_trig,
        -- TTS port
        TTSclk => osc125_b_bufg, -- clock source which clocks TTS signals
        TTS    => local_tts_state,
        -- SYSCLK_IN is required by the GTX ip core, you can connect any clock source
        -- (e.g. TTSclk, TTCclk or EventDataClk) as long as its period is in the range
        -- of 8-250 ns (do not forget to specify its period in the generic port)
        SYSCLK_IN => osc125_b_bufg,
        -- data port
        ReSyncAndEmpty    => '0',
        EventDataClk      => osc125_b_bufg,
        EventData_valid   => daq_valid,       -- data write enable
        EventData_header  => daq_header,      -- first data word
        EventData_trailer => daq_trailer,     -- last data word
        EventData         => daq_data,
        AlmostFull        => daq_almost_full, -- buffer almost full
        Ready             => daq_ready
    );

end usr;
