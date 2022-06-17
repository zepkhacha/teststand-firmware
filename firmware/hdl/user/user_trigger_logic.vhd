-- Top-level module for the Trigger FC7 user logic

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

entity user_trigger_logic is 
port (
    -- clocks
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

    -- FMC headers
    fmc_header_p : out std_logic_vector(31 downto  0);
    fmc_header_n :  in std_logic_vector(31 downto  0);

    -- FMC status
    fmc_l12_absent : in std_logic;
    fmc_l8_absent  : in std_logic;

    -- FMC LEMOs
    aux_lemo_a : in std_logic;
    aux_lemo_b : in std_logic;
    tr0_lemo_p : in std_logic;
    tr0_lemo_n : in std_logic;
    tr1_lemo_p : in std_logic;
    tr1_lemo_n : in std_logic;

    -- FMC I2C
    i2c_fmc_scl : inout std_logic;
    i2c_fmc_sda : inout std_logic;

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
    ipb_mosi_i : in  ipb_wbus_array(0 to nbr_usr_trg_slaves-1);
    ipb_miso_o : out ipb_rbus_array(0 to nbr_usr_trg_slaves-1);

    -- other
    reprog_fpga : out std_logic;
    user_reset  : out std_logic;
    board_id    : in  std_logic_vector(10 downto 0)
);
end user_trigger_logic;

architecture usr of user_trigger_logic is

    -- I/O banks

    signal abank_out : std_logic_vector(7 downto 0);
    signal bbank_out : std_logic_vector(7 downto 0);
    signal cbank_out : std_logic_vector(7 downto 0);
    signal dbank_out : std_logic_vector(7 downto 0);

    signal abank_in  : std_logic_vector(3 downto 0);

    -- clocks
    signal ttc_clk_x12p5     : std_logic;
    signal ttc_clk_x5_0      : std_logic;
    signal ttc_clk           : std_logic;

    -- clock wizard locks
    signal ttc_clk_lock      : std_logic;
    signal ttc_clk_lock_200M : std_logic;
    signal a6_clock_locks    : std_logic_vector(2 downto 0);
    signal clocks_500_lock   : std_logic;

    -- resets
    signal rst_ttc_n           : std_logic;
    signal rst_from_ipbus      : std_logic;
    signal soft_rst_from_ipbus : std_logic;
    signal rst_ipb             : std_logic;
    signal rst_ipb_stretch     : std_logic;
    signal init_rst_ipb        : std_logic;
    signal sys_rst_ipb         : std_logic;

    signal rst_osc125, hard_rst_osc125, soft_rst_osc125, auto_soft_rst_osc125 : std_logic;
    signal rst_ttc,    hard_rst_ttc,    soft_rst_ttc,    auto_soft_rst_ttc    : std_logic;
    signal user_reset_internal : std_logic;
    signal sequence_reset      : std_logic;

    signal auto_soft_rst         : std_logic;
    signal auto_soft_rst_sync1   : std_logic;
    signal auto_soft_rst_sync2   : std_logic;
    signal auto_soft_rst_sync3   : std_logic;
    signal auto_soft_rst_stretch : std_logic;
    signal auto_soft_rst_delay   : std_logic;

    signal i2c_l8_rst_from_ipb      : std_logic;
    signal ttc_decoder_rst_from_ipb : std_logic;
    signal ttc_decoder_rst          : std_logic;

    -- trigger logic signals
    signal tr0_lemo,     tr0_lemo_inv     : std_logic;
    signal tr1_lemo,     tr1_lemo_inv     : std_logic;
    signal trx_lemo_sel, trx_lemo_inv     : std_logic;
    signal trig_clk125,  trig_clk125_sync : std_logic;

    signal aux_lemo_a_internal, aux_lemo_b_internal : std_logic;
    signal acc_trigger_0                            : std_logic;
    signal begin_of_supercycle, accel_boc           : std_logic;
    signal gap_detected, latch_enable               : std_logic;


    -- -- logic at 200 MHz
    signal acc_trigger_0_200M,   acc_cycle_start_0_200M   : std_logic;
    signal acc_trigger_180_200M, acc_cycle_start_180_200M : std_logic;
    signal acc_trig_fanout_0_200M   : std_logic_vector(13 downto 7);
    signal kicker_asynch            : std_logic;

    -- choose 8 or 16 triggers per cycle
    signal trig_cycle_toggle_8_16  : std_logic;
    signal trigger_per_cycle_limit : std_logic_vector(3 downto 0);
    signal penultimate_seq         : std_logic;
    signal use_second_cycle        : std_logic_vector(0 downto 0);
    signal second_cycle_seen       : std_logic;
    signal sequence_error          : std_logic;
	 signal active_cycle            : integer range 0 to  1;
    signal assrt_penu_delay        : std_logic_vector( 3 downto 0);
    signal assrt_cyc2_delay        : std_logic_vector(23 downto 0);

    -- laser prescaling trigger logic signals
    signal acc_cycle_start_40MHz : std_logic;
    signal prescaled_cycle       : std_logic;
    signal laser_prescale_factor : std_logic_vector(7 downto 0);
    signal laser_channel_out     : std_logic_vector(3 downto 0);
    signal laser_channel_p1      : std_logic_vector(3 downto 0);
    signal laser_trigger_signal  : std_logic;
    signal laser_trigger_select     : std_logic;
    signal always_send_laser_trig   : std_logic; -- by default, laser triggers only sent when run is active.  This will send laser triggers independently of run state
    signal send_laser_triggers      : std_logic;

    signal ttc_raw_trigger          : std_logic;
    signal trigger_from_ttc         : std_logic;
    signal trigger_from_ttc_delayed : std_logic;
    signal ttc_trigger_out          : std_logic;
    signal ttc_trig_out_width       : std_logic_vector( 7 downto 0);
    signal ttc_trig_out_width_sync  : std_logic_vector( 7 downto 0);
    signal ttc_trig_out_width_use   : std_logic_vector( 9 downto 0);
    signal ttc_trig_out_delay       : std_logic_vector(31 downto 0);
    signal ttc_trig_out_delay_sync  : std_logic_vector(31 downto 0);

    -- kicker T9-related parameters
    signal t9_kickerSignals_width   : std_logic_vector( 8 downto 0);
    signal t9_kickCapChg_delay      : std_logic_vector(31 downto 0);
    signal internal_trigger_fallbck : std_logic;
    signal internal_trigger_fallbck_stretch, internal_trigger_fallbck_ttc : std_logic;
    signal internal_trigger_force   : std_logic;
    signal internal_trigger_boc     : std_logic; --  a boc generated from the internal triggering
    signal use_internal_trigger_boc : std_logic; --  use the internal boc => free running mode
    signal force_internal_trigger_boc : std_logic; --  use the internal boc => free running mode
    signal internal_trigger_force_stretch, internal_trigger_force_ttc : std_logic;
    signal enable_T9_adjust         : std_logic;
    signal accel_a6_missing         : std_logic;
    signal a6_missing_threshold     : std_logic_vector(31 downto 0);
    signal t9_gapcorr_reset         : std_logic;
    signal t9_gapcorr_reset_stretch, t9_gapcorr_reset_ttc, reset_gapcorr : std_logic;
    signal t9_gap_correction        : std_logic_vector(31 downto 0);
    signal t9_correction_valid      : std_logic;
    signal apply_t9_correction      : std_logic;
    signal t9_pulse                 : std_logic;
    signal t9_delayed_pulse         : std_logic;
    signal t9_use, t9_accel         : std_logic;
    signal t9_use_stretch           : std_logic;
    signal t9_triggers_uninhibited  : std_logic_vector(3 downto 0);
    signal t9_kicker_triggers       : std_logic_vector(3 downto 0);
    signal t9_trigger_armed         : std_logic_vector(3 downto 0);
    signal debug_kicker_triggers    : std_logic_vector(3 downto 0);
    signal a6_source                : std_logic;
    signal a6_for_encoder           : std_logic;
    signal a6_and_transition_for_encoder : std_logic;
    signal an_a6_missed             : std_logic_vector(3 downto 0);
    signal ignore_t9                : std_logic;
    signal generate_sequence_abort  : std_logic;
    signal abort_current_sequence   : std_logic;
    signal encoder_abort            : std_logic;
    signal aborted_cycle_count      : std_logic_vector( 31 downto 0);
    signal infill_laser_on_internal : std_logic;
    signal infill_laser_on_internal_stretch : std_logic;
    signal infill_laser_on_internal_ttc : std_logic;
    signal use_infill               : std_logic;
    signal oosync_gap_threshold     : std_logic_vector(31 downto 0);
    signal boc_oos                  : std_logic;
    signal out_of_sync_count        : std_logic_vector(7 downto 0);
    signal out_of_sync_count_reset_ipb   : std_logic;
    signal out_of_sync_count_rst_stretch : std_logic;
    signal out_of_sync_count_rst_sync    : std_logic;
    signal out_of_sync_count_reset  : std_logic;
    signal stretch_lemo_b           : std_logic;

--    signal pulse_delay_parameters         : array_2_12_8_4_4x7bit;
--    signal pulse_width_parameters         : array_2_12_8_2_4x5bit;
    signal pulse_delay_parms_shifted_fast : array_7_8_4_4x7bit;
    signal pulse_width_parms_shifted_fast : array_7_8_2_4x5bit;
--    signal pulse_delay_parms_shifted_slow : array_3_8_4_4x7bit;
--    signal pulse_width_parms_shifted_slow : array_3_8_2_4x5bit;
--    signal pulse_delay_parms_shifted_slow : array_5_8_4_4x7bit;
--    signal pulse_width_parms_shifted_slow : array_5_8_2_4x5bit;
    signal pulse_delay_parms_shifted_slow : array_7u_8_4_4x7bit;
    signal pulse_width_parms_shifted_slow : array_7u_8_2_4x5bit;
--    signal pulse_enabled_both             : array_2_12_8x4bit;
    signal pulse_enabled_fast_both        : fast_enabled_reg_t;
    signal pulse_enabled_slow_both        : slow_enabled_reg_t;
    signal pulse_enabled_fast             : array_7_8x4bit;
