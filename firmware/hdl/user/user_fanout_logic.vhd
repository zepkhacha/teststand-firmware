-- Top-level module for the Fanout FC7 user logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.ipbus.all;
use work.system_package.all;
use work.user_package.all;
use work.user_version_package.all;

library unisim;
use unisim.vcomponents.all;

entity user_fanout_logic is 
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

    -- FMC status
    fmc_l12_absent : in std_logic;
    fmc_l8_absent  : in std_logic;

    -- FMC SFP
    sfp_l12_rx_p : in  std_logic_vector(7 downto 0);
    sfp_l12_rx_n : in  std_logic_vector(7 downto 0);
    sfp_l12_tx_p : out std_logic_vector(7 downto 0);
    sfp_l12_tx_n : out std_logic_vector(7 downto 0);

    sfp_l8_rx_p : in  std_logic_vector(7 downto 0);
    sfp_l8_rx_n : in  std_logic_vector(7 downto 0);
    sfp_l8_tx_p : out std_logic_vector(7 downto 0);
    sfp_l8_tx_n : out std_logic_vector(7 downto 0);

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
    i2c_l8_int : in    std_logic;

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
    ipb_mosi_i : in  ipb_wbus_array(0 to nbr_usr_fan_slaves-1);
    ipb_miso_o : out ipb_rbus_array(0 to nbr_usr_fan_slaves-1);

    -- other
    reprog_fpga : out std_logic;
    user_reset  : out std_logic;
    board_id    : in  std_logic_vector(10 downto 0)
);
end user_fanout_logic;