--    signal pulse_enabled_slow             : array_3_8x4bit;
--    signal pulse_enabled_slow             : array_5_8x4bit;
    signal pulse_enabled_slow             : array_7u_8x4bit;
    signal storableDelay3                 : array_10_4x7bit;
    signal storableDelay2                 : array_10_4x7bit;
    signal storableDelay1                 : array_10_4x7bit;
    signal storableDelay0                 : array_10_4x7bit;
    signal storableWidth1                 : array_10_2x5bit;
    signal storableWidth0                 : array_10_2x5bit;
    signal trigger_encoder                : std_logic;
    signal trigger_out      : std_logic_vector(13 downto 0);
    signal counter_err      : std_logic_vector( 1 downto 0);
    signal seq_index_0      : std_logic_vector( 3 downto 0);
    signal seq_index_180    : std_logic_vector( 3 downto 0);
    signal seq_index_200M   : std_logic_vector( 3 downto 0);
    signal counter_val_sync : std_logic_vector( 3 downto 0);
    signal boc_pulse_length : std_logic_vector( 7 downto 0);
    signal throttle_asynch  : std_logic;

    signal pulse_delay_param_fast_test  : fast_delay_reg_t;
    signal pulse_width_param_fast_test  : fast_width_reg_t;
    signal pulse_delay_param_slow_test  : slow_delay_reg_t;
    signal pulse_width_param_slow_test  : slow_width_reg_t;

--  kicker related
    signal kicker_t9_pulse_delays : array_4_2_8x32bit;
    signal kicker_t9_ctrl         : array_8x32bit;
    signal t9_kickerSignals_enabled : std_logic_vector( 3 downto 0);
    signal kicker_tsq               : array_3x32bit;
    signal safety_discharge_timing : std_logic_vector(31 downto 0);
    signal discharge_deadtime      : std_logic_vector(31 downto 0);
    signal charging_deadtime       : std_logic_vector(31 downto 0);
    signal safety_trigger          : std_logic_vector(2 downto 0);
    signal k_combined_no_inhibit   : std_logic_vector(2 downto 0);
--    signal k_combined_stretch      : std_logic_vector(2 downto 0);
--    signal k_combined_200MHz       : std_logic_vector(2 downto 0);
    signal k_combined_discharge    : std_logic_vector(2 downto 0);
    signal discharge_inhibit       : std_logic_vector(2 downto 0);

--  quad related
    signal a6_quadSignal_enabled   : std_logic;
    signal t9_quadSignal_enabled   : std_logic;
    signal quad_t9_pulse_delay     : std_logic_vector(31 downto 0);
    signal quad_t9_pulse_width     : std_logic_vector(23 downto 0);
    signal t9_trigger_quad         : std_logic;
    signal a6_trigger_quad         : std_logic;
    signal combined_trigger_quad   : std_logic;
    signal delayed_t9_quad         : std_logic;
    signal stretched_t9_quad       : std_logic;

    -- IPbus slave registers
    signal stat_reg : stat_reg_t;
    signal ctrl_reg : ctrl_reg_t;

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

    -- DAQ link
    signal daq_data        : std_logic_vector(63 downto 0);
    signal daq_almost_full : std_logic;
    signal daq_ready       : std_logic;
    signal daq_valid       : std_logic;
    signal daq_header      : std_logic;
    signal daq_trailer     : std_logic;
    signal daq_link_trig   : std_logic_vector( 7 downto 0);

    -- finite state machine states
    signal eb_state  : std_logic_vector(18 downto 0);
    signal tis_state : std_logic_vector( 1 downto 0);
    signal fe_state  : std_logic_vector(11 downto 0);

    signal l8_fs_state,  l12_fs_state  : std_logic_vector(27 downto 0);
    signal l8_sgr_state, l12_sgr_state : std_logic_vector( 6 downto 0);
    signal l8_ssc_state, l12_ssc_state : std_logic_vector(10 downto 0);
    signal l8_st_state,  l12_st_state  : std_logic_vector(32 downto 0);

    -- internal trigger parameters and signals
    signal supercycle_period        : std_logic_vector(31 downto 0);
    signal eight_cycle_period       : std_logic_vector(31 downto 0);
    signal eight_cycle_delay        : std_logic_vector(31 downto 0);
    signal second_cycle_gap         : std_logic_vector(31 downto 0);
    signal max_eight_cycle_delay    : std_logic_vector(31 downto 0);
    signal internal_t9              : std_logic;
    signal internal_t9_stretch      : std_logic;
    signal internal_a6              : std_logic;
    signal internal_cycle_active    : std_logic;
    signal internal_trigger_enabled : std_logic;
    signal cycle8_active            : std_logic;
    signal trigger_transitioning    : std_logic;

    -- run information
    signal run_enable           : std_logic;
    signal run_disabled         : std_logic;
    signal begin_of_run         : std_logic;
    signal begin_of_run_stretch : std_logic;
    signal end_of_run           : std_logic;
    signal end_of_run_delayed   : std_logic;
    signal end_of_run_stretch   : std_logic;
    signal run_latch_enable     : std_logic;
    signal run_status_latch     : std_logic;

    -- trigger information
    signal trig_num        : std_logic_vector(23 downto 0);
    signal trig_type_num   : array_32x24bit;
    signal trig_timestamp  : std_logic_vector(43 downto 0);
    signal trig_type       : std_logic_vector( 4 downto 0);
    signal trig_info_valid : std_logic;

    -- Trigger/Pulse Information FIFO
    signal s_trig_info_fifo_tdata  : std_logic_vector(127 downto 0);
    signal s_trig_info_fifo_tready : std_logic;

    signal m_trig_info_fifo_tdata  : std_logic_vector(127 downto 0);
    signal m_trig_info_fifo_tvalid : std_logic;
    signal m_trig_info_fifo_tready : std_logic;

    signal s_pulse_info_fifo_tdata  : std_logic_vector(2047 downto 0);
    signal s_pulse_info_fifo_tready : std_logic;

    signal m_pulse_info_fifo_tdata  : std_logic_vector(2047 downto 0);
    signal m_pulse_info_fifo_tvalid : std_logic;
    signal m_pulse_info_fifo_tready : std_logic;

    signal s_x_info_fifo_tready : std_logic;
    signal s_x_info_fifo_tvalid : std_logic;
    signal trig_info_sm_state   : std_logic;
    signal trig_info_fifo_full  : std_logic;
    signal pulse_info_fifo_full : std_logic;

    signal wr_rst_busy_trig,  rd_rst_busy_trig  : std_logic;
    signal wr_rst_busy_pulse, rd_rst_busy_pulse : std_logic;
    
    -- FMC SFP configuration
    signal error_l8_fmc_absent,  error_l12_fmc_absent : std_logic;
    signal error_l8_fmc_mod_type                      : std_logic;
    signal error_l8_fmc_int_n                         : std_logic;
    signal error_l8_startup_i2c                       : std_logic;

    -- FMC I2C
    signal i2c_fmc_scl_o,   i2c_l8_scl_o   : std_logic;
    signal i2c_fmc_scl_oen, i2c_l8_scl_oen : std_logic;
    signal i2c_fmc_sda_o,   i2c_l8_sda_o   : std_logic;
    signal i2c_fmc_sda_oen, i2c_l8_sda_oen : std_logic;

    signal fmcs_ready                                  : std_logic;
    signal fmc_eeprom_error_i2c,  fmc_eeprom_error_id  : std_logic;
    signal fmc_ids_wr_start,      fmc_ids_wr_start_osc : std_logic;
    signal fmc_ids_wr_start_pulse                      : std_logic;
    signal fmc_ids_valid                               : std_logic;

    signal l8_fmc_id_request,     l12_fmc_id_request     : std_logic_vector(7 downto 0);
    signal l8_fmc_id_request_osc, l12_fmc_id_request_osc : std_logic_vector(7 downto 0);
    signal l8_fmc_id,             l12_fmc_id             : std_logic_vector(7 downto 0);

    -- TTS
    signal local_tts_state : std_logic_vector(3 downto 0);
    signal local_error     : std_logic;
    signal local_sync_lost : std_logic;
    signal local_overflow  : std_logic;
    signal abort_run       : std_logic;

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

    -- capture FMC inputs
    signal fmc_header_n_internal  : std_logic_vector(16 downto 0);

    -- monitoring the delay for the TTC data input
    signal ttc_data_delay : std_logic_vector( 4 downto 0);
    signal ttc_ddelay_rdy : std_logic;

    -- keeps
    attribute keep : string;
    attribute keep of ttc_decoder_rst : signal is "true";

    -- arrays to allow flexible mapping of 32 signals to the 4 spare output ports
    signal debuglines      : std_logic_vector(31 downto 0);
    signal debugline1      : integer range 0 to 31;
    signal debugline2      : integer range 0 to 31;
    signal debugline3      : integer range 0 to 31;
    signal debugline4      : integer range 0 to 31;

    -- debugs
--    attribute mark_debug : string;
--    attribute keep       : string;
--    attribute mark_debug of aux_lemo_a_internal : signal is "true";
--    attribute keep       of aux_lemo_a_internal : signal is "true";
--    attribute mark_debug of trigger_from_ttc : signal is "true";
--    attribute keep       of trigger_from_ttc : signal is "true";
--    attribute mark_debug of ttc_trigger_out : signal is "true";
--    attribute keep       of ttc_trigger_out : signal is "true";

begin

    -- ----------
    -- Bank I/O
    -- ----------
    fmc_header_p(31) <= abank_out(0);
    fmc_header_p(27) <= abank_out(1);
    fmc_header_p(23) <= abank_out(2);
    fmc_header_p(19) <= abank_out(3);
    fmc_header_p(15) <= abank_out(4);
    fmc_header_p(11) <= abank_out(5);
    fmc_header_p( 7) <= abank_out(6);
    fmc_header_p( 3) <= abank_out(7);


    fmc_header_p(30) <= bbank_out(0);
    fmc_header_p(26) <= bbank_out(1);
    fmc_header_p(22) <= bbank_out(2);
    fmc_header_p(18) <= bbank_out(3);
    fmc_header_p(14) <= bbank_out(4);
    fmc_header_p(10) <= bbank_out(5);
    fmc_header_p( 6) <= bbank_out(6);
    fmc_header_p( 2) <= bbank_out(7);


    fmc_header_p(29) <= cbank_out(0);
    fmc_header_p(25) <= cbank_out(1);
    fmc_header_p(21) <= cbank_out(2);
    fmc_header_p(17) <= cbank_out(3);
    fmc_header_p(13) <= cbank_out(4);
    fmc_header_p( 9) <= cbank_out(5);
    fmc_header_p( 5) <= cbank_out(6);
    fmc_header_p( 1) <= cbank_out(7);


    fmc_header_p(28) <= dbank_out(0);
    fmc_header_p(24) <= dbank_out(1);
    fmc_header_p(20) <= dbank_out(2);
    fmc_header_p(16) <= dbank_out(3);
    fmc_header_p(12) <= dbank_out(4);
    fmc_header_p( 8) <= dbank_out(5);
    fmc_header_p( 4) <= dbank_out(6);
    fmc_header_p( 0) <= dbank_out(7);

    -- ---------------
    -- FMC Input banks
    -- ---------------
    -- bank A 0-3
    abank_0_ibuf: IBUF port map (I => fmc_header_n(31), O => abank_in(0) );
    abank_1_ibuf: IBUF port map (I => fmc_header_n(27), O => abank_in(1) );
    abank_2_ibuf: IBUF port map (I => fmc_header_n(23), O => abank_in(2) );
    abank_3_ibuf: IBUF port map (I => fmc_header_n(19), O => abank_in(3) );

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

    -- -----------------------------------
    clk_wiz_500M_singePhase: entity work.clk_wiz_500M_singlePhase
    port map (
        clk_in1  => ttc_clk,
        clk_out1 => ttc_clk_x12p5,
        locked   => ttc_clk_lock
    );
    clk_wiz_trig_200M: entity work.clk_wiz_trig_200M
    port map (
        clk_in1  => ttc_clk,
        clk_out1 => ttc_clk_x5_0,
        locked   => ttc_clk_lock_200M
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
    rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => hard_rst_ttc
    );

    -- stretch T9 to A6 gap correction reset and then synch it to the ttc clock
    reset_t9_correction_inst: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => t9_gapcorr_reset,
        sig_o    => t9_gapcorr_reset_stretch
    );

    -- ---------------------------------------------
    reset_t9_correction_ttc: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => t9_gapcorr_reset_stretch,
        sig_o(0) => t9_gapcorr_reset_ttc
    );

    stretch_force_internal: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => internal_trigger_force,
        sig_o    => internal_trigger_force_stretch
    );

    synch_force_internal: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => internal_trigger_force_stretch,
        sig_o(0) => internal_trigger_force_ttc
    );

    stretch_fallback_internal: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => internal_trigger_fallbck,
        sig_o    => internal_trigger_fallbck_stretch
    );

    synch_fallback_internal: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => internal_trigger_fallbck_stretch,
        sig_o(0) => internal_trigger_fallbck_ttc
    );

    stretch_infill: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => infill_laser_on_internal,
        sig_o    => infill_laser_on_internal_stretch
    );

    synch_infill: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => infill_laser_on_internal_stretch,
        sig_o(0) => infill_laser_on_internal_ttc
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

    -- automatic soft reset generation
    -- to recover from any spurious outputs from the TTC decoder
    process(osc125_b_bufg)
    begin
        if rising_edge(osc125_b_bufg) then
            auto_soft_rst_sync1 <= ttc_ready;
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
    auto_soft_rst_delay_inst: entity work.pulse_delay
    generic map (nbr_bits => 8)
    port map (
        clock     => osc125_b_bufg,
        delay     => x"7C", -- 1-us delay
        pulse_in  => auto_soft_rst_stretch,
        pulse_out => auto_soft_rst_delay
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

    generate_sequence_abort <= or_reduce(an_a6_missed) and not ignore_t9;
    encoder_abort_trigger: entity work.level_to_pulse
    port map (
        clk   => ttc_clk,
        sig_i => generate_sequence_abort,
        sig_o => abort_current_sequence
    );

    generate_encoder_abort: entity work.fast_variable_pulse -- 100 ns / "length bit"
    port map (
        clk      => ttc_clk,
        trigger  => abort_current_sequence,
        length   => "1000", -- 800 ns
        pulse    => encoder_abort
    );

    -- count the number of cycles that we have aborted
    count_cycle_abort: entity work.input_counter
    port map (
        clk         => ttc_clk,
        reset       => rst_ttc,
        input_pulse => abort_current_sequence,
        pulse_count => aborted_cycle_count
    );

    -- help debug encoder / trigger handshake issues by checking A6 / BOC timing
    -- in trigger as well as encoder FC7
    -- monitor the timing of the a6 signal relative to the boc to see if we've gotten out of sync
    oos_check: entity work.sequence_sync_monitor
    port map (
       clock       => ttc_clk,
       reset       => rst_ttc,
       boc_in      => begin_of_supercycle, -- to here
       a6_in       => a6_source,
       minimum_gap => oosync_gap_threshold,
       out_of_seq  => boc_oos
    );
    
    stretch_oosc_rst: entity work.signal_stretch
    port map (
        clk      => ipb_clk,
        n_cycles => x"04",
        sig_i    => out_of_sync_count_reset_ipb,
        sig_o    => out_of_sync_count_rst_stretch
    );

    -- ----------------------------------
    oos_rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => out_of_sync_count_rst_stretch,
        sig_o(0) => out_of_sync_count_rst_sync
    );

    out_of_sync_count_reset <= rst_ttc or out_of_sync_count_rst_sync;
    oos_count: entity work.input_counter
    generic map ( nbr_bits => 8 )
    port map (
        clk         => ttc_clk,
        reset       => out_of_sync_count_reset,
        input_pulse => boc_oos,
        pulse_count => out_of_sync_count
    );

    rst_osc125 <= hard_rst_osc125 or soft_rst_osc125 or auto_soft_rst_osc125;
    rst_ttc    <= hard_rst_ttc    or soft_rst_ttc    or auto_soft_rst_ttc;
    rst_ttc_n  <= not rst_ttc;
    reset_gapcorr <= rst_ttc or t9_gapcorr_reset_ttc;

    user_reset_internal <= rst_ipb or soft_rst_from_ipbus;
    user_reset          <= user_reset_internal;
    sequence_reset      <= trigger_transitioning or rst_ttc or abort_current_sequence;


    -- -----------
    -- LED mapping
    -- -----------

    -- FC7 baseboard
    top_led2(0) <= not error_l12_fmc_absent;
    top_led2(1) <= error_l12_fmc_absent;
    top_led2(2) <= '1';

    top_led3(0) <= not error_l8_fmc_absent and not error_l8_fmc_mod_type and not error_l8_fmc_int_n;
    top_led3(1) <= error_l8_fmc_absent or error_l8_fmc_mod_type or error_l8_fmc_int_n;
    top_led3(2) <= '1';

    bot_led1(0) <= ttc_clk_lock and clocks_500_lock and ttc_clk_lock_200M and ttc_ready;
    bot_led1(1) <= not ttc_clk_lock or not clocks_500_lock or not ttc_ready or not ttc_clk_lock_200M;
    bot_led1(2) <= '1';

    bot_led2(0) <= clocks_500_lock;
    bot_led2(1) <= '0';
    bot_led2(2) <= '1';

    -- EDA-02708 FMC
    fmc_l8_led(8) <= '0'; -- misaligned or disconnected
    fmc_l8_led(7) <= '1' when ttc_ready = '1' and local_tts_state = "1100" else '0'; -- error
    fmc_l8_led(6) <= '1' when ttc_ready = '1' and local_tts_state = "0010" else '0'; -- sync lost
    fmc_l8_led(5) <= '1' when ttc_ready = '1' and local_tts_state = "0100" else '0'; -- busy
    fmc_l8_led(4) <= '1' when ttc_ready = '1' and local_tts_state = "0001" else '0'; -- overflow warning
    fmc_l8_led(3) <= '1' when ttc_ready = '1' and local_tts_state = "1000" else '0'; -- ready

    fmc_l8_led2(0) <= internal_trigger_enabled;
    fmc_l8_led2(1) <= '0';
    
    fmc_l8_led1(0) <= trig_info_fifo_full;
    fmc_l8_led1(1) <= pulse_info_fifo_full;


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
        run_in_progress => run_enable,
        ipbus_in        => ipb_mosi_i(user_ipb_ctrl_regs),
        ipbus_out       => ipb_miso_o(user_ipb_ctrl_regs),
        regs_o          => ctrl_reg
    );

    -- ----------------------------------------------
	trig_regs_inst: entity work.ipb_user_trigger_regs
	port map (
	    clk             => ipb_clk,
        reset           => rst_ipb,
        run_in_progress => run_enable,
        ipbus_in        => ipb_mosi_i(user_ipb_trig_regs),
        ipbus_out       => ipb_miso_o(user_ipb_trig_regs),
    	regs_delay_fast => pulse_delay_param_fast_test,
    	regs_width_fast => pulse_width_param_fast_test,
    	regs_delay_slow => pulse_delay_param_slow_test,
    	regs_width_slow => pulse_width_param_slow_test,
		pulse_enabled_fast => pulse_enabled_fast_both,
		pulse_enabled_slow => pulse_enabled_slow_both
    );

    -- ----------------------------------------------
	trig_t9_regs_inst: entity work.ipb_user_t9_trigger_regs
	port map (
        clk             => ipb_clk,
        reset           => rst_ipb,
        run_in_progress => run_enable,
        ipbus_in        => ipb_mosi_i(user_ipb_trig_t9_regs),
        ipbus_out       => ipb_miso_o(user_ipb_trig_t9_regs),
        regs_t9_delay   => kicker_t9_pulse_delays,
        reg_t9_ctrl     => kicker_t9_ctrl
    );


    -- ----------------
    -- register mapping
    -- ----------------

    -- status register
    -- two-stage synchronization is performed in slave module
    stat_reg( 0) <= "11" & "00" & x"0" & usr_ver_major & usr_ver_minor & usr_ver_patch;
    stat_reg( 1) <= x"0" & l8_fmc_id & l12_fmc_id & '0' & board_id;
    stat_reg( 2) <= x"000" & '0' & pulse_info_fifo_full & trig_info_fifo_full & fmc_ids_valid & fmc_eeprom_error_id & fmc_eeprom_error_i2c & fmcs_ready & '0' & '0' & ttc_ready & '0' & ttc_clk_lock; -- PARTLY RESERVED FOR ENCODER, FANOUT USE
    stat_reg( 3) <= measured_vccint  & measured_temp;
    stat_reg( 4) <= measured_vccbram & measured_vccaux;
    stat_reg( 5) <= x"000000" & "000" & alarm_vccbram & alarm_vccaux & alarm_vccint & alarm_temp & over_temp;
    stat_reg( 6) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg( 7) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg( 8) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg( 9) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(10) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(11) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(12) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(13) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(14) <= x"0000000" & "000" & error_l12_fmc_absent; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(15) <= x"0000000" & error_l8_startup_i2c & error_l8_fmc_int_n & error_l8_fmc_mod_type & error_l8_fmc_absent; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(16) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(17) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(18) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(19) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(20) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(21) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(22) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(23) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(24) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(25) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(26) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(27) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(28) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(29) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(30) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(31) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(32) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(33) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(34) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(35) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(36) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(37) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(38) <= x"00" & '0' & "000000" & local_tts_state & "000000"; -- PARTLY RESERVED FOR FANOUT USE
    stat_reg(39) <= eb_state(15 downto  0) & x"0000"; -- PARTLY RESERVED FOR ENCODER USE
    stat_reg(40) <= eb_state(18 downto 16) & l12_st_state(32) & l12_fs_state;
    stat_reg(41) <= "000" & l8_st_state(32) & l8_fs_state;
    stat_reg(42) <= l12_st_state(31 downto 0);
    stat_reg(43) <= l8_st_state(31 downto 0);
    stat_reg(44) <= x"00" & tis_state & l8_ssc_state & l12_ssc_state;
    stat_reg(45) <= x"0" & "000" & fe_state & l8_sgr_state & l12_sgr_state;
    stat_reg(46) <= x"00000000"; -- RESERVED FOR ENCODER USE
    stat_reg(47) <= x"00" & trig_num;
    stat_reg(48) <= trig_timestamp(31 downto 0);
    stat_reg(49) <= x"00000" & trig_timestamp(43 downto 32);
    stat_reg(50) <= ttc_sbit_error_cnt;
    stat_reg(51) <= ttc_mbit_error_cnt;
    stat_reg(52) <= x"0" & x"000000" & "00" & error_ttc_mbit_limit & error_ttc_sbit_limit;
    stat_reg(53) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(54) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(55) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(56) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(57) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(58) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
    stat_reg(59) <= x"00000000"; -- RESERVED FOR FANOUT USE
    stat_reg(60) <= x"00000000"; -- RESERVED FOR ENCODER USE
    stat_reg(61) <= x"00000000"; -- RESERVED FOR ENCODER USE
    stat_reg(62) <= ttc_sbit_error_cnt_global;
    stat_reg(63) <= ttc_mbit_error_cnt_global;

    sfp_sn_regs: for i in 0 to 7 generate
    begin
        stat_reg(64 + 4*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
        stat_reg(65 + 4*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
        stat_reg(66 + 4*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
        stat_reg(67 + 4*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE

        stat_reg(96 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(97 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(98 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(99 + 4*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
    end generate;

    trig_type_num_regs: for i in 0 to 31 generate
    begin
        stat_reg(128 + i) <= x"00000000"; -- RESERVED FOR ENCODER USE
    end generate;

    tts_timer_regs: for i in 0 to 7 generate
    begin
        stat_reg(160 + 2*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE
        stat_reg(161 + 2*i) <= x"00000000"; -- RESERVED FOR ENCODER, FANOUT USE

        stat_reg(176 + 2*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
        stat_reg(177 + 2*i) <= x"00000000"; -- RESERVED FOR FANOUT USE
    end generate;

	-- trigger status
    --                                      7                 6               5                       4                          3                  2           1:0
	stat_reg(192)( 7 downto 0) <= gap_detected & prescaled_cycle & cycle8_active & internal_cycle_active & internal_trigger_enabled & accel_a6_missing & counter_err;
   stat_reg(192)(          8) <= apply_t9_correction;
	stat_reg(192)(31 downto 9) <= (others => '0');

--	begin
    stat_reg(193)( 3 downto 0) <= counter_val_sync;
    stat_reg(193)(31 downto 4) <= (others => '0');
    stat_reg(194) <= (others => '0'); -- RESERVED FOR ENCODER USE
    stat_reg(195)              <= aborted_cycle_count;
    stat_reg(196)              <= t9_gap_correction; 
    stat_reg(197)( 5 downto 0) <= ttc_ddelay_rdy & ttc_data_delay; -- fill the unused registers with zeros
    stat_reg(197)(31 downto 6) <= (others => '0');
    stat_reg(198)              <= x"00000" & out_of_sync_count & "0000";
    stat_reg(199) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(200) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(201) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(202) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(203) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(204) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(205) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(206) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(207) <= (others => '0'); -- fill the unused registers with zeros
    stat_reg(208) <= (others => '0'); -- fill the unused registers with zeros

-- control register
    rst_from_ipbus           <= ctrl_reg( 0)( 0);
    soft_rst_from_ipbus      <= ctrl_reg( 0)( 1);
    run_enable               <= ctrl_reg( 0)( 2);
    -- RESERVED              <= ctrl_reg( 0)( 3);
    -- RESERVED              <= ctrl_reg( 0)( 4);
    reprog_fpga_from_ipb     <= ctrl_reg( 0)( 5);
    -- RESERVED              <= ctrl_reg( 1);
    -- RESERVED              <= ctrl_reg( 2)( 7 downto  0);
    -- RESERVED              <= ctrl_reg( 2)(15 downto  8);
    -- UNUSED                <= ctrl_reg( 2)(31 downto 16);
    ttc_trig_out_width       <= ctrl_reg( 3)( 7 downto  0); -- default set
    -- RESERVED              <= ctrl_reg( 3)(11 downto  8);
    -- RESERVED              <= ctrl_reg( 4)(23 downto  0); -- default set
    -- RESERVED              <= ctrl_reg( 5);               -- default set
    -- RESERVED              <= ctrl_reg( 6);               -- default set
    -- RESERVED              <= ctrl_reg( 7)( 0);
    -- RESERVED              <= ctrl_reg( 7)( 1);
    -- RESERVED              <= ctrl_reg( 7)( 6 downto  2);
    -- RESERVED              <= ctrl_reg( 7)( 7);
    -- RESERVED              <= ctrl_reg( 7)( 8);
    -- RESERVED              <= ctrl_reg( 7)( 9);
    -- RESERVED              <= ctrl_reg( 8)( 7 downto  0);
    -- RESERVED              <= ctrl_reg( 8)( 8);
    -- RESERVED              <= ctrl_reg( 8)(16 downto  9);
    -- RESERVED              <= ctrl_reg( 8)(22 downto 17);
    -- RESERVED              <= ctrl_reg( 8)(23);
    -- RESERVED              <= ctrl_reg( 8)(24);
    -- RESERVED              <= ctrl_reg( 9)( 7 downto  0);
    -- RESERVED              <= ctrl_reg( 9)(15 downto  8);
    -- RESERVED              <= ctrl_reg( 9)(16);
    -- RESERVED              <= ctrl_reg( 9)(17);
    -- RESERVED              <= ctrl_reg( 9)(18);           -- default set
    i2c_l8_rst_from_ipb      <= ctrl_reg( 9)(19);           -- default set
    trig_cycle_toggle_8_16   <= ctrl_reg( 9)(20);
    laser_prescale_factor    <= ctrl_reg( 9)(28 downto 21);
    l12_fmc_id_request       <= ctrl_reg(10)( 7 downto  0);
    l8_fmc_id_request        <= ctrl_reg(10)(15 downto  8);
    fmc_ids_wr_start         <= ctrl_reg(10)(16);
    -- RESERVED              <= ctrl_reg(11)( 7 downto  0);
    -- RESERVED              <= ctrl_reg(11)(15 downto  8);
    -- RESERVED              <= ctrl_reg(11)(23 downto 16);
    -- RESERVED              <= ctrl_reg(11)(31 downto 24);
    -- RESERVED              <= ctrl_reg(12)( 7 downto  0);
    -- RESERVED              <= ctrl_reg(12)(15 downto  8);
    -- RESERVED              <= ctrl_reg(12)(23 downto 16);
    -- RESERVED              <= ctrl_reg(12)(31 downto 24);
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
    -- RESERVED              <= ctrl_reg(17)( 7 downto  0); -- default set
    boc_pulse_length         <= ctrl_reg(17)(15 downto  8); -- default set
    -- RESERVED              <= ctrl_reg(17)(23 downto 16); -- default set
    -- RESERVED              <= ctrl_reg(17)(31 downto 24); -- default set
    ttc_decoder_rst_from_ipb <= ctrl_reg(18)(0);
    -- RESERVED              <= ctrl_reg(19)(0);            -- default set
    -- RESERVED              <= ctrl_reg(20);               -- default set
    -- RESERVED              <= ctrl_reg(21);
    -- RESERVED              <= ctrl_reg(22);
    trx_lemo_sel             <= ctrl_reg(23)(0);
    -- RESERVED              <= ctrl_reg(24);
    -- RESERVED              <= ctrl_reg(25);               -- default set
    -- RESERVED              <= ctrl_reg(26);               -- default set
    -- RESERVED              <= ctrl_reg(27);
    -- RESERVED              <= ctrl_reg(28);
    ttc_trig_out_delay       <= ctrl_reg(29);
    eight_cycle_delay        <= ctrl_reg(30); 
    eight_cycle_period       <= ctrl_reg(31); 
    second_cycle_gap         <= ctrl_reg(32);
    supercycle_period        <= ctrl_reg(33); -- the 1.2'ish period
    a6_missing_threshold     <= ctrl_reg(34);
    internal_trigger_fallbck <= ctrl_reg(35)(0);
    internal_trigger_force   <= ctrl_reg(35)(1);
    enable_T9_adjust         <= ctrl_reg(35)(2);
    t9_gapcorr_reset         <= ctrl_reg(35)(3);
    force_internal_trigger_boc <= ctrl_reg(35)(4);
-- debug --    infill_laser_on_internal <= ctrl_reg(35)(12);
    always_send_laser_trig   <= ctrl_reg(35)(13);
    ignore_t9                <= ctrl_reg(35)(14);
    max_eight_cycle_delay    <= ctrl_reg(36);
    assrt_penu_delay         <= ctrl_reg(37)(27 downto 24);
    assrt_cyc2_delay         <= ctrl_reg(37)(23 downto  0);
    oosync_gap_threshold     <= ctrl_reg(38);
    safety_discharge_timing  <= ctrl_reg(39);
    discharge_deadtime       <= ctrl_reg(40);
    charging_deadtime        <= ctrl_reg(41);
    quad_t9_pulse_delay      <= ctrl_reg(42);
    quad_t9_pulse_width      <= ctrl_reg(43)(23 downto 0);
    t9_quadSignal_enabled    <= ctrl_reg(43)(24);
    a6_quadSignal_enabled    <= ctrl_reg(43)(25);
    out_of_sync_count_reset_ipb <= ctrl_reg(43)(26);
    -- RESERVED                 ctrl_reg(44);
    -- RESERVED                 ctrl_reg(45);
    debugline1               <=  to_integer(unsigned(ctrl_reg(46)( 4 downto  0)));
    debugline2               <=  to_integer(unsigned(ctrl_reg(46)( 9 downto  5)));
    debugline3               <=  to_integer(unsigned(ctrl_reg(46)(14 downto 10)));
    debugline4               <=  to_integer(unsigned(ctrl_reg(46)(19 downto 15)));

	-- copy the parameters for the next cycle of eight fills
	active_cycle <= 0 when  use_second_cycle(0) = '0' else 1;
	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			pulse_delay_parms_shifted_fast <= pulse_delay_param_fast_test(active_cycle);
			pulse_delay_parms_shifted_slow <= pulse_delay_param_slow_test(active_cycle);
			pulse_width_parms_shifted_fast <= pulse_width_param_fast_test(active_cycle);
			pulse_width_parms_shifted_slow <= pulse_width_param_slow_test(active_cycle);
			pulse_enabled_fast             <= pulse_enabled_fast_both(active_cycle);
			pulse_enabled_slow             <= pulse_enabled_slow_both(active_cycle);
		end if;
	end process;


    -- store pulse information for the active sequence
    trig_info_if: for i in 0 to 6 generate
        trig_info_jf: for j in 0 to 3 generate
            process(ttc_clk)
            begin
                if rising_edge(ttc_clk) then
                    storableDelay3(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(3)(j))) + 1,7));
                    storableDelay2(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(2)(j))) + 1,7));
                    storableDelay1(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(1)(j))) + 1,7));
                    storableDelay0(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(0)(j))) + 1,7));
                    s_pulse_info_fifo_tdata(128*i + 32*j + 23 downto 128*i + 32*j     ) <= 
                          storableDelay3(i)(j)(5 downto 0)
                        & storableDelay2(i)(j)(5 downto 0)
                        & storableDelay1(i)(j)(5 downto 0)
                        & storableDelay0(i)(j)(5 downto 0);
                    storableWidth1(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_width_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(1)(j))) + 1,5));
                    storableWidth0(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_width_parms_shifted_fast(i)(to_integer(unsigned(counter_val_sync)))(0)(j))) + 1,5));
                    s_pulse_info_fifo_tdata(128*i + 32*j + 31 downto 128*i + 32*j + 24) <= 
                          storableWidth1(i)(j)(3 downto 0)
                        & storableWidth0(i)(j)(3 downto 0);
                end if;
            end process;
        end generate trig_info_jf;
    end generate trig_info_if;
    trig_info_is: for i in 7 to 9 generate
        trig_info_js: for j in 0 to 3 generate
            process(ttc_clk)
            begin
                if rising_edge(ttc_clk) then
                    storableDelay3(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(3)(j))) + 1,7));
                    storableDelay2(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(2)(j))) + 1,7));
                    storableDelay1(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(1)(j))) + 1,7));
                    storableDelay0(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_delay_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(0)(j))) + 1,7));
                    s_pulse_info_fifo_tdata(128*i + 32*j + 23 downto 128*i + 32*j     ) <= 
                          storableDelay3(i)(j)(5 downto 0)
                        & storableDelay2(i)(j)(5 downto 0)
                        & storableDelay1(i)(j)(5 downto 0)
                        & storableDelay0(i)(j)(5 downto 0);
                    storableWidth1(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_width_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(1)(j))) + 1,5));
                    storableWidth0(i)(j) <= std_logic_vector(to_signed(to_integer(signed(pulse_width_parms_shifted_slow(i)(to_integer(unsigned(counter_val_sync)))(0)(j))) + 1,5));
                    s_pulse_info_fifo_tdata(128*i + 32*j + 31 downto 128*i + 32*j + 24) <= 
                          storableWidth1(i)(j)(3 downto 0)
                        & storableWidth0(i)(j)(3 downto 0);
                end if;
            end process;
        end generate trig_info_js;
    end generate trig_info_is;