architecture usr of user_fanout_logic is

    -- clocks
    signal ttc_clk     : std_logic;
    signal ttc_clk_x2  : std_logic;
    signal ttc_clk_x4  : std_logic;
    signal ttc_clk_x5  : std_logic;
    signal ttc_clk_x10 : std_logic;

    -- clock wizard locks
    signal ttc_clk_lock : std_logic;

    -- resets
    signal rst_ttc_n           : std_logic;
    signal rst_ttc_x4          : std_logic;
    signal rst_from_ipbus      : std_logic;
    signal soft_rst_from_ipbus : std_logic;
    signal rst_ipb             : std_logic;
    signal rst_ipb_stretch     : std_logic;
    signal init_rst_ipb        : std_logic;
    signal sys_rst_ipb         : std_logic;

    signal rst_osc125, hard_rst_osc125, soft_rst_osc125, auto_soft_rst_osc125 : std_logic;
    signal rst_ttc,    hard_rst_ttc,    soft_rst_ttc,    auto_soft_rst_ttc    : std_logic;

    signal auto_soft_rst         : std_logic;
    signal auto_soft_rst_sync1   : std_logic;
    signal auto_soft_rst_sync2   : std_logic;
    signal auto_soft_rst_sync3   : std_logic;
    signal auto_soft_rst_stretch : std_logic;
    signal auto_soft_rst_delay   : std_logic;

    signal i2c_l12_rst_from_ipb     : std_logic;
    signal i2c_l8_rst_from_ipb      : std_logic;
    signal tts_rx_rst_l12_from_ipb  : std_logic;
    signal tts_rx_rst_l8_from_ipb   : std_logic;
    signal ttc_decoder_rst_from_ipb : std_logic;
    signal ttc_decoder_rst          : std_logic;

    -- triggers
    signal trigger_from_ttc : std_logic;
    signal ttc_raw_trigger  : std_logic;
    signal trig_clk125      : std_logic;
    signal trig_clk125_sync : std_logic;

    -- IPbus slave registers
    signal stat_reg : stat_reg_t;
    signal ctrl_reg : ctrl_reg_t;

    -- delays
    signal trigger_delay_a, trigger_delay_a_ext : std_logic_vector(31 downto 0);
    signal trigger_delay_b, trigger_delay_b_ext : std_logic_vector(31 downto 0);

    signal l12_ttc_encoded_delay, l12_ttc_encoded_delay_ttc : array_8x8bit;
    signal l8_ttc_encoded_delay,  l8_ttc_encoded_delay_ttc  : array_8x8bit;

    -- TTC encoding
    signal ttc_data    : std_logic_vector(15 downto 0);
    signal ttc_encoded : std_logic;

    signal sfp_l8_tx,       sfp_l12_tx       : std_logic_vector(7 downto 0);
    signal sfp_l8_tx_delay, sfp_l12_tx_delay : std_logic_vector(7 downto 0);

    -- TTC decoder
    signal ttc_bcnt_reset, ttc_bcnt_reset1, ttc_bcnt_reset2, ttc_bcnt_reset3, ttc_bcnt_reset_sync : std_logic;
    signal ttc_evt_reset,  ttc_evt_reset1,  ttc_evt_reset2,  ttc_evt_reset3,  ttc_evt_reset_sync  : std_logic;

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

    -- run information
    signal run_enable : std_logic;

    -- trigger information
    signal trig_num        : std_logic_vector(23 downto 0);
    signal trig_type_num   : array_32x24bit;
    signal trig_timestamp  : std_logic_vector(43 downto 0);
    signal trig_type       : std_logic_vector( 4 downto 0);
    signal trig_info_valid : std_logic;

    signal a_channel      : std_logic;
    signal a_channel1     : std_logic;
    signal a_channel2     : std_logic;
    signal a_channel3     : std_logic;
    signal a_channel_sync : std_logic;

    signal b_channel  : std_logic_vector(7 downto 0);
    signal b_channel1 : std_logic_vector(7 downto 0);
    signal b_channel2 : std_logic_vector(7 downto 0);

    signal b_channel_valid      : std_logic;
    signal b_channel_valid1     : std_logic;
    signal b_channel_valid2     : std_logic;
    signal b_channel_valid3     : std_logic;
    signal b_channel_valid_sync : std_logic;

    signal ttc_chan_b_mux       : std_logic_vector(7 downto 0);
    signal ttc_chan_b_valid_mux : std_logic;

    -- Trigger Information FIFO
    signal s_trig_info_fifo_tdata,  m_trig_info_fifo_tdata  : std_logic_vector(127 downto 0);
    signal s_trig_info_fifo_tvalid, m_trig_info_fifo_tvalid : std_logic;
    signal s_trig_info_fifo_tready, m_trig_info_fifo_tready : std_logic;
    signal wr_rst_busy_trig                                 : std_logic;
    signal rd_rst_busy_trig                                 : std_logic;
    
    signal trig_info_sm_state  : std_logic;
    signal trig_info_fifo_full : std_logic;

    -- FMC SFP configuration
    signal i2c_l8_en_start, i2c_l12_en_start : std_logic;
    signal i2c_l8_rd_start, i2c_l12_rd_start : std_logic;

    signal sfp_l8_requested_ports,   sfp_l12_requested_ports   : std_logic_vector(7 downto 0);
    signal sfp_l8_enabled_ports,     sfp_l12_enabled_ports     : std_logic_vector(7 downto 0);
    signal sfp_l8_enabled_ports_ttc, sfp_l12_enabled_ports_ttc : std_logic_vector(7 downto 0);

    signal sfp_l8_sn,       sfp_l12_sn       : array_8x128bit;
    signal sfp_l8_mod_abs,  sfp_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal sfp_l8_tx_fault, sfp_l12_tx_fault : std_logic_vector(7 downto 0);
    signal sfp_l8_rx_los,   sfp_l12_rx_los   : std_logic_vector(7 downto 0);

    signal change_l8_mod_abs,  change_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal change_l8_tx_fault, change_l12_tx_fault : std_logic_vector(7 downto 0);
    signal change_l8_rx_los,   change_l12_rx_los   : std_logic_vector(7 downto 0);

    signal change_error_l8_mod_abs,  change_error_l12_mod_abs  : std_logic_vector(7 downto 0);
    signal change_error_l8_tx_fault, change_error_l12_tx_fault : std_logic_vector(7 downto 0);
    signal change_error_l8_rx_los,   change_error_l12_rx_los   : std_logic_vector(7 downto 0);

    signal error_l8_fmc_absent,   error_l12_fmc_absent   : std_logic;
    signal error_l8_fmc_mod_type, error_l12_fmc_mod_type : std_logic;
    signal error_l8_fmc_int_n,    error_l12_fmc_int_n    : std_logic;
    signal error_l8_startup_i2c,  error_l12_startup_i2c  : std_logic;

    signal sfp_en_error_l8_mod_abs,    sfp_en_error_l12_mod_abs    : std_logic_vector(7 downto 0);
    signal sfp_en_error_l8_sfp_type,   sfp_en_error_l12_sfp_type   : std_logic_vector(1 downto 0);
    signal sfp_en_error_l8_tx_fault,   sfp_en_error_l12_tx_fault   : std_logic_vector(7 downto 0);
    signal sfp_en_error_l8_sfp_alarms, sfp_en_error_l12_sfp_alarms : std_logic;
    signal sfp_en_error_l8_i2c_chip,   sfp_en_error_l12_i2c_chip   : std_logic;

    signal sfp_en_alarm_l8_temp_high,     sfp_en_alarm_l12_temp_high     : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_temp_low,      sfp_en_alarm_l12_temp_low      : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_vcc_high,      sfp_en_alarm_l12_vcc_high      : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_vcc_low,       sfp_en_alarm_l12_vcc_low       : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_tx_bias_high,  sfp_en_alarm_l12_tx_bias_high  : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_tx_bias_low,   sfp_en_alarm_l12_tx_bias_low   : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_tx_power_high, sfp_en_alarm_l12_tx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_tx_power_low,  sfp_en_alarm_l12_tx_power_low  : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_rx_power_high, sfp_en_alarm_l12_rx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_alarm_l8_rx_power_low,  sfp_en_alarm_l12_rx_power_low  : std_logic_vector(7 downto 0);

    signal sfp_en_warning_l8_temp_high,     sfp_en_warning_l12_temp_high     : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_temp_low,      sfp_en_warning_l12_temp_low      : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_vcc_high,      sfp_en_warning_l12_vcc_high      : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_vcc_low,       sfp_en_warning_l12_vcc_low       : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_tx_bias_high,  sfp_en_warning_l12_tx_bias_high  : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_tx_bias_low,   sfp_en_warning_l12_tx_bias_low   : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_tx_power_high, sfp_en_warning_l12_tx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_tx_power_low,  sfp_en_warning_l12_tx_power_low  : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_rx_power_high, sfp_en_warning_l12_rx_power_high : std_logic_vector(7 downto 0);
    signal sfp_en_warning_l8_rx_power_low,  sfp_en_warning_l12_rx_power_low  : std_logic_vector(7 downto 0);

    signal sfp_channel_sel_in      : std_logic_vector(7 downto 0);
    signal sfp_eeprom_map_sel_in   : std_logic;
    signal sfp_eeprom_start_adr_in : std_logic_vector(7 downto 0);
    signal sfp_eeprom_num_regs_in  : std_logic_vector(5 downto 0);

    signal l8_eeprom_reg_out,       l12_eeprom_reg_out       : std_logic_vector(127 downto 0);
    signal l8_eeprom_reg_out_valid, l12_eeprom_reg_out_valid : std_logic;

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
    signal l8_aligned_a,       l12_aligned_a       : std_logic_vector(  7 downto 0);
    signal l8_idelay_tap_a,    l12_idelay_tap_a    : std_logic_vector( 39 downto 0);
    signal l8_idelay_locked_a, l12_idelay_locked_a : std_logic;
    signal l8_stats_cnt_a,     l12_stats_cnt_a     : std_logic_vector(255 downto 0);

    signal l8_tts_state,          l12_tts_state          : std_logic_vector(31 downto 0);
    signal l8_tts_state_out,      l12_tts_state_out      : std_logic_vector(63 downto 0);
    signal l8_tts_state_valid,    l12_tts_state_valid    : std_logic_vector( 7 downto 0);
    signal l8_tts_state_mask,     l12_tts_state_mask     : std_logic_vector( 7 downto 0);
    signal l8_tts_state_mask_ttc, l12_tts_state_mask_ttc : std_logic_vector( 7 downto 0);

    signal tts_rx_realign   : std_logic;
    signal tts_rx_realign_i : std_logic_vector(7 downto 0);

    signal sfp_tap_delay_strobe   : std_logic;
    signal sfp_tap_delay_strobe_i : std_logic_vector( 7 downto 0);
    signal sfp_tap_delay          : std_logic_vector( 4 downto 0);
    signal sfp_tap_delay_i        : std_logic_vector(39 downto 0);
    signal sfp_tap_delay_manual   : std_logic;

    -- TTS lock
    signal l8_tts_lock_mux, l12_tts_lock_mux : std_logic;
    signal l8_tts_lock,     l12_tts_lock     : std_logic_vector(7 downto 0);
    signal l8_tts_lock_cnt, l12_tts_lock_cnt : array_8x32bit;

    signal tts_lock_threshold      : std_logic_vector(31 downto 0);
    signal tts_lock_threshold_sync : std_logic_vector(31 downto 0);

    signal tts_misaligned_allowed      : std_logic_vector(31 downto 0);
    signal tts_misaligned_allowed_sync : std_logic_vector(31 downto 0);

    signal l8_tts_msa, l12_tts_msa : std_logic_vector(7 downto 0);
    signal l8_tts_dis, l12_tts_dis : std_logic_vector(7 downto 0);
    signal l8_tts_err, l12_tts_err : std_logic_vector(7 downto 0);
    signal l8_tts_syl, l12_tts_syl : std_logic_vector(7 downto 0);
    signal l8_tts_bsy, l12_tts_bsy : std_logic_vector(7 downto 0);
    signal l8_tts_ofw, l12_tts_ofw : std_logic_vector(7 downto 0);
    signal l8_tts_rdy, l12_tts_rdy : std_logic_vector(7 downto 0);

    signal l8_tts_state_prev  : std_logic_vector(31 downto 0);
    signal l12_tts_state_prev : std_logic_vector(31 downto 0);

    signal l8_tts_update_timer  : array_8x64bit;
    signal l12_tts_update_timer : array_8x64bit;

    signal local_tts_state  : std_logic_vector(3 downto 0);
    signal l8_tts_status    : std_logic_vector(5 downto 0);
    signal l12_tts_status   : std_logic_vector(5 downto 0);
    signal system_status    : std_logic_vector(5 downto 0);
    signal system_tts_state : std_logic_vector(3 downto 0);
    signal local_error      : std_logic;
    signal local_sync_lost  : std_logic;
    signal local_overflow   : std_logic;
    signal abort_run        : std_logic;

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

    -- monitoring the delay for the TTC data input
    signal ttc_data_delay : std_logic_vector( 4 downto 0);
    signal ttc_ddelay_rdy : std_logic;


    -- debugs
    -- attribute mark_debug : string;
    -- attribute mark_debug of SIGNAL_NAME : signal is "true";

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
    clk_wiz_ttc: entity work.clk_wiz_ttc
    port map (
        clk_in1  => ttc_clk,
        clk_out1 => ttc_clk_x2,
        clk_out2 => ttc_clk_x4,
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
    rst_ttc_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => hard_rst_ttc
    );

    -- -------------------------------------
    rst_ttc_x4_sync: entity work.sync_2stage
    port map (
        clk      => ttc_clk_x4,
        sig_i(0) => rst_ipb_stretch,
        sig_o(0) => rst_ttc_x4
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
    rst_ttc_n  <= not rst_ttc;


    -- -----------
    -- LED mapping
    -- -----------

    -- FC7 baseboard
    top_led2(0) <= not error_l12_fmc_absent and not error_l12_fmc_mod_type and not error_l12_fmc_int_n and l12_tts_lock_mux and l12_tts_status(5);
    top_led2(1) <= error_l12_fmc_absent or error_l12_fmc_mod_type or error_l12_fmc_int_n or not l12_tts_lock_mux or not l12_tts_status(5);
    top_led2(2) <= '1';

    top_led3(0) <= not error_l8_fmc_absent and not error_l8_fmc_mod_type and not error_l8_fmc_int_n and l8_tts_lock_mux and l8_tts_status(5);
    top_led3(1) <= error_l8_fmc_absent or error_l8_fmc_mod_type or error_l8_fmc_int_n or not l8_tts_lock_mux or not l8_tts_status(5);
    top_led3(2) <= '1';

    bot_led1(0) <= ttc_clk_lock and ttc_ready;
    bot_led1(1) <= not ttc_clk_lock or not ttc_ready;
    bot_led1(2) <= '1';

    bot_led2(0) <= l8_tts_lock_mux and l12_tts_lock_mux;
    bot_led2(1) <= not l8_tts_lock_mux or not l12_tts_lock_mux;
    bot_led2(2) <= '1';


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


    -- ----------------
    -- register mapping
    -- ----------------

    -- status register
    -- two-stage synchronization is performed in slave module
    stat_reg( 0) <= "10" & "00" & x"0" & usr_ver_major & usr_ver_minor & usr_ver_patch;
    stat_reg( 1) <= x"0" & l8_fmc_id & l12_fmc_id & '0' & board_id;
    stat_reg( 2) <= x"000" & '0' & '0' & trig_info_fifo_full & fmc_ids_valid & fmc_eeprom_error_id & fmc_eeprom_error_i2c & fmcs_ready & l8_tts_lock_mux & l12_tts_lock_mux & ttc_ready & '0' & ttc_clk_lock; -- PARTLY RESERVED FOR ENCODER, TRIGGER USE
    stat_reg( 3) <= measured_vccint  & measured_temp;
    stat_reg( 4) <= measured_vccbram & measured_vccaux;
    stat_reg( 5) <= x"000000" & "000" & alarm_vccbram & alarm_vccaux & alarm_vccint & alarm_temp & over_temp;
    stat_reg( 6) <= l12_eeprom_reg_out( 31 downto  0);
    stat_reg( 7) <= l12_eeprom_reg_out( 63 downto 32);
    stat_reg( 8) <= l12_eeprom_reg_out( 95 downto 64);
    stat_reg( 9) <= l12_eeprom_reg_out(127 downto 96);
    stat_reg(10) <= l8_eeprom_reg_out( 31 downto  0);
    stat_reg(11) <= l8_eeprom_reg_out( 63 downto 32);
    stat_reg(12) <= l8_eeprom_reg_out( 95 downto 64);
    stat_reg(13) <= l8_eeprom_reg_out(127 downto 96);
    stat_reg(14) <= x"00" & sfp_en_error_l12_i2c_chip & sfp_en_error_l12_sfp_alarms & sfp_en_error_l12_tx_fault & sfp_en_error_l12_sfp_type & sfp_en_error_l12_mod_abs & error_l12_startup_i2c & error_l12_fmc_int_n & error_l12_fmc_mod_type & error_l12_fmc_absent;
    stat_reg(15) <= x"00" & sfp_en_error_l8_i2c_chip  & sfp_en_error_l8_sfp_alarms  & sfp_en_error_l8_tx_fault  & sfp_en_error_l8_sfp_type  & sfp_en_error_l8_mod_abs  & error_l8_startup_i2c  & error_l8_fmc_int_n  & error_l8_fmc_mod_type  & error_l8_fmc_absent;
    stat_reg(16) <= sfp_en_alarm_l12_vcc_low & sfp_en_alarm_l12_vcc_high & sfp_en_alarm_l12_temp_low & sfp_en_alarm_l12_temp_high;
    stat_reg(17) <= sfp_en_alarm_l12_tx_power_low & sfp_en_alarm_l12_tx_power_high & sfp_en_alarm_l12_tx_bias_low & sfp_en_alarm_l12_tx_bias_high;
    stat_reg(18) <= x"0000" & sfp_en_alarm_l12_rx_power_low & sfp_en_alarm_l12_rx_power_high;
    stat_reg(19) <= sfp_en_alarm_l8_vcc_low & sfp_en_alarm_l8_vcc_high & sfp_en_alarm_l8_temp_low & sfp_en_alarm_l8_temp_high;
    stat_reg(20) <= sfp_en_alarm_l8_tx_power_low & sfp_en_alarm_l8_tx_power_high & sfp_en_alarm_l8_tx_bias_low & sfp_en_alarm_l8_tx_bias_high;
    stat_reg(21) <= x"0000" & sfp_en_alarm_l8_rx_power_low & sfp_en_alarm_l8_rx_power_high;
    stat_reg(22) <= sfp_en_warning_l12_vcc_low & sfp_en_warning_l12_vcc_high & sfp_en_warning_l12_temp_low & sfp_en_warning_l12_temp_high;
    stat_reg(23) <= sfp_en_warning_l12_tx_power_low & sfp_en_warning_l12_tx_power_high & sfp_en_warning_l12_tx_bias_low & sfp_en_warning_l12_tx_bias_high;
    stat_reg(24) <= x"0000" & sfp_en_warning_l12_rx_power_low & sfp_en_warning_l12_rx_power_high;
    stat_reg(25) <= sfp_en_warning_l8_vcc_low & sfp_en_warning_l8_vcc_high & sfp_en_warning_l8_temp_low & sfp_en_warning_l8_temp_high;
    stat_reg(26) <= sfp_en_warning_l8_tx_power_low & sfp_en_warning_l8_tx_power_high & sfp_en_warning_l8_tx_bias_low & sfp_en_warning_l8_tx_bias_high;
    stat_reg(27) <= x"0000" & sfp_en_warning_l8_rx_power_low & sfp_en_warning_l8_rx_power_high;
    stat_reg(28) <= x"0000" & sfp_l8_enabled_ports & sfp_l12_enabled_ports;
    stat_reg(29) <= x"00" & change_error_l12_mod_abs & change_l12_mod_abs & sfp_l12_mod_abs;
    stat_reg(30) <= x"00" & change_error_l8_mod_abs  & change_l8_mod_abs  & sfp_l8_mod_abs;
    stat_reg(31) <= x"00" & change_error_l12_tx_fault & change_l12_tx_fault & sfp_l12_tx_fault;
    stat_reg(32) <= x"00" & change_error_l8_tx_fault  & change_l8_tx_fault  & sfp_l8_tx_fault;
    stat_reg(33) <= x"00" & change_error_l12_rx_los & change_l12_rx_los & sfp_l12_rx_los;
    stat_reg(34) <= x"00" & change_error_l8_rx_los  & change_l8_rx_los  & sfp_l8_rx_los;
    stat_reg(35) <= x"0000" & l8_tts_lock & l12_tts_lock;
    stat_reg(36) <= l12_tts_state;
    stat_reg(37) <= l8_tts_state;
    stat_reg(38) <= "000" & l8_tts_status & l12_tts_status & local_tts_state & system_status;
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
    stat_reg(52) <= x"0000000" & "00" & error_ttc_mbit_limit & error_ttc_sbit_limit; -- PARTLY RESERVED FOR ENCODER USE
    stat_reg(53) <= x"00000000"; -- PARTLY RESERVED FOR ENCODER USE
    stat_reg(54) <= x"000" & l12_idelay_tap_a(19 downto  0);
    stat_reg(55) <= x"000" & l12_idelay_tap_a(39 downto 20);
    stat_reg(56) <= x"000" & l8_idelay_tap_a(19 downto  0);
    stat_reg(57) <= x"000" & l8_idelay_tap_a(39 downto 20);
    stat_reg(58) <= l12_tts_state_prev;
    stat_reg(59) <= l8_tts_state_prev;
    stat_reg(60) <= x"00000000"; -- RESERVED FOR ENCODER USE
    stat_reg(61) <= x"00000000"; -- RESERVED FOR ENCODER USE
    stat_reg(62) <= ttc_sbit_error_cnt_global;
    stat_reg(63) <= ttc_mbit_error_cnt_global;
    -- stat_reg( to ) <= (others => (others => '0')); -- fill the unused registers with zeros

    sfp_sn_regs: for i in 0 to 7 generate
    begin
        stat_reg(64 + 4*i) <= sfp_l12_sn(i)( 31 downto  0);
        stat_reg(65 + 4*i) <= sfp_l12_sn(i)( 63 downto 32);
        stat_reg(66 + 4*i) <= sfp_l12_sn(i)( 95 downto 64);
        stat_reg(67 + 4*i) <= sfp_l12_sn(i)(127 downto 96);

        stat_reg(96 + 4*i) <= sfp_l8_sn(i)( 31 downto  0);
        stat_reg(97 + 4*i) <= sfp_l8_sn(i)( 63 downto 32);
        stat_reg(98 + 4*i) <= sfp_l8_sn(i)( 95 downto 64);
        stat_reg(99 + 4*i) <= sfp_l8_sn(i)(127 downto 96);
    end generate;

    trig_type_num_regs: for i in 0 to 31 generate
    begin
        stat_reg(128 + i) <= x"00" & trig_type_num(i);
    end generate;

    tts_timer_regs: for i in 0 to 7 generate
    begin
        stat_reg(160 + 2*i) <= l12_tts_update_timer(i)(31 downto  0);
        stat_reg(161 + 2*i) <= l12_tts_update_timer(i)(63 downto 32);

        stat_reg(176 + 2*i) <= l8_tts_update_timer(i)(31 downto  0);
        stat_reg(177 + 2*i) <= l8_tts_update_timer(i)(63 downto 32);
    end generate;

	stat_reg(192 to 193) <= (others => (others => '0')); -- RESERVED FOR TRIGGER USE
    stat_reg(194)( 5 downto 0) <= ttc_ddelay_rdy & ttc_data_delay; -- fill the unused registers with zeros
    stat_reg(194)(31 downto 6) <= (others => '0');
    stat_reg(195 to 208) <= (others => (others => '0')); -- RESERVED FOR TRIGGER USE

    -- control register
    rst_from_ipbus           <= ctrl_reg( 0)( 0);
    soft_rst_from_ipbus      <= ctrl_reg( 0)( 1);
    run_enable               <= ctrl_reg( 0)( 2);
    -- RESERVED              <= ctrl_reg( 0)( 3);
    -- RESERVED              <= ctrl_reg( 0)( 4);
    reprog_fpga_from_ipb     <= ctrl_reg( 0)( 5);
    -- RESERVED              <= ctrl_reg( 1);
    l8_tts_state_mask        <= ctrl_reg( 2)( 7 downto  0);
    l12_tts_state_mask       <= ctrl_reg( 2)(15 downto  8);
    -- UNUSED                <= ctrl_reg( 2)(31 downto 16);
    -- RESERVED              <= ctrl_reg( 3)( 7 downto  0); -- default set
    -- RESERVED              <= ctrl_reg( 3)(11 downto  8);
    -- RESERVED              <= ctrl_reg( 4)(23 downto  0); -- default set
    -- RESERVED              <= ctrl_reg( 5);               -- default set
    tts_lock_threshold       <= ctrl_reg( 6);               -- default set
    sfp_tap_delay_manual     <= ctrl_reg( 7)( 0);
    sfp_tap_delay_strobe     <= ctrl_reg( 7)( 1);
    sfp_tap_delay            <= ctrl_reg( 7)( 6 downto  2);
    tts_rx_realign           <= ctrl_reg( 7)( 7);
    tts_rx_rst_l12_from_ipb  <= ctrl_reg( 7)( 8);
    tts_rx_rst_l8_from_ipb   <= ctrl_reg( 7)( 9);
    sfp_channel_sel_in       <= ctrl_reg( 8)( 7 downto  0);
    sfp_eeprom_map_sel_in    <= ctrl_reg( 8)( 8);
    sfp_eeprom_start_adr_in  <= ctrl_reg( 8)(16 downto  9);
    sfp_eeprom_num_regs_in   <= ctrl_reg( 8)(22 downto 17);
    i2c_l12_rd_start         <= ctrl_reg( 8)(23);
    i2c_l8_rd_start          <= ctrl_reg( 8)(24);
    sfp_l12_requested_ports  <= ctrl_reg( 9)( 7 downto  0);
    sfp_l8_requested_ports   <= ctrl_reg( 9)(15 downto  8);
    i2c_l12_en_start         <= ctrl_reg( 9)(16);
    i2c_l8_en_start          <= ctrl_reg( 9)(17);
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
    l8_ttc_encoded_delay(0)  <= ctrl_reg(13)( 7 downto  0);
    l8_ttc_encoded_delay(1)  <= ctrl_reg(13)(15 downto  8);
    l8_ttc_encoded_delay(2)  <= ctrl_reg(13)(23 downto 16);
    l8_ttc_encoded_delay(3)  <= ctrl_reg(13)(31 downto 24);
    l8_ttc_encoded_delay(4)  <= ctrl_reg(14)( 7 downto  0);
    l8_ttc_encoded_delay(5)  <= ctrl_reg(14)(15 downto  8);
    l8_ttc_encoded_delay(6)  <= ctrl_reg(14)(23 downto 16);
    l8_ttc_encoded_delay(7)  <= ctrl_reg(14)(31 downto 24);
    ttc_sbit_error_threshold <= ctrl_reg(15);
    ttc_mbit_error_threshold <= ctrl_reg(16);
    -- RESERVED              <= ctrl_reg(17);               -- default set
    ttc_decoder_rst_from_ipb <= ctrl_reg(18)(0);
    -- RESERVED              <= ctrl_reg(19)(0);            -- default set
    -- RESERVED              <= ctrl_reg(20);               -- default set
    -- RESERVED              <= ctrl_reg(21);
    -- RESERVED              <= ctrl_reg(22);
    -- RESERVED              <= ctrl_reg(23)(0);
    tts_misaligned_allowed   <= ctrl_reg(24);
    -- RESERVED              <= ctrl_reg(25);               -- default set
    -- RESERVED              <= ctrl_reg(26);               -- default set
    -- RESERVED              <= ctrl_reg(27);
    -- RESERVED              <= ctrl_reg(28);
    -- RESERVED              <= ctrl_reg(29);


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

    -- ------------------------------------------------
    l8_tts_state_mask_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => l8_tts_state_mask,
        sig_o => l8_tts_state_mask_ttc
    );

    -- -------------------------------------------------
    l12_tts_state_mask_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => l12_tts_state_mask,
        sig_o => l12_tts_state_mask_ttc
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
    ttc_decoder_rst_inst: entity work.sync_2stage
    port map (
        clk      => ttc_clk,
        sig_i(0) => ttc_decoder_rst_from_ipb,
        sig_o(0) => ttc_decoder_rst
    );


    -- -------------
    -- trigger logic
    -- -------------

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


    -- -------------
    -- FMC I2C logic
    -- -------------

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
        i2c_rd_start          => i2c_l12_rd_start,        -- from IPbus

        -- generic read interface
        channel_sel_in       => sfp_channel_sel_in,       -- from IPbus
        eeprom_map_sel_in    => sfp_eeprom_map_sel_in,    -- from IPbus
        eeprom_start_adr_in  => sfp_eeprom_start_adr_in,  -- from IPbus
        eeprom_num_regs_in   => sfp_eeprom_num_regs_in,   -- from IPbus
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

    -- --------------------------------------------
    i2c_l8_top_wrapper: entity work.i2c_top_wrapper
    port map (
        -- clock and reset
        clk   => osc125_b_bufg,
        reset => hard_rst_osc125,

        -- control signals
        fmc_loc               => "11",                   -- L8 LOC
        fmc_mod_type          => "00000011",             -- EDA-02707-V2 FMC
        fmc_absent            => fmc_l8_absent,          -- FMC absent signal
        sfp_requested_ports_i => sfp_l8_requested_ports, -- from IPbus
        i2c_en_start          => i2c_l8_en_start,        -- from IPbus
        i2c_rd_start          => i2c_l8_rd_start,        -- from IPbus

        -- generic read interface
        channel_sel_in       => sfp_channel_sel_in,       -- from IPbus
        eeprom_map_sel_in    => sfp_eeprom_map_sel_in,    -- from IPbus
        eeprom_start_adr_in  => sfp_eeprom_start_adr_in,  -- from IPbus
        eeprom_num_regs_in   => sfp_eeprom_num_regs_in,   -- from IPbus
        eeprom_reg_out       => l8_eeprom_reg_out,        -- to IPbus
        eeprom_reg_out_valid => l8_eeprom_reg_out_valid,

        -- status signals
        sfp_enabled_ports => sfp_l8_enabled_ports,
        sfp_sn            => sfp_l8_sn,
        sfp_mod_abs       => sfp_l8_mod_abs,
        sfp_tx_fault      => sfp_l8_tx_fault,
        sfp_rx_los        => sfp_l8_rx_los,

        change_mod_abs  => change_l8_mod_abs,
        change_tx_fault => change_l8_tx_fault,
        change_rx_los   => change_l8_rx_los,

        fs_state  => l8_fs_state,
        st_state  => l8_st_state,
        ssc_state => l8_ssc_state,
        sgr_state => l8_sgr_state,

        -- warning signals
        change_error_mod_abs  => change_error_l8_mod_abs,
        change_error_tx_fault => change_error_l8_tx_fault,
        change_error_rx_los   => change_error_l8_rx_los,

        -- error signals
        error_fmc_absent   => error_l8_fmc_absent,
        error_fmc_mod_type => error_l8_fmc_mod_type,
        error_fmc_int_n    => error_l8_fmc_int_n,
        error_startup_i2c  => error_l8_startup_i2c,

        sfp_en_error_mod_abs    => sfp_en_error_l8_mod_abs,
        sfp_en_error_sfp_type   => sfp_en_error_l8_sfp_type,
        sfp_en_error_tx_fault   => sfp_en_error_l8_tx_fault,
        sfp_en_error_sfp_alarms => sfp_en_error_l8_sfp_alarms,
        sfp_en_error_i2c_chip   => sfp_en_error_l8_i2c_chip,

        -- SFP alarm flags
        sfp_alarm_temp_high     => sfp_en_alarm_l8_temp_high,
        sfp_alarm_temp_low      => sfp_en_alarm_l8_temp_low,
        sfp_alarm_vcc_high      => sfp_en_alarm_l8_vcc_high,
        sfp_alarm_vcc_low       => sfp_en_alarm_l8_vcc_low,
        sfp_alarm_tx_bias_high  => sfp_en_alarm_l8_tx_bias_high,
        sfp_alarm_tx_bias_low   => sfp_en_alarm_l8_tx_bias_low,
        sfp_alarm_tx_power_high => sfp_en_alarm_l8_tx_power_high,
        sfp_alarm_tx_power_low  => sfp_en_alarm_l8_tx_power_low,
        sfp_alarm_rx_power_high => sfp_en_alarm_l8_rx_power_high,
        sfp_alarm_rx_power_low  => sfp_en_alarm_l8_rx_power_low,
          
        -- SFP warning flags
        sfp_warning_temp_high     => sfp_en_warning_l8_temp_high,
        sfp_warning_temp_low      => sfp_en_warning_l8_temp_low,
        sfp_warning_vcc_high      => sfp_en_warning_l8_vcc_high,
        sfp_warning_vcc_low       => sfp_en_warning_l8_vcc_low,
        sfp_warning_tx_bias_high  => sfp_en_warning_l8_tx_bias_high,
        sfp_warning_tx_bias_low   => sfp_en_warning_l8_tx_bias_low,
        sfp_warning_tx_power_high => sfp_en_warning_l8_tx_power_high,
        sfp_warning_tx_power_low  => sfp_en_warning_l8_tx_power_low,
        sfp_warning_rx_power_high => sfp_en_warning_l8_rx_power_high,
        sfp_warning_rx_power_low  => sfp_en_warning_l8_rx_power_low,

        -- I2C signals
        i2c_int_n_i  => i2c_l8_int,     -- active-low I2C interrupt signal
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

    -- ---------------------------------------------------
    sfp_l8_enabled_ports_ttc_inst: entity work.sync_2stage
    generic map (nbr_bits => 8)
    port map (
        clk   => ttc_clk,
        sig_i => sfp_l8_enabled_ports,
        sig_o => sfp_l8_enabled_ports_ttc
    );

    -- assert when I2C state machines are in their MONITOR state
    fmcs_ready <= l8_fs_state(23) and l12_fs_state(23) and l8_ssc_state(9) and l12_ssc_state(9);

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
        l12_ttc_delay_sync: entity work.sync_2stage generic map (nbr_bits => 8) port map ( clk => ttc_clk_x4, sig_i => l12_ttc_encoded_delay(i), sig_o => l12_ttc_encoded_delay_ttc(i) );
        l8_ttc_delay_sync : entity work.sync_2stage generic map (nbr_bits => 8) port map ( clk => ttc_clk_x4, sig_i => l8_ttc_encoded_delay(i),  sig_o => l8_ttc_encoded_delay_ttc(i)  );

        -- delay data streams
        l12_ttc_delay_inst: entity work.shift_register generic map (delay_width => 8) port map ( clock => ttc_clk_x4, delay => l12_ttc_encoded_delay_ttc(i), data_in => ttc_encoded, data_out => sfp_l12_tx_delay(i) );
        l8_ttc_delay_inst : entity work.shift_register generic map (delay_width => 8) port map ( clock => ttc_clk_x4, delay => l8_ttc_encoded_delay_ttc(i),  data_in => ttc_encoded, data_out => sfp_l8_tx_delay(i)  );

        -- select enabled ports
        sfp_l12_tx(i) <= sfp_l12_tx_delay(i) when sfp_l12_enabled_ports(i) = '1' else '0';
        sfp_l8_tx(i)  <= sfp_l8_tx_delay(i)  when sfp_l8_enabled_ports(i)  = '1' else '0';

        -- output data streams
        SFP_L12_TX_I_OBUFDS: OBUFDS port map ( I => sfp_l12_tx(i), O => sfp_l12_tx_p(i), OB => sfp_l12_tx_n(i) );
        SFP_L8_TX_I_OBUFDS : OBUFDS port map ( I => sfp_l8_tx(i),  O => sfp_l8_tx_p(i),  OB => sfp_l8_tx_n(i)  );
    end generate;


    -- ------------------
    -- TTS receiver logic
    -- ------------------

    tts_rx_realign_i       <= (others => tts_rx_realign);
    sfp_tap_delay_i        <= sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay & sfp_tap_delay;
    sfp_tap_delay_strobe_i <= (others => sfp_tap_delay_strobe);

    -- ---------------------------
    l12_tts_rx: entity work.tts_rx
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

    -- --------------------------
    l8_tts_rx: entity work.tts_rx
    generic map (
        idelayctrl_gen                  => true,
        idelaygroup                     => "l8_idelay_group",
        nbr_channels                    => 8,
        bitslip_delay                   => 1024,
        consecutive_valid_chars_to_lock => 1024,
        misaligned_state_code           => x"FF",
        allow_all_0000xxxx              => false
    )
    port map (
        -- clocks and reset
        reset_i         => tts_rx_rst_l8_from_ipb,
        clk_i           => ttc_clk,
        pclk_i          => ttc_clk_x2,             -- parallel clock
        sclk_i          => ttc_clk_x10,            -- serial clock
        -- alignment
        align_str_i     => tts_rx_realign_i,       -- when 0, in alignment cycle, to realign 0->1->0
        aligned_o       => l8_aligned_a,           -- when 1, bitslip is successful
        -- delays
        idelay_manual_i => sfp_tap_delay_manual,
        idelay_ld_i     => sfp_tap_delay_strobe_i, -- strobe for loading input delay values
        idelay_tap_i    => sfp_tap_delay_i,        -- dynamically loadable delay tap value for input delay
        idelay_tap_o    => l8_idelay_tap_a,        -- delay tap value for monitoring input delay
        idelay_locked_o => l8_idelay_locked_a,     -- idelay ctrl locked
        idelay_clk_i    => ttc_clk_x5,             -- reference clock for idelayctrl, has to come from bufg
        -- statistics
        stats_clr       => x"00",
        stats_cnt       => l8_stats_cnt_a,         -- delay tap value for monitoring input delay
        -- inputs and outputs
        i               => sfp_l8_rx_p,
        ib              => sfp_l8_rx_n,
        o               => l8_tts_state_out,
        dv_o            => l8_tts_state_valid
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

                if l8_tts_state_valid(i) = '1' and l8_aligned_a(i) = '1' then
                    -- update TTS state
                    l8_tts_state(4*i+3 downto 4*i) <= l8_tts_state_out(8*i+3 downto 8*i);

                    -- record TTS state changes
                    if l8_tts_state(4*i+3 downto 4*i) /= l8_tts_state_out(8*i+3 downto 8*i) then
                        -- TTS state changed
                        l8_tts_state_prev(4*i+3 downto 4*i) <= l8_tts_state(4*i+3 downto 4*i);
                        l8_tts_update_timer(i) <= x"0000_0000_0000_0000"; -- clear timer
                    else
                        l8_tts_update_timer(i) <= l8_tts_update_timer(i) + 1;
                    end if;
                else
                    -- keep the same TTS state
                    l8_tts_state(4*i+3 downto 4*i) <= l8_tts_state(4*i+3 downto 4*i);
                    l8_tts_update_timer(i) <= l8_tts_update_timer(i) + 1;
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

                -- lock counter logic
                if l8_tts_state_valid(i) = '1' and l8_aligned_a(i) = '1' then
                    if l8_tts_lock_cnt(i) = tts_lock_threshold_sync then
                        l8_tts_lock_cnt(i) <= l8_tts_lock_cnt(i); -- keep value at threshold
                    else
                        l8_tts_lock_cnt(i) <= l8_tts_lock_cnt(i) + 1; -- increment lock counter
                    end if;
                else
                    if l8_tts_lock_cnt(i) > 0 then
                        l8_tts_lock_cnt(i) <= l8_tts_lock_cnt(i) - 1; -- decrement lock counter
                    end if;
                end if;

                -- locked logic
                if l12_tts_lock_cnt(i) >= (tts_lock_threshold_sync - tts_misaligned_allowed_sync) then
                    l12_tts_lock(i) <= '1'; -- locked
                else
                    l12_tts_lock(i) <= '0'; -- not locked
                end if;

                -- locked logic
                if l8_tts_lock_cnt(i) >= (tts_lock_threshold_sync - tts_misaligned_allowed_sync) then
                    l8_tts_lock(i) <= '1'; -- locked
                else
                    l8_tts_lock(i) <= '0'; -- not locked
                end if;
            end loop;

            -- define system locks
            if ((l12_tts_lock xor (sfp_l12_enabled_ports_ttc xor l12_tts_state_mask_ttc)) and (sfp_l12_enabled_ports_ttc xor l12_tts_state_mask_ttc)) = x"00" then
                l12_tts_lock_mux <= ttc_clk_lock and ttc_ready; -- lock only valid if ttc_clk is valid
            else
                l12_tts_lock_mux <= '0';
            end if;

            if ((l8_tts_lock xor (sfp_l8_enabled_ports_ttc xor l8_tts_state_mask_ttc)) and (sfp_l8_enabled_ports_ttc xor l8_tts_state_mask_ttc)) = x"00" then
                l8_tts_lock_mux <= ttc_clk_lock and ttc_ready; -- lock only valid if ttc_clk is valid
            else
                l8_tts_lock_mux <= '0';
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
                l8_tts_msa(i) <= '0'; l12_tts_msa(i) <= '0';
                l8_tts_dis(i) <= '0'; l12_tts_dis(i) <= '0';
                l8_tts_err(i) <= '0'; l12_tts_err(i) <= '0';
                l8_tts_syl(i) <= '0'; l12_tts_syl(i) <= '0';
                l8_tts_bsy(i) <= '0'; l12_tts_bsy(i) <= '0';
                l8_tts_ofw(i) <= '0'; l12_tts_ofw(i) <= '0';
                l8_tts_rdy(i) <= '0'; l12_tts_rdy(i) <= '0';

                -- overwrite one of the bits, when state is valid
                case l12_tts_state(4*i+3 downto 4*i) is
                    when "0000" => l12_tts_dis(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1111" => l12_tts_dis(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1100" => l12_tts_err(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0010" => l12_tts_syl(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0100" => l12_tts_bsy(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0001" => l12_tts_ofw(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1000" => l12_tts_rdy(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when others => l12_tts_msa(i) <= l12_tts_lock_mux and (sfp_l12_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                end case;

                case l8_tts_state(4*i+3 downto 4*i) is
                    when "0000" => l8_tts_dis(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1111" => l8_tts_dis(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1100" => l8_tts_err(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0010" => l8_tts_syl(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0100" => l8_tts_bsy(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "0001" => l8_tts_ofw(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when "1000" => l8_tts_rdy(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                    when others => l8_tts_msa(i) <= l8_tts_lock_mux and (sfp_l8_enabled_ports_ttc(i) xor l8_tts_state_mask_ttc(i));
                end case;
            end loop;

            -- define status
            if    l12_tts_dis /= x"00" then l12_tts_status <= "000001"; -- disconnected
            elsif l12_tts_err /= x"00" then l12_tts_status <= "000010"; -- error
            elsif l12_tts_syl /= x"00" then l12_tts_status <= "000100"; -- sync lost
            elsif l12_tts_msa /= x"00" then l12_tts_status <= "000100"; -- sync lost / misaligned
            elsif l12_tts_bsy /= x"00" then l12_tts_status <= "001000"; -- busy
            elsif l12_tts_ofw /= x"00" then l12_tts_status <= "010000"; -- overflow warning
            else                            l12_tts_status <= "100000"; -- ready
            end if;

            if    l8_tts_dis /= x"00" then l8_tts_status <= "000001"; -- disconnected
            elsif l8_tts_err /= x"00" then l8_tts_status <= "000010"; -- error
            elsif l8_tts_syl /= x"00" then l8_tts_status <= "000100"; -- sync lost
            elsif l8_tts_msa /= x"00" then l8_tts_status <= "000100"; -- sync lost / misaligned
            elsif l8_tts_bsy /= x"00" then l8_tts_status <= "001000"; -- busy
            elsif l8_tts_ofw /= x"00" then l8_tts_status <= "010000"; -- overflow warning
            else                           l8_tts_status <= "100000"; -- ready
            end if;
        end if;
    end process;

    -- combine local state conditions;
    -- they must be independent of TTS RX signals
    local_error     <= '1' when fmc_ids_valid        = '0' or over_temp              = '1' or ttc_clk_lock        = '0' or
                                error_ttc_sbit_limit = '1' or error_ttc_mbit_limit   = '1' or ttc_ready           = '0' or
                                error_l12_fmc_absent = '1' or error_l12_fmc_mod_type = '1' or error_l12_fmc_int_n = '1' or
                                error_l8_fmc_absent  = '1' or error_l8_fmc_mod_type  = '1' or error_l8_fmc_int_n  = '1' or
                                xadc_alarms               /= x"0"  or
                                change_error_l12_mod_abs  /= x"00" or change_error_l8_mod_abs  /= x"00" or
                                change_error_l12_tx_fault /= x"00" or change_error_l8_tx_fault /= x"00" or
                                change_error_l12_rx_los   /= x"00" or change_error_l8_rx_los   /= x"00" else '0';
    local_sync_lost <= not l8_tts_lock_mux or not l12_tts_lock_mux;
    local_overflow  <= trig_info_fifo_full;

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
            if                                l8_tts_status(0) = '1' or l12_tts_status(0) = '1' then system_status <= "000001"; system_tts_state <= "0000"; -- disconnected
            elsif local_tts_state = "1100" or l8_tts_status(1) = '1' or l12_tts_status(1) = '1' then system_status <= "000010"; system_tts_state <= "1100"; -- error
            elsif local_tts_state = "0010" or l8_tts_status(2) = '1' or l12_tts_status(2) = '1' then system_status <= "000100"; system_tts_state <= "0010"; -- sync lost
            elsif                             l8_tts_status(3) = '1' or l12_tts_status(3) = '1' then system_status <= "001000"; system_tts_state <= "0100"; -- busy
            elsif local_tts_state = "0001" or l8_tts_status(4) = '1' or l12_tts_status(4) = '1' then system_status <= "010000"; system_tts_state <= "0001"; -- overflow warning
            else                                                                                     system_status <= "100000"; system_tts_state <= "1000"; -- ready
            end if;
        end if;
    end process;

    abort_run <= '1' when system_status(2 downto 0) /= "0000" or ttc_clk_lock = '0' or ttc_ready = '0' else '0';


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
        Brcst       => ttc_chan_b_info,   -- channel b data
        TTC_CLK_ddelay => ttc_clk_x5,     -- clock for IDELAYE2 for data
        delay_count    => ttc_data_delay, -- amount that ttc data is delayed
        delay_rdy      => ttc_ddelay_rdy -- delay unit ready for data delay
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


    -- ---------------------
    -- TTC re-encoding logic
    -- ---------------------

    -- 2-stage synchronizer
    process(ttc_clk_x4)
    begin
        if rising_edge(ttc_clk_x4) then
            a_channel1 <= trigger_from_ttc;
            a_channel2 <= a_channel1;
            a_channel3 <= a_channel2;

            -- rising-edge detect
            if a_channel2 = '1' and a_channel3 = '0' then
                a_channel_sync <= '1';
            else
                a_channel_sync <= '0';
            end if;

            b_channel1 <= ttc_chan_b_info & "00";
            b_channel2 <= b_channel1;

            b_channel_valid1 <= ttc_chan_b_valid;
            b_channel_valid2 <= b_channel_valid1;
            b_channel_valid3 <= b_channel_valid2;

            -- rising-edge detect
            if b_channel_valid2 = '1' and b_channel_valid3 = '0' then
                b_channel_valid_sync <= '1';
            else
                b_channel_valid_sync <= '0';
            end if;

            ttc_evt_reset1 <= ttc_evt_reset;
            ttc_evt_reset2 <= ttc_evt_reset1;
            ttc_evt_reset3 <= ttc_evt_reset2;

            -- rising-edge detect
            if ttc_evt_reset2 = '1' and ttc_evt_reset3 = '0' then
                ttc_evt_reset_sync <= '1';
            else
                ttc_evt_reset_sync <= '0';
            end if;

            ttc_bcnt_reset1 <= ttc_bcnt_reset;
            ttc_bcnt_reset2 <= ttc_bcnt_reset1;
            ttc_bcnt_reset3 <= ttc_bcnt_reset2;

            -- rising-edge detect
            if ttc_bcnt_reset2 = '1' and ttc_bcnt_reset3 = '0' then
                ttc_bcnt_reset_sync <= '1';
            else
                ttc_bcnt_reset_sync <= '0';
            end if;

            ttc_chan_b_mux       <= b_channel2(7 downto 2) & ttc_evt_reset2 & ttc_bcnt_reset2;
            ttc_chan_b_valid_mux <= b_channel_valid_sync or ttc_evt_reset_sync or ttc_bcnt_reset_sync;
        end if;
    end process;

    -- ----------------------------------------------
    ttc_data_hamming: entity work.ttc_chan_b_data_mux
    port map (
        clk       => ttc_clk_x4,
        b_channel => ttc_chan_b_mux,
        ttc_data  => ttc_data
    );

    -- ----------------------------------------
    ttc_signal: entity work.ttc_encoder_wrapper
    port map (
        clk            => ttc_clk_x4,
        rst            => rst_ttc_x4,
        a_channel      => a_channel_sync,
        ttc_data       => ttc_data,
        ttc_data_valid => ttc_chan_b_valid_mux,
        ttc_bit_out    => ttc_encoded
    );


    -- ---------------------------
    -- trigger information storage
    -- ---------------------------

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
        fifo_ready => s_trig_info_fifo_tready,
        fifo_data  => s_trig_info_fifo_tdata,
        fifo_valid => s_trig_info_fifo_tvalid,

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
        s_axis_tvalid  => s_trig_info_fifo_tvalid,
        s_axis_tready  => s_trig_info_fifo_tready,
        s_axis_tdata   => s_trig_info_fifo_tdata,
        m_axis_tvalid  => m_trig_info_fifo_tvalid,
        m_axis_tready  => m_trig_info_fifo_tready,
        m_axis_tdata   => m_trig_info_fifo_tdata,
        axis_prog_full => trig_info_fifo_full
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
        fc7_type           => "10",
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
        tts_lock_thres     => tts_lock_threshold,
        ofw_watchdog_thres => x"000000",
        l12_enabled_ports  => sfp_l12_enabled_ports,
        l8_enabled_ports   => sfp_l8_enabled_ports,
        l12_tts_mask       => l12_tts_state_mask,
        l8_tts_mask        => l8_tts_state_mask,
        l12_ttc_delays     => l12_ttc_encoded_delay,
        l8_ttc_delays      => l8_ttc_encoded_delay,
        l12_sfp_sn         => sfp_l12_sn,
        l8_sfp_sn          => sfp_l8_sn,

        -- variable event information
        l12_tts_state             => l12_tts_state,
        l8_tts_state              => l8_tts_state,
        l12_tts_lock              => l12_tts_lock,
        l8_tts_lock               => l8_tts_lock,
        l12_tts_lock_mux          => l12_tts_lock_mux,
        l8_tts_lock_mux           => l8_tts_lock_mux,
        ext_clk_lock              => '0',
        ttc_clk_lock              => ttc_clk_lock,
        ttc_ready                 => ttc_ready,
        xadc_alarms               => xadc_alarms,
        error_flag                => abort_run,
        error_l12_fmc_absent      => error_l12_fmc_absent,
        error_l8_fmc_absent       => error_l8_fmc_absent,
        change_error_l12_mod_abs  => change_error_l12_mod_abs,
        change_error_l8_mod_abs   => change_error_l8_mod_abs,
        change_error_l12_tx_fault => change_error_l12_tx_fault,
        change_error_l8_tx_fault  => change_error_l8_tx_fault,
        change_error_l12_rx_los   => change_error_l12_rx_los,
        change_error_l8_rx_los    => change_error_l8_rx_los,

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
        TTS    => system_tts_state,
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