--  store the T9-based trigger info here
    t9_pulse_is: for iChan in 0 to 3 generate
        process(ttc_clk)
        begin
            if rising_edge(ttc_clk) then
                s_pulse_info_fifo_tdata(1280 + 32*iChan + 31 downto 1280 + 32*iChan) <= kicker_t9_pulse_delays(iChan)(active_cycle)(to_integer(unsigned(counter_val_sync)));
            end if;
        end process;
    end generate;

    -- store information bits: start on a 32-bit boundary
    s_pulse_info_fifo_tdata(1411 downto 1408) <= counter_val_sync;
    s_pulse_info_fifo_tdata(1412)             <= prescaled_cycle;
    s_pulse_info_fifo_tdata(1413)             <= internal_trigger_enabled;
    s_pulse_info_fifo_tdata(1414)             <= internal_trigger_force_ttc;
    s_pulse_info_fifo_tdata(1415)             <= apply_t9_correction;
    s_pulse_info_fifo_tdata(1471 downto 1416) <= (others => '0');

    -- store the observed time for kicker charge to fire
    s_pulse_info_fifo_tdata(1503 downto 1472) <= kicker_tsq(0);
    s_pulse_info_fifo_tdata(1535 downto 1504) <= kicker_tsq(1);
    s_pulse_info_fifo_tdata(1567 downto 1536) <= kicker_tsq(2);

    -- zero out the unused bits in the fifo
    s_pulse_info_fifo_tdata(2047 downto 1568 ) <= (others => '0');

    -- triggers per cycle limit.  We count to 0 so for 8 trigs / cycle, limit is "0111" and for 16 it is "1111"
--    trigger_per_cycle_limit <= "111";
    trigger_per_cycle_limit <= trig_cycle_toggle_8_16 & "111";


    -- kicker t9-based controls
    t9_kickerSignals_enabled <= kicker_t9_ctrl(0)(3 downto 0);
    t9_kickerSignals_width   <= '0' & kicker_t9_ctrl(1)(7 downto 0);

    -- --------------------------------
    -- control register synchronization
    -- --------------------------------

    -- delay signal by passing through 32-bit shift register (to allow time for IPbus ack)
    reprog_fpga_delay_inst: entity work.shift_register
    generic map (delay_width => 5)
    port map (
        clock    => ipb_clk,
        delay    => "11111",
        data_in  => reprog_fpga_from_ipb,
        data_out => reprog_fpga
    );

    -- -------------------------------------------------
    ttc_trig_out_width_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => ttc_trig_out_width,
        sig_o => ttc_trig_out_width_sync
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
    ttc_decoder_rst_inst: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => ttc_decoder_rst_from_ipb,
        sig_o(0) => ttc_decoder_rst
    );

    -- -------------------------------------------------
    ttc_trig_out_delay_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 32)
    port map (
        clk   => ttc_clk,
        sig_i => ttc_trig_out_delay,
        sig_o => ttc_trig_out_delay_sync
    );

    -- -------------------------------------------------
    begin_of_run_detected: entity work.level_to_pulse
    port map (
        clk   => ttc_clk_x5_0,
        sig_i => run_enable,
        sig_o => begin_of_run
    );
    bor_stretch_inst: entity work.signal_stretch
    port map (
        clk      => ttc_clk_x5_0,
        n_cycles => x"0F",
        sig_i    => begin_of_run,
        sig_o    => begin_of_run_stretch
    );
    run_disabled <= not run_enable;
    end_of_run_detected: entity work.level_to_pulse
    port map (
        clk   => ttc_clk_x5_0,
        sig_i => run_disabled,
        sig_o => end_of_run
    );
    end_of_run_delay: entity work.pulse_delay
    port map (
        clock     => ttc_clk_x5_0,
        delay     => x"3B9ACA00",
        pulse_in  => end_of_run,
        pulse_out => end_of_run_delayed
    );
    eor_stretch_inst: entity work.signal_stretch
    port map (
        clk      => ttc_clk_x5_0,
        n_cycles => x"0F",
        sig_i    => end_of_run_delayed,
        sig_o    => end_of_run_stretch
    );
    run_latch_enable <= begin_of_run_stretch or end_of_run_stretch;
    generate_laser_inhibit: FDCE  -- Initial value of register ('0' or '1')
    generic map ( INIT => '0')
    port map (
        Q   => run_status_latch, -- Data output
        C   => ttc_clk_x5_0,     -- Clock input
        CE  => run_latch_enable, -- Clock enable input
        CLR => hard_rst_ttc,     -- Asynchronous clear input
        D   => run_enable        -- Data input
    );
    send_laser_triggers <= always_send_laser_trig or run_status_latch;


--    -- ------------------------
--    -- internal trigger testing
--    -- ------------------------
--
    generate_internal_trigger: entity work.internal_trigger
    port map (
        clk                    => ttc_clk,
        enable                 => internal_trigger_enabled,  
        two_cycles             => trig_cycle_toggle_8_16,
        supercycle_period      => supercycle_period,   -- rep rate for the dual cycles of 8 fills
        cycle8_period          => eight_cycle_period,  -- period between pulses in a period
        cycle8_delay           => eight_cycle_delay,   -- delay from T93 (or T94) to the first A6 signal of a cycle
        scnd_cycle8_gap        => second_cycle_gap,    -- time in gap from last (eighth) A6 of first cycle to the T94 that launches the second cycle
        t9_signal              => internal_t9,
        a_six_signal           => internal_a6,
        supercycle_in_progress => internal_cycle_active,
        cycle8_active          => cycle8_active,
        internal_trigger_boc   => internal_trigger_boc
    );  

    -- -------------
    -- trigger logic
    -- -------------

    -- external trigger inputs
    TRIG0_IBUFGDS: IBUFDS port map (I => tr0_lemo_p, IB => tr0_lemo_n, O => tr0_lemo);
    TRIG1_IBUFGDS: IBUFDS port map (I => tr1_lemo_p, IB => tr1_lemo_n, O => tr1_lemo);

    -- auxilliary lemo inputs
    AUXA_IBUF: IBUF port map (I => aux_lemo_a, O => aux_lemo_a_internal);
    AUXB_IBUF: IBUF port map (I => aux_lemo_b, O => aux_lemo_b_internal);

    -- use length of pulse to distinguish between begin of supercycle or throttling start / stop
    check_boc_length: entity work.boc_length_counter
    port map (
        clock           =>  ttc_clk,
        reset           =>  rst_ttc,
        pulse_in        =>  aux_lemo_b_internal,
        base_boc_length =>  boc_pulse_length,
        boc_out         =>  accel_boc,
        throttle        =>  throttle_asynch
    );
    
    -- stretch aux_lemo_b_internal (begin of supercycle signal) for easier viewing on scope
    stretch_auxb: entity work.signal_stretch
    port map (
         clk      => ttc_clk,
         n_cycles => x"80",
         sig_i    => aux_lemo_b_internal,
         sig_o    => stretch_lemo_b
    );

    -- select trigger input source
    tr0_lemo_inv <= not tr0_lemo;
    tr1_lemo_inv <= not tr1_lemo;
    trx_lemo_inv <= tr0_lemo_inv when trx_lemo_sel = '0' else tr1_lemo_inv;

    -- select boc from internal trigger or from encoder FC7 (aux lemo b)
    use_internal_trigger_boc <= force_internal_trigger_boc or (internal_trigger_enabled and not run_enable);
    begin_of_supercycle <= accel_boc when use_internal_trigger_boc = '0' else internal_trigger_boc;

    -- trigger level-to-pulse conversions
    -- a6: take the lemo input from accelerator when external trigger is valid, else take the internally generated A6 when
    -- we have fallen back to the internal trigger, or have forced its use.
    a6_source <= aux_lemo_a_internal when internal_trigger_enabled = '0' else internal_a6;
    trx_conv0:      entity work.level_to_pulse port map (clk => ttc_clk_x12p5,  sig_i => a6_source, sig_o => acc_trigger_0      );
    trx_conv0_200M: entity work.level_to_pulse port map (clk => ttc_clk_x5_0,   sig_i => a6_source, sig_o => acc_trigger_0_200M      );
    -- begin of supercycle
    boc_conv0_200M: entity work.level_to_pulse port map (clk => ttc_clk_x5_0,   sig_i => begin_of_supercycle, sig_o => acc_cycle_start_0_200M  );

    acc_trig_fanout_0_200M   <= (others => acc_trigger_0_200M  );

	-- t9
    t9_to_pulse: entity work.level_to_pulse port map (clk   => ttc_clk, sig_i => abank_in(0),      sig_o    => t9_pulse );
    t9_accel <= t9_pulse when internal_trigger_enabled = '0' else internal_t9;
    apply_t9_correction <= enable_T9_adjust and t9_correction_valid and not internal_trigger_enabled;
    delay_t9:    entity work.pulse_delay    port map (clock => ttc_clk, delay => t9_gap_correction, pulse_in => t9_pulse, pulse_out => t9_delayed_pulse );
    t9_use   <= t9_delayed_pulse when apply_t9_correction = '1' else t9_accel;
    stretch_t9: entity work.signal_stretch
    port map (
      clk      => ttc_clk,
      n_cycles => x"04",
      sig_i    => internal_t9,
      sig_o    => internal_t9_stretch
    );
    stretch_t9_use: entity work.signal_stretch
    port map (
      clk      => ttc_clk,
      n_cycles => x"14",
      sig_i    => t9_use,
      sig_o    => t9_use_stretch
    );

    -- sequence counters and checking
    -- utilize fact that we have time to make the last cycle comparison, rather than carrying this through to the
    -- counter at high rate.  Take advantage of fact that we have plenty of time between triggers
    seq_limit_check: entity work.sequence_limit_check
    port map (
        clk               => ttc_clk_x5_0,
        reset             => sequence_reset,
        boc               => acc_cycle_start_0_200M,
        seq_index         => seq_index_200M,
        max_seq_index     => trigger_per_cycle_limit,
        assert_penu_delay => assrt_penu_delay,
        assert_cyc2_delay => assrt_cyc2_delay,
        penultimate_seq   => penultimate_seq,
        second_cycle      => second_cycle_seen,
        sequence_error    => counter_err(0)
    );  

    -- we shouldn't see  second_cycle go high if we aren't using the second cycle
    counter_err(1) <= second_cycle_seen and not trig_cycle_toggle_8_16;

    -- switch to 2nd cycle parameters
    use_second_cycle(0) <= second_cycle_seen and trig_cycle_toggle_8_16;

    -- monitor whether A6 triggers are arriving
    watch_a6: entity work.monitor_a6_noidle
    port map (
    	clk                  => ttc_clk,
    	reset                => rst_ttc,
    	a6                   => aux_lemo_a_internal,
    	a6_missing_threshold => a6_missing_threshold,
      supercycle_active    => internal_cycle_active,
    	a6_missing           => accel_a6_missing
    );

    -- monitor the current average correcton for the gap between t9 and a6
    t9_gap: entity work.t9_to_a6_monitor 
    port map (
    -- ttc clock
    	clk                => ttc_clk,
    	reset              => reset_gapcorr,
    	t9                 => t9_pulse,               -- t9_accel,  -- always use the external accel signals, not the internally generated
    	a6                 => aux_lemo_a_internal,    -- a6_source, -- ditto
      ideal_t9_to_a6_gap => eight_cycle_delay,
      max_t9_to_a6_gap   => max_eight_cycle_delay,
      t9_correction      => t9_gap_correction,
      correction_valid   => t9_correction_valid
	);

	-- ----------------------------------
    -- generate the kicker charging signals
    kicker_t9s: for it9 in 0 to 3 generate
	 begin
		kicker_t9_inst: entity work.kicker_t9_triggers
		port map (
		   clk                  => ttc_clk,
		   reset                => rst_ttc,
    		t9                   => t9_use,
    		a6                   => a6_source,
    		enabled              => t9_kickerSignals_enabled(it9),
    		number_triggers      => 8,
    		t9_to_trigger_delays => kicker_t9_pulse_delays(it9),
    		t9_trigger_width     => t9_kickerSignals_width,
    		iSecondCycle         => active_cycle,
         trigger_armed        => t9_trigger_armed(it9),
    		trigger_out          => t9_triggers_uninhibited(it9),
         a6_trigger_missing   => an_a6_missed(it9),
         debug_trigger_out    => debug_kicker_triggers(it9),
         safety_clear         => safety_trigger(0)
      );
      kicker_inhib_inst: entity work.inhibit_trigger
      port map (
         clk                  => ttc_clk,
         reset                => rst_ttc,
         charging_trigger     => t9_triggers_uninhibited(it9),
         inhibit_time         => charging_deadtime,
         trigger_with_inhibit => t9_kicker_triggers(it9)
      );
	end generate;

    -- latch the time between charging the kicker capacitor banks and firing the kicker
    kicker_1_tsq: entity work.kicker_time_since_charge
    port map (
        clk               => ttc_clk,
        reset             => rst_ttc,
        charge_cap        => t9_kicker_triggers(0),
        fire_kicker       => trigger_out(0),
        time_since_charge => kicker_tsq(0)
    );
    kicker_2_tsq: entity work.kicker_time_since_charge
    port map (
        clk               => ttc_clk,
        reset             => rst_ttc,
        charge_cap        => t9_kicker_triggers(0),
        fire_kicker       => trigger_out(1),
        time_since_charge => kicker_tsq(1)
    );
    kicker_3_tsq: entity work.kicker_time_since_charge
    port map (
        clk               => ttc_clk,
        reset             => rst_ttc,
        charge_cap        => t9_kicker_triggers(0),
        fire_kicker       => trigger_out(2),
        time_since_charge => kicker_tsq(2)
    );

    -- ----------------------------------
    -- generate a quad trigger for a "once per t9" quad pulse
    -- first delay it by the requested amount
    quad_t9_delay: entity work.pulse_delay
    port map (
       clock                => ttc_clk,
       delay                => quad_t9_pulse_delay,
       pulse_in             => t9_use,
       pulse_out            => delayed_t9_quad
    );
    -- now stretch it
    quad_t9_stretch: entity work.signal_stretch
    generic map (nbr_bits => 24)
    port map (
       clk                  => ttc_clk,
       n_cycles             => quad_t9_pulse_width,
       sig_i                => delayed_t9_quad,
       sig_o                => stretched_t9_quad
    );
    -- enable/suppress quad triggers as requested
    t9_trigger_quad <= stretched_t9_quad and t9_quadSignal_enabled;
    a6_trigger_quad <= trigger_out(3) and a6_quadSignal_enabled;
    -- combined_trigger_quad <= t9_trigger_quad or a6_trigger_quad;
    -- -------------------------------------------
    -- monitor for switching between internal and external triggers
    trigger_traffic_cop: entity work.trigger_traffic_controller
    port map (
		clk                  => ttc_clk,
		reset                => rst_ttc,
      fallback_enabled     => internal_trigger_fallbck,
		force_internal       => internal_trigger_force_ttc,
		a6_missing           => accel_a6_missing,
		transition_trigger   => trigger_transitioning,
		use_internal_trigger => internal_trigger_enabled
    );


    -- -------------------------------------------
    counter_val_sync_inst: entity work.sync_2stage
    generic map (nbr_bits => 4)
    port map (
        clk   => ttc_clk,
        sig_i => seq_index_200M,
        sig_o => counter_val_sync(3 downto 0)
    );

    -- ----------------------------------
    seq_counter_200M: entity work.counter_sm
    generic map (n => 4)
    port map (
        clk               => ttc_clk_x5_0,
        reset             => sequence_reset,
        trigger_in        => acc_trigger_0_200M,
        cycle_start       => acc_cycle_start_0_200M,
        penultimate_seq   => penultimate_seq,
        seq_index         => seq_index_200M
    );

    -- 80 ns pulse of repeated $A6
    issue_a6: entity work.fast_variable_pulse
    generic map ( strtbit => 17 )
    port map (
        clk      => ttc_clk_x12p5,
        trigger  => acc_trigger_0,
        length   => "0110",
        pulse    => a6_for_encoder
    );


    -- the encoder will either see the a6 (internal or accel as source), or the flag that the trigger is transitioning
    trigger_encoder <= a6_for_encoder or trigger_transitioning or encoder_abort;
    --- trigger_out(12) <= a6_for_encoder or trigger_transitioning or encoder_abort;

    -- 500 MHz infrastructure
    a6_channels: entity work.a6_500_channels
    port map (
    	ttc_clk         => ttc_clk,
      reset           => sequence_reset,
    	clock_locks     => a6_clock_locks,
    	a6              => a6_source,
    	begin_of_cycle  => begin_of_supercycle,
    	penultimate_seq => penultimate_seq,
    	pulse_delays    => pulse_delay_parms_shifted_fast,
    	pulse_widths    => pulse_width_parms_shifted_fast,
    	enabled         => pulse_enabled_fast,
    	trigger_out     => trigger_out( 6 downto 0)
    );
    clocks_500_lock <= a6_clock_locks(0) and a6_clock_locks(1) and a6_clock_locks(2);

    -- 200 MHz channels
    channel_array_200M: for i in 7 to 13 generate
    begin
        -- --------------------------------------
        channel_inst: entity work.trigger_channel_singlePhase
        port map (
            clk_0                  => ttc_clk_x5_0,
            seq_index_0            => seq_index_200M(2 downto 0),
            trigger_0              => acc_trig_fanout_0_200M(i),
            pulse_delay_parameters => pulse_delay_parms_shifted_slow(i),
            pulse_width_parameters => pulse_width_parms_shifted_slow(i),
            pulse_enabled          => pulse_enabled_slow(i),
            trigger_out            => trigger_out(i)
        );
    end generate;
  
    -- -----------------------------------------
    -- kicker safety
    -- -----------------------------------------
    -- first, generate the safety pulse
    kicker_saftey_channel: for i in 0 to 2 generate
    begin
        safety_dischg_int: entity work.kicker_safety_trig
        port map (
            clk                  => ttc_clk,
            reset                => rst_ttc,
            charging_trigger     => t9_kicker_triggers(i+1),
            discharge_trigger    => trigger_out(i),
            safety_dischrge_time => safety_discharge_timing,
            safety_trigger       => safety_trigger(i)
        );
    end generate;
    -- next, apply the the discharge inhibit for specified deadtime to the output of the or'd regular and safety triggers
    kicker_discharge_inhibit: for k in 0 to 2 generate
        k_combined_no_inhibit(k) <= safety_trigger(k) or trigger_out(k);
-- debug        k_create_inibit: entity work.generate_inhibit
-- debug        port map (
-- debug           clk           => ttc_clk_x5_0,
-- debug           reset         => rst_ttc,
-- debug           trigger_in    => k_combined_no_inhibit(k),
-- debug           inhibit_time  => discharge_deadtime,
-- debug           inhibit_out   => discharge_inhibit(k)
-- debug        );
-- debug        k_combined_discharge(k) <= k_combined_no_inhibit(k) and not discharge_inhibit(k);
        k_combined_discharge(k) <= k_combined_no_inhibit(k);
    end generate;

    -- prescaler to flag when sequence "9" should get mapped to header output instead of sequence "8".  For the laser system
    trx_conv_40MHz: entity work.level_to_pulse port map (clk => ttc_clk,   sig_i => begin_of_supercycle, sig_o => acc_cycle_start_40MHz);
    prescale_cycle: entity work.prescale_pulse 
    generic map ( n => 8 )
    port map (
        clk             => ttc_clk,   
        prescale_factor => laser_prescale_factor,
        active          => run_enable,
        pulse_in        => acc_cycle_start_40MHz, 
        prescale_seen   => prescaled_cycle
    );
    -- for laser system, send sequence 8 out when prescaled condition met, otherwise 9
    use_infill <= prescaled_cycle or (infill_laser_on_internal_ttc and internal_trigger_enabled);
    laser_channel_p1  <= "100" & use_infill;
    laser_channel_out <= laser_channel_p1 - 1;
    laser_trigger_select <= trigger_out(to_integer(unsigned(laser_channel_out)));
    laser_trigger_signal <= laser_trigger_select and send_laser_triggers;

    -- for asynch trigger, do not send triggers when ttc triggering is throttled, and only when run is enabled
    kicker_asynch <= (trigger_out(9) and run_enable) when throttle_asynch = '0' else '0';

    -- set a status bit when we are in the gap in the supercycle
    latch_enable <= begin_of_supercycle or t9_use;
    gap_latch_inst: work.fdse
    port map (
        Q  => gap_detected,
        C  => ttc_clk,
        CE => latch_enable,
        S  => rst_ttc,
        D  => begin_of_supercycle
    );

    -- -----------------
    -- FMC header output
    -- -----------------

    -- --------------- new patch panel output---------------
    -- outputs from 500 MHz domain signals
    bbank_out(7) <= k_combined_discharge(0); -- K1 discharge
    bbank_out(6) <= k_combined_discharge(1); -- K2 discharge
    bbank_out(5) <= k_combined_discharge(2); -- K3 discharge
    bbank_out(4) <= trigger_out( 3); -- Quad
    bbank_out(3) <= trigger_out( 4); -- reserved (used temp for kicker)
    bbank_out(2) <= trigger_out( 5); -- reserved
    bbank_out(1) <= trigger_out( 6); -- reserved

    -- A6 trigger for encoder
    bbank_out(0) <= trigger_encoder;

    -- outputs from 200 MHz domain signals
    cbank_out(7) <= laser_trigger_signal;
    cbank_out(6) <= kicker_asynch;
    cbank_out(5) <= trigger_out( 9); -- spark detection -- same table as kicker_asynch, but always active independent of run state
    cbank_out(4) <= trigger_out(10); -- IBMS 1,2
    dbank_out(0) <= trigger_out(11); -- IBMS 3
    dbank_out(1) <= trigger_out(12); -- reserved for another 200 MHz signal
    dbank_out(2) <= trigger_out(13); -- reserved for another 200 MHz signal

    -- outputs from 40 MHz domain signals
    cbank_out(3) <= t9_kicker_triggers(0);
    cbank_out(2) <= t9_kicker_triggers(1);
    cbank_out(1) <= t9_kicker_triggers(2);
    cbank_out(0) <= t9_kicker_triggers(3);

    -- send out analog copies of the TTC trigger
    abank_out(7) <= ttc_trigger_out;
    abank_out(6) <= ttc_trigger_out;
    abank_out(5) <= ttc_trigger_out;
    abank_out(4) <= ttc_trigger_out;

    -- outputs for the T9-based quad triggering
    dbank_out(3) <= t9_trigger_quad; -- begin of supercycle from encoder

    -- outputs for debugging
    dbank_out(4) <= debuglines(debugline1);
    dbank_out(5) <= debuglines(debugline2);
    dbank_out(6) <= debuglines(debugline3);
    dbank_out(7) <= debuglines(debugline4);

    debuglines <= ( 0 => aux_lemo_a_internal, -- a6 from accelerator
                    1 => abank_in(0),         -- T93/T94 from accel
                    2 => t9_use,              -- internal or beam signal used for t9 triggering
                    3 => a6_source,           -- internal or beam signal used for a6 triggering
                    4 => stretch_lemo_b,      -- begin of supercycle from encoder, stretched for scoping
                    5 => throttle_asynch,
                    6 => trigger_from_ttc,
                    7 => accel_a6_missing,
                    8 => accel_boc,
                    9 => t9_trigger_armed(0), -- flag that system is ready to accept a new t9 signal.
                   10 => t9_trigger_armed(1), -- flag that system is ready to accept a new t9 signal.
                   11 => t9_trigger_armed(2), -- flag that system is ready to accept a new t9 signal.
                   12 => t9_trigger_armed(3), -- flag that system is ready to accept a new t9 signal.
                   13 => t9_triggers_uninhibited(0),
                   14 => t9_triggers_uninhibited(1),
                   15 => t9_triggers_uninhibited(2),
                   16 => t9_triggers_uninhibited(3),
                   17 => debug_kicker_triggers(0),
                   18 => debug_kicker_triggers(1),
                   19 => debug_kicker_triggers(2),
                   20 => debug_kicker_triggers(3),
                   others => '0');



    -- -------------
    -- FMC I2C logic
    -- -------------
--    NOTE: Cornell FMC card does not have an active eeprom on it.  Restore the i2c_top_wrapper interface should
--          another FMC card with the eeprom get introduced.  In the meantime, provide "all is well" signals for
--          the L12 parameters
      l12_fs_state  <= (23 => '1', others => '0');
      l12_ssc_state <= ( 0 => '1', others => '0');
      l12_st_state  <= (others => '0');
      l12_sgr_state <= (others => '0');
      error_l12_fmc_absent <= '0';
--    -- ---------------------------------------------
--    i2c_l12_top_wrapper: entity work.i2c_top_wrapper
--    port map (
--        -- clock and reset
--        clk   => osc125_b_bufg,
--        reset => hard_rst_osc125,
--
--        -- control signals
--        fmc_loc               => "00",           -- L12 LOC
--        fmc_mod_type          => "00000010",     -- HTG-FMC-SMA-LVDS FMC
--        fmc_absent            => fmc_l12_absent, -- FMC absent signal
--        sfp_requested_ports_i => "00000000",     -- not used
--        i2c_en_start          => '0',            -- not used
--        i2c_rd_start          => '0',            -- not used
--
--        -- generic read interface
--        channel_sel_in       => "00000000",
--        eeprom_map_sel_in    => '0',
--        eeprom_start_adr_in  => "00000000",
--        eeprom_num_regs_in   => "000000",
--        eeprom_reg_out       => open,
--        eeprom_reg_out_valid => open,
--
--        -- status signals
--        sfp_enabled_ports => open,
--        sfp_sn            => open,
--        sfp_mod_abs       => open,
--        sfp_tx_fault      => open,
--        sfp_rx_los        => open,
--
--        change_mod_abs  => open,
--        change_tx_fault => open,
--        change_rx_los   => open,
--
--        fs_state  => l12_fs_state,
--        st_state  => l12_st_state,
--        ssc_state => l12_ssc_state,
--        sgr_state => l12_sgr_state,
--
--        -- warning signals
--        change_error_mod_abs  => open,
--        change_error_tx_fault => open,
--        change_error_rx_los   => open,
--
--        -- error signals
--        error_fmc_absent   => error_l12_fmc_absent,
--        error_fmc_mod_type => open,
--        error_fmc_int_n    => open,
--        error_startup_i2c  => open,
--
--        sfp_en_error_mod_abs    => open,
--        sfp_en_error_sfp_type   => open,
--        sfp_en_error_tx_fault   => open,
--        sfp_en_error_sfp_alarms => open,
--        sfp_en_error_i2c_chip   => open,
--
--        -- SFP alarm flags
--        sfp_alarm_temp_high     => open,
--        sfp_alarm_temp_low      => open,
--        sfp_alarm_vcc_high      => open,
--        sfp_alarm_vcc_low       => open,
--        sfp_alarm_tx_bias_high  => open,
--        sfp_alarm_tx_bias_low   => open,
--        sfp_alarm_tx_power_high => open,
--        sfp_alarm_tx_power_low  => open,
--        sfp_alarm_rx_power_high => open,
--        sfp_alarm_rx_power_low  => open,
--          
--        -- SFP warning flags
--        sfp_warning_temp_high     => open,
--        sfp_warning_temp_low      => open,
--        sfp_warning_vcc_high      => open,
--        sfp_warning_vcc_low       => open,
--        sfp_warning_tx_bias_high  => open,
--        sfp_warning_tx_bias_low   => open,
--        sfp_warning_tx_power_high => open,
--        sfp_warning_tx_power_low  => open,
--        sfp_warning_rx_power_high => open,
--        sfp_warning_rx_power_low  => open,
--
--        -- I2C signals
--        i2c_int_n_i  => '1',  -- active-low I2C interrupt signal (not used)
--        scl_pad_i    => '0',  -- input from external pin (not used)
--        scl_pad_o    => open, -- output to tri-state driver (not used)
--        scl_padoen_o => open, -- enable signal for tri-state driver (not used)
--        sda_pad_i    => '0',  -- input from external pin (not used)
--        sda_pad_o    => open, -- output to tri-state driver (not used)
--        sda_padoen_o => open  -- enable signal for tri-state driver (not used)
--    );

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
    -- except for L12 and L8 SSC state machines, which are held in reset
    fmcs_ready <= l8_fs_state(23) and l12_fs_state(23) and l8_ssc_state(0) and l12_ssc_state(0);

    -- -------------------------------------------
    fmc_eeprom_usr: entity work.fmc_eeprom_wrapper
    port map (
        -- clock and reset
        clk => osc125_b_bufg,
        rst => hard_rst_osc125,

        -- status
        l12_dev_active => '0',
        l08_dev_active => '1',
        l12_dev_ext => '1', -- STMicroelectronics M24128-BWDW6TP EEPROM
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


    -- ------------------
    -- TTS reporter logic
    -- ------------------

    -- combine local state conditions;
    -- they must be independent of TTS RX signals
    local_error     <= '1' when fmc_ids_valid        = '0' or over_temp             = '1' or
                                ttc_ready            = '0' or ttc_clk_lock          = '0' or
                                error_l12_fmc_absent = '1' or error_ttc_sbit_limit  = '1' or error_ttc_mbit_limit = '1' or
                                error_l8_fmc_absent  = '1' or error_l8_fmc_mod_type = '1' or error_l8_fmc_int_n   = '1' or
                                xadc_alarms         /= x"0" else '0';
    local_sync_lost <= '1' when counter_err /= x"0000" else '0';
    local_overflow  <= trig_info_fifo_full or pulse_info_fifo_full;

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
        end if;
    end process;

    abort_run <= '1' when local_tts_state /= "1000" else '0';


    -- -----------------
    -- TTC decoder logic
    -- -----------------

    -- ---------------------------------
    ttc_decoder: entity work.TTC_decoder_ddelay
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
        Brcst       => ttc_chan_b_info,  -- channel b data
        TTC_CLK_ddelay => ttc_clk_x5_0,   -- clock for IDELAYE2 for data
        delay_count    => ttc_data_delay, -- amount that ttc data is delayed
        delay_rdy      => ttc_ddelay_rdy -- delay unit ready for data delay
    );

    trigger_from_ttc <= ttc_raw_trigger and ttc_ready;

    ttc_width: entity work.ttc_analog_width
    port map (
        clk       => ttc_clk,
        reset     => rst_ttc,
        ttc_valid => ttc_chan_b_valid,
        ttc_trggr => trigger_from_ttc,
        ttc_cmd   => ttc_chan_b_info,
        width_in  => ttc_trig_out_width_sync,
        width_out => ttc_trig_out_width_use
    );
    -- -------------------------------------------
    trigger_from_ttc_sync: entity work.sync_2stage
    port map (
        clk      => osc125_b_bufg,
        sig_i(0) => trigger_from_ttc,
        sig_o(0) => trig_clk125_sync
    );

    -- trigger to event builder
    trig_clk125_conv: entity work.level_to_pulse
    port map (
        clk   => osc125_b_bufg,
        sig_i => trig_clk125_sync,
        sig_o => trig_clk125
    );

    -- delay TTC trigger signal
    ttc_trig_delay_inst: entity work.pulse_delay
    port map (
        clock     => ttc_clk,
        delay     => ttc_trig_out_delay_sync,
        pulse_in  => trigger_from_ttc,
        pulse_out => trigger_from_ttc_delayed
    );

    -- stretch TTC trigger signal
    ttc_trig_stretch_inst: entity work.signal_stretch
    generic map ( nbr_bits => 10 )
    port map (
        clk      => ttc_clk,
        n_cycles => ttc_trig_out_width_use,
        sig_i    => trigger_from_ttc_delayed,
        sig_o    => ttc_trigger_out
    );

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


    -- ---------------------------
    -- trigger information storage
    -- ---------------------------

    s_x_info_fifo_tready <= s_trig_info_fifo_tready and s_pulse_info_fifo_tready and not (wr_rst_busy_trig or wr_rst_busy_pulse);

    trigger_info_storer_usr: entity work.trigger_info_storer_wrapper
    port map (
        -- clock and reset
        clk => ttc_clk,
        rst => rst_ttc,

        -- TTC information
        trigger           => trigger_from_ttc,
        broadcast         => ttc_chan_b_info(7 downto 2),
        broadcast_valid   => ttc_chan_b_valid,
        event_count_reset => ttc_evt_reset,

        -- FIFO interface
        fifo_ready => s_x_info_fifo_tready,
        fifo_data  => s_trig_info_fifo_tdata,
        fifo_valid => s_x_info_fifo_tvalid,

        -- trigger information
        trig_timestamp => trig_timestamp,
        trig_num       => trig_num,
        trig_type_num  => trig_type_num,
        trig_type      => trig_type,

        -- status
        state => tis_state
    );

    -- Trigger Information FIFO : 2048 depth, 2047 almost full threshold, 16-byte data width
    -- holds the trigger timestamp, trigger number, and trigger type
    trig_info_fifo: entity work.trig_info_fifo
    port map (
        wr_rst_busy    => wr_rst_busy_trig,
        rd_rst_busy    => rd_rst_busy_trig,
        m_aclk         => osc125_b_bufg,
        s_aclk         => ttc_clk,
        s_aresetn      => rst_ttc_n,
        s_axis_tvalid  => s_x_info_fifo_tvalid,
        s_axis_tready  => s_trig_info_fifo_tready,
        s_axis_tdata   => s_trig_info_fifo_tdata,
        m_axis_tvalid  => m_trig_info_fifo_tvalid,
        m_axis_tready  => m_trig_info_fifo_tready,
        m_axis_tdata   => m_trig_info_fifo_tdata,
        axis_prog_full => trig_info_fifo_full
    );

    -- Pulse Information FIFO : 2048 depth, 2047 almost full threshold, 512-byte data width
    -- holds the pulse widths and delays for each channel for the active sequence
    pulse_info_fifo: entity work.pulse_info_fifo
    port map (
        wr_rst_busy    => wr_rst_busy_pulse,
        rd_rst_busy    => rd_rst_busy_pulse,
        m_aclk         => osc125_b_bufg,
        s_aclk         => ttc_clk,
        s_aresetn      => rst_ttc_n,
        s_axis_tvalid  => s_x_info_fifo_tvalid,
        s_axis_tready  => s_pulse_info_fifo_tready,
        s_axis_tdata   => s_pulse_info_fifo_tdata,
        m_axis_tvalid  => m_pulse_info_fifo_tvalid,
        m_axis_tready  => m_pulse_info_fifo_tready,
        m_axis_tdata   => m_pulse_info_fifo_tdata,
        axis_prog_full => pulse_info_fifo_full
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

        m_pulse_info_fifo_tvalid => m_pulse_info_fifo_tvalid,
        m_pulse_info_fifo_tready => m_pulse_info_fifo_tready,
        m_pulse_info_fifo_tdata  => m_pulse_info_fifo_tdata,

        -- controls
        ttc_trigger => trig_clk125,

        -- static event information
        fc7_type           => "11",
        major_rev          => usr_ver_major,
        minor_rev          => usr_ver_minor,
        patch_rev          => usr_ver_patch,
        board_id           => board_id,
        l12_fmc_id         => l12_fmc_id,
        l8_fmc_id          => l8_fmc_id,
        otrig_disable_a    => '0',
        otrig_disable_b    => '0',
        otrig_delay_a      => x"00000000",
        otrig_delay_b      => x"00000000",
        otrig_width_a      => x"00",
        otrig_width_b      => x"00",
        tts_lock_thres     => x"00000000",
        ofw_watchdog_thres => x"000000",
        l12_enabled_ports  => x"00",
        l8_enabled_ports   => x"00",
        l12_tts_mask       => x"00",
        l8_tts_mask        => x"00",
        l12_ttc_delays     => (others => (others => '0')),
        l8_ttc_delays      => (others => (others => '0')),
        l12_sfp_sn         => (others => (others => '0')),
        l8_sfp_sn          => (others => (others => '0')),

        -- variable event information
        l12_tts_state             => x"00000000",
        l8_tts_state              => x"00000000",
        l12_tts_lock              => x"00",
        l8_tts_lock               => x"00",
        l12_tts_lock_mux          => '0',
        l8_tts_lock_mux           => '0',
        ext_clk_lock              => '0',
        ttc_clk_lock              => ttc_clk_lock,
        ttc_ready                 => ttc_ready,
        xadc_alarms               => xadc_alarms,
        error_flag                => abort_run,
        error_l12_fmc_absent      => error_l12_fmc_absent,
        error_l8_fmc_absent       => error_l8_fmc_absent,
        change_error_l12_mod_abs  => x"00",
        change_error_l8_mod_abs   => x"00",
        change_error_l12_tx_fault => x"00",
        change_error_l8_tx_fault  => x"00",
        change_error_l12_rx_los   => x"00",
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
