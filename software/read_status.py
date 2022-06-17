# FC7 general status script
# python read_status.py [crate] [slot] [options]

import uhal, sys, binascii
uhal.disableLogging()

# check number of arguments
if len(sys.argv)<3:
    print('usage: python read_status.py [crate] [slot] [options]')
    print('')
    print('options:')
    print('  expert : print firmware signals')
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# read status registers
regs = fc7.getNode("STATUS").readBlock(209)
fc7.dispatch()

# colors
GRAY  = "\033[47;30m"
BLUE  = "\033[0;34m"
RESET = "\033[m\017"

# interpret signals
patch_rev                        = '{0:032b}'.format(int(regs.value()[  0]))[24:32]
minor_rev                        = '{0:032b}'.format(int(regs.value()[  0]))[16:24]
major_rev                        = '{0:032b}'.format(int(regs.value()[  0]))[ 8:16]
board_type                       = '{0:032b}'.format(int(regs.value()[  0]))[ 0: 2]
board_id                         = '{0:032b}'.format(int(regs.value()[  1]))[20:32]
l12_fmc_id                       = '{0:032b}'.format(int(regs.value()[  1]))[12:20]
l8_fmc_id                        = '{0:032b}'.format(int(regs.value()[  1]))[ 4:12]
ttc_clk_lock                     = '{0:032b}'.format(int(regs.value()[  2]))[31:32]
ext_clk_lock                     = '{0:032b}'.format(int(regs.value()[  2]))[30:31]
ttc_ready                        = '{0:032b}'.format(int(regs.value()[  2]))[29:30]
l12_tts_lock_mux                 = '{0:032b}'.format(int(regs.value()[  2]))[28:29]
l8_tts_lock_mux                  = '{0:032b}'.format(int(regs.value()[  2]))[27:28]
fmcs_ready                       = '{0:032b}'.format(int(regs.value()[  2]))[26:27]
fmc_eeprom_error_i2c             = '{0:032b}'.format(int(regs.value()[  2]))[25:26]
fmc_eeprom_error_id              = '{0:032b}'.format(int(regs.value()[  2]))[24:25]
fmc_ids_valid                    = '{0:032b}'.format(int(regs.value()[  2]))[23:24]
async_enable_sent                = '{0:032b}'.format(int(regs.value()[  2]))[20:21]
measured_temp                    = '{0:032b}'.format(int(regs.value()[  3]))[16:28]
measured_vccint                  = '{0:032b}'.format(int(regs.value()[  3]))[ 0:12]
measured_vccaux                  = '{0:032b}'.format(int(regs.value()[  4]))[16:28]
measured_vccbram                 = '{0:032b}'.format(int(regs.value()[  4]))[ 0:12]
over_temp                        = '{0:032b}'.format(int(regs.value()[  5]))[31:32]
alarm_temp                       = '{0:032b}'.format(int(regs.value()[  5]))[30:31]
alarm_vccint                     = '{0:032b}'.format(int(regs.value()[  5]))[29:30]
alarm_vccaux                     = '{0:032b}'.format(int(regs.value()[  5]))[28:29]
alarm_vccbram                    = '{0:032b}'.format(int(regs.value()[  5]))[27:28]
l12_eeprom_reg_out1              = '{0:032b}'.format(int(regs.value()[  6]))[ 0:32]
l12_eeprom_reg_out2              = '{0:032b}'.format(int(regs.value()[  7]))[ 0:32]
l12_eeprom_reg_out3              = '{0:032b}'.format(int(regs.value()[  8]))[ 0:32]
l12_eeprom_reg_out4              = '{0:032b}'.format(int(regs.value()[  9]))[ 0:32]
l8_eeprom_reg_out1               = '{0:032b}'.format(int(regs.value()[ 10]))[ 0:32]
l8_eeprom_reg_out2               = '{0:032b}'.format(int(regs.value()[ 11]))[ 0:32]
l8_eeprom_reg_out3               = '{0:032b}'.format(int(regs.value()[ 12]))[ 0:32]
l8_eeprom_reg_out4               = '{0:032b}'.format(int(regs.value()[ 13]))[ 0:32]
error_l12_fmc_absent             = '{0:032b}'.format(int(regs.value()[ 14]))[31:32]
error_l12_fmc_mod_type           = '{0:032b}'.format(int(regs.value()[ 14]))[30:31]
error_l12_fmc_int_n              = '{0:032b}'.format(int(regs.value()[ 14]))[29:30]
error_l12_startup_i2c            = '{0:032b}'.format(int(regs.value()[ 14]))[28:29]
sfp_en_error_l12_mod_abs         = '{0:032b}'.format(int(regs.value()[ 14]))[20:28]
sfp_en_error_l12_sfp_type        = '{0:032b}'.format(int(regs.value()[ 14]))[18:20]
sfp_en_error_l12_tx_fault        = '{0:032b}'.format(int(regs.value()[ 14]))[10:18]
sfp_en_error_l12_sfp_alarms      = '{0:032b}'.format(int(regs.value()[ 14]))[ 9:10]
sfp_en_error_l12_i2c_chip        = '{0:032b}'.format(int(regs.value()[ 14]))[ 8: 9]
error_l8_fmc_absent              = '{0:032b}'.format(int(regs.value()[ 15]))[31:32]
error_l8_fmc_mod_type            = '{0:032b}'.format(int(regs.value()[ 15]))[30:31]
error_l8_fmc_int_n               = '{0:032b}'.format(int(regs.value()[ 15]))[29:30]
error_l8_startup_i2c             = '{0:032b}'.format(int(regs.value()[ 15]))[28:29]
sfp_en_error_l8_mod_abs          = '{0:032b}'.format(int(regs.value()[ 15]))[20:28]
sfp_en_error_l8_sfp_type         = '{0:032b}'.format(int(regs.value()[ 15]))[18:20]
sfp_en_error_l8_tx_fault         = '{0:032b}'.format(int(regs.value()[ 15]))[10:18]
sfp_en_error_l8_sfp_alarms       = '{0:032b}'.format(int(regs.value()[ 15]))[ 9:10]
sfp_en_error_l8_i2c_chip         = '{0:032b}'.format(int(regs.value()[ 15]))[ 8: 9]
sfp_en_alarm_l12_temp_high       = '{0:032b}'.format(int(regs.value()[ 16]))[24:32]
sfp_en_alarm_l12_temp_low        = '{0:032b}'.format(int(regs.value()[ 16]))[16:24]
sfp_en_alarm_l12_vcc_high        = '{0:032b}'.format(int(regs.value()[ 16]))[ 8:16]
sfp_en_alarm_l12_vcc_low         = '{0:032b}'.format(int(regs.value()[ 16]))[ 0: 8]
sfp_en_alarm_l12_tx_bias_high    = '{0:032b}'.format(int(regs.value()[ 17]))[24:32]
sfp_en_alarm_l12_tx_bias_low     = '{0:032b}'.format(int(regs.value()[ 17]))[16:24]
sfp_en_alarm_l12_tx_power_high   = '{0:032b}'.format(int(regs.value()[ 17]))[ 8:16]
sfp_en_alarm_l12_tx_power_low    = '{0:032b}'.format(int(regs.value()[ 17]))[ 0: 8]
sfp_en_alarm_l12_rx_power_high   = '{0:032b}'.format(int(regs.value()[ 18]))[24:32]
sfp_en_alarm_l12_rx_power_low    = '{0:032b}'.format(int(regs.value()[ 18]))[16:24]
sfp_en_alarm_l8_temp_high        = '{0:032b}'.format(int(regs.value()[ 19]))[24:32]
sfp_en_alarm_l8_temp_low         = '{0:032b}'.format(int(regs.value()[ 19]))[16:24]
sfp_en_alarm_l8_vcc_high         = '{0:032b}'.format(int(regs.value()[ 19]))[ 8:16]
sfp_en_alarm_l8_vcc_low          = '{0:032b}'.format(int(regs.value()[ 19]))[ 0: 8]
sfp_en_alarm_l8_tx_bias_high     = '{0:032b}'.format(int(regs.value()[ 20]))[24:32]
sfp_en_alarm_l8_tx_bias_low      = '{0:032b}'.format(int(regs.value()[ 20]))[16:24]
sfp_en_alarm_l8_tx_power_high    = '{0:032b}'.format(int(regs.value()[ 20]))[ 8:16]
sfp_en_alarm_l8_tx_power_low     = '{0:032b}'.format(int(regs.value()[ 20]))[ 0: 8]
sfp_en_alarm_l8_rx_power_high    = '{0:032b}'.format(int(regs.value()[ 21]))[24:32]
sfp_en_alarm_l8_rx_power_low     = '{0:032b}'.format(int(regs.value()[ 21]))[16:24]
sfp_en_warning_l12_temp_high     = '{0:032b}'.format(int(regs.value()[ 22]))[24:32]
sfp_en_warning_l12_temp_low      = '{0:032b}'.format(int(regs.value()[ 22]))[16:24]
sfp_en_warning_l12_vcc_high      = '{0:032b}'.format(int(regs.value()[ 22]))[ 8:16]
sfp_en_warning_l12_vcc_low       = '{0:032b}'.format(int(regs.value()[ 22]))[ 0: 8]
sfp_en_warning_l12_tx_bias_high  = '{0:032b}'.format(int(regs.value()[ 23]))[24:32]
sfp_en_warning_l12_tx_bias_low   = '{0:032b}'.format(int(regs.value()[ 23]))[16:24]
sfp_en_warning_l12_tx_power_high = '{0:032b}'.format(int(regs.value()[ 23]))[ 8:16]
sfp_en_warning_l12_tx_power_low  = '{0:032b}'.format(int(regs.value()[ 23]))[ 0: 8]
sfp_en_warning_l12_rx_power_high = '{0:032b}'.format(int(regs.value()[ 24]))[24:32]
sfp_en_warning_l12_rx_power_low  = '{0:032b}'.format(int(regs.value()[ 24]))[16:24]
sfp_en_warning_l8_temp_high      = '{0:032b}'.format(int(regs.value()[ 25]))[24:32]
sfp_en_warning_l8_temp_low       = '{0:032b}'.format(int(regs.value()[ 25]))[16:24]
sfp_en_warning_l8_vcc_high       = '{0:032b}'.format(int(regs.value()[ 25]))[ 8:16]
sfp_en_warning_l8_vcc_low        = '{0:032b}'.format(int(regs.value()[ 25]))[ 0: 8]
sfp_en_warning_l8_tx_bias_high   = '{0:032b}'.format(int(regs.value()[ 26]))[24:32]
sfp_en_warning_l8_tx_bias_low    = '{0:032b}'.format(int(regs.value()[ 26]))[16:24]
sfp_en_warning_l8_tx_power_high  = '{0:032b}'.format(int(regs.value()[ 26]))[ 8:16]
sfp_en_warning_l8_tx_power_low   = '{0:032b}'.format(int(regs.value()[ 26]))[ 0: 8]
sfp_en_warning_l8_rx_power_high  = '{0:032b}'.format(int(regs.value()[ 27]))[24:32]
sfp_en_warning_l8_rx_power_low   = '{0:032b}'.format(int(regs.value()[ 27]))[16:24]
sfp_l12_enabled_ports            = '{0:032b}'.format(int(regs.value()[ 28]))[24:32]
sfp_l8_enabled_ports             = '{0:032b}'.format(int(regs.value()[ 28]))[16:24]
sfp_l12_mod_abs                  = '{0:032b}'.format(int(regs.value()[ 29]))[24:32]
change_l12_mod_abs               = '{0:032b}'.format(int(regs.value()[ 29]))[16:24]
change_error_l12_mod_abs         = '{0:032b}'.format(int(regs.value()[ 29]))[ 8:16]
sfp_l8_mod_abs                   = '{0:032b}'.format(int(regs.value()[ 30]))[24:32]
change_l8_mod_abs                = '{0:032b}'.format(int(regs.value()[ 30]))[16:24]
change_error_l8_mod_abs          = '{0:032b}'.format(int(regs.value()[ 30]))[ 8:16]
sfp_l12_tx_fault                 = '{0:032b}'.format(int(regs.value()[ 31]))[24:32]
change_l12_tx_fault              = '{0:032b}'.format(int(regs.value()[ 31]))[16:24]
change_error_l12_tx_fault        = '{0:032b}'.format(int(regs.value()[ 31]))[ 8:16]
sfp_l8_tx_fault                  = '{0:032b}'.format(int(regs.value()[ 32]))[24:32]
change_l8_tx_fault               = '{0:032b}'.format(int(regs.value()[ 32]))[16:24]
change_error_l8_tx_fault         = '{0:032b}'.format(int(regs.value()[ 32]))[ 8:16]
sfp_l12_rx_los                   = '{0:032b}'.format(int(regs.value()[ 33]))[24:32]
change_l12_rx_los                = '{0:032b}'.format(int(regs.value()[ 33]))[16:24]
change_error_l12_rx_los          = '{0:032b}'.format(int(regs.value()[ 33]))[ 8:16]
sfp_l8_rx_los                    = '{0:032b}'.format(int(regs.value()[ 34]))[24:32]
change_l8_rx_los                 = '{0:032b}'.format(int(regs.value()[ 34]))[16:24]
change_error_l8_rx_los           = '{0:032b}'.format(int(regs.value()[ 34]))[ 8:16]
l12_tts_lock                     = '{0:032b}'.format(int(regs.value()[ 35]))[24:32]
l8_tts_lock                      = '{0:032b}'.format(int(regs.value()[ 35]))[16:24]
l12_tts_state                    = '{0:032b}'.format(int(regs.value()[ 36]))[ 0:32]
l8_tts_state                     = '{0:032b}'.format(int(regs.value()[ 37]))[ 0:32]
system_status                    = '{0:032b}'.format(int(regs.value()[ 38]))[26:32]
local_tts_state                  = '{0:032b}'.format(int(regs.value()[ 38]))[22:26]
l12_tts_status                   = '{0:032b}'.format(int(regs.value()[ 38]))[16:22]
l8_tts_status                    = '{0:032b}'.format(int(regs.value()[ 38]))[10:16]
ts_state1                        = '{0:032b}'.format(int(regs.value()[ 39]))[16:32]
eb_state1                        = '{0:032b}'.format(int(regs.value()[ 39]))[ 0:16]
l12_fs_state                     = '{0:032b}'.format(int(regs.value()[ 40]))[ 4:32]
l12_st_state1                    = '{0:032b}'.format(int(regs.value()[ 40]))[ 3: 4]
eb_state2                        = '{0:032b}'.format(int(regs.value()[ 40]))[ 2: 3]
l8_fs_state                      = '{0:032b}'.format(int(regs.value()[ 41]))[ 4:32]
l8_st_state1                     = '{0:032b}'.format(int(regs.value()[ 41]))[ 3: 4]
ts_state2                        = '{0:032b}'.format(int(regs.value()[ 41]))[ 2: 3]
l12_st_state2                    = '{0:032b}'.format(int(regs.value()[ 42]))[ 0:32]
l8_st_state2                     = '{0:032b}'.format(int(regs.value()[ 43]))[ 0:32]
l12_ssc_state                    = '{0:032b}'.format(int(regs.value()[ 44]))[21:32]
l8_ssc_state                     = '{0:032b}'.format(int(regs.value()[ 44]))[10:21]
tis_state                        = '{0:032b}'.format(int(regs.value()[ 44]))[ 8:10]
l12_sgr_state                    = '{0:032b}'.format(int(regs.value()[ 45]))[25:32]
l8_sgr_state                     = '{0:032b}'.format(int(regs.value()[ 45]))[18:25]
fe_state                         = '{0:032b}'.format(int(regs.value()[ 45]))[ 7:18]
run_in_progress                  = '{0:032b}'.format(int(regs.value()[ 46]))[31:32]
doing_run_checks                 = '{0:032b}'.format(int(regs.value()[ 46]))[30:31]
resetting_clients                = '{0:032b}'.format(int(regs.value()[ 46]))[29:30]
finding_cycle_start              = '{0:032b}'.format(int(regs.value()[ 46]))[28:29]
run_aborted                      = '{0:032b}'.format(int(regs.value()[ 46]))[27:28]
trig_index                       = '{0:032b}'.format(int(regs.value()[ 46]))[23:27]
trig_sub_index                   = '{0:032b}'.format(int(regs.value()[ 46]))[19:23]
trig_num                         = '{0:032b}'.format(int(regs.value()[ 47]))[ 8:32]
trig_timestamp1                  = '{0:032b}'.format(int(regs.value()[ 48]))[ 0:32]
trig_timestamp2                  = '{0:032b}'.format(int(regs.value()[ 49]))[20:32]
ttc_sbit_error_cnt               = '{0:032b}'.format(int(regs.value()[ 50]))[ 0:32]
ttc_mbit_error_cnt               = '{0:032b}'.format(int(regs.value()[ 51]))[ 0:32]
error_ttc_sbit_limit             = '{0:032b}'.format(int(regs.value()[ 52]))[31:32]
error_ttc_mbit_limit             = '{0:032b}'.format(int(regs.value()[ 52]))[30:31]
ofw_trig_count_running           = '{0:032b}'.format(int(regs.value()[ 52]))[ 4:28]
ofw_trig_count                   = '{0:032b}'.format(int(regs.value()[ 53]))[ 8:32]
ofw_limit_reached                = '{0:032b}'.format(int(regs.value()[ 53]))[ 7: 8]
l12_tts_tap_delay_1              = '{0:032b}'.format(int(regs.value()[ 54]))[27:32]
l12_tts_tap_delay_2              = '{0:032b}'.format(int(regs.value()[ 54]))[22:27]
l12_tts_tap_delay_3              = '{0:032b}'.format(int(regs.value()[ 54]))[17:22]
l12_tts_tap_delay_4              = '{0:032b}'.format(int(regs.value()[ 54]))[12:17]
l12_tts_tap_delay_5              = '{0:032b}'.format(int(regs.value()[ 55]))[27:32]
l12_tts_tap_delay_6              = '{0:032b}'.format(int(regs.value()[ 55]))[22:27]
l12_tts_tap_delay_7              = '{0:032b}'.format(int(regs.value()[ 55]))[17:22]
l12_tts_tap_delay_8              = '{0:032b}'.format(int(regs.value()[ 55]))[12:17]
l8_tts_tap_delay_1               = '{0:032b}'.format(int(regs.value()[ 56]))[27:32]
l8_tts_tap_delay_2               = '{0:032b}'.format(int(regs.value()[ 56]))[22:27]
l8_tts_tap_delay_3               = '{0:032b}'.format(int(regs.value()[ 56]))[17:22]
l8_tts_tap_delay_4               = '{0:032b}'.format(int(regs.value()[ 56]))[12:17]
l8_tts_tap_delay_5               = '{0:032b}'.format(int(regs.value()[ 57]))[27:32]
l8_tts_tap_delay_6               = '{0:032b}'.format(int(regs.value()[ 57]))[22:27]
l8_tts_tap_delay_7               = '{0:032b}'.format(int(regs.value()[ 57]))[17:22]
l8_tts_tap_delay_8               = '{0:032b}'.format(int(regs.value()[ 57]))[12:17]
sfp_l12_sn0_1                    = '{0:032b}'.format(int(regs.value()[ 64]))[ 0:32]
sfp_l12_sn0_2                    = '{0:032b}'.format(int(regs.value()[ 65]))[ 0:32]
sfp_l12_sn0_3                    = '{0:032b}'.format(int(regs.value()[ 66]))[ 0:32]
sfp_l12_sn0_4                    = '{0:032b}'.format(int(regs.value()[ 67]))[ 0:32]
sfp_l12_sn1_1                    = '{0:032b}'.format(int(regs.value()[ 68]))[ 0:32]
sfp_l12_sn1_2                    = '{0:032b}'.format(int(regs.value()[ 69]))[ 0:32]
sfp_l12_sn1_3                    = '{0:032b}'.format(int(regs.value()[ 70]))[ 0:32]
sfp_l12_sn1_4                    = '{0:032b}'.format(int(regs.value()[ 71]))[ 0:32]
sfp_l12_sn2_1                    = '{0:032b}'.format(int(regs.value()[ 72]))[ 0:32]
sfp_l12_sn2_2                    = '{0:032b}'.format(int(regs.value()[ 73]))[ 0:32]
sfp_l12_sn2_3                    = '{0:032b}'.format(int(regs.value()[ 74]))[ 0:32]
sfp_l12_sn2_4                    = '{0:032b}'.format(int(regs.value()[ 75]))[ 0:32]
sfp_l12_sn3_1                    = '{0:032b}'.format(int(regs.value()[ 76]))[ 0:32]
sfp_l12_sn3_2                    = '{0:032b}'.format(int(regs.value()[ 77]))[ 0:32]
sfp_l12_sn3_3                    = '{0:032b}'.format(int(regs.value()[ 78]))[ 0:32]
sfp_l12_sn3_4                    = '{0:032b}'.format(int(regs.value()[ 79]))[ 0:32]
sfp_l12_sn4_1                    = '{0:032b}'.format(int(regs.value()[ 80]))[ 0:32]
sfp_l12_sn4_2                    = '{0:032b}'.format(int(regs.value()[ 81]))[ 0:32]
sfp_l12_sn4_3                    = '{0:032b}'.format(int(regs.value()[ 82]))[ 0:32]
sfp_l12_sn4_4                    = '{0:032b}'.format(int(regs.value()[ 83]))[ 0:32]
sfp_l12_sn5_1                    = '{0:032b}'.format(int(regs.value()[ 84]))[ 0:32]
sfp_l12_sn5_2                    = '{0:032b}'.format(int(regs.value()[ 85]))[ 0:32]
sfp_l12_sn5_3                    = '{0:032b}'.format(int(regs.value()[ 86]))[ 0:32]
sfp_l12_sn5_4                    = '{0:032b}'.format(int(regs.value()[ 87]))[ 0:32]
sfp_l12_sn6_1                    = '{0:032b}'.format(int(regs.value()[ 88]))[ 0:32]
sfp_l12_sn6_2                    = '{0:032b}'.format(int(regs.value()[ 89]))[ 0:32]
sfp_l12_sn6_3                    = '{0:032b}'.format(int(regs.value()[ 90]))[ 0:32]
sfp_l12_sn6_4                    = '{0:032b}'.format(int(regs.value()[ 91]))[ 0:32]
sfp_l12_sn7_1                    = '{0:032b}'.format(int(regs.value()[ 92]))[ 0:32]
sfp_l12_sn7_2                    = '{0:032b}'.format(int(regs.value()[ 93]))[ 0:32]
sfp_l12_sn7_3                    = '{0:032b}'.format(int(regs.value()[ 94]))[ 0:32]
sfp_l12_sn7_4                    = '{0:032b}'.format(int(regs.value()[ 95]))[ 0:32]
sfp_l8_sn0_1                     = '{0:032b}'.format(int(regs.value()[ 96]))[ 0:32]
sfp_l8_sn0_2                     = '{0:032b}'.format(int(regs.value()[ 97]))[ 0:32]
sfp_l8_sn0_3                     = '{0:032b}'.format(int(regs.value()[ 98]))[ 0:32]
sfp_l8_sn0_4                     = '{0:032b}'.format(int(regs.value()[ 99]))[ 0:32]
sfp_l8_sn1_1                     = '{0:032b}'.format(int(regs.value()[100]))[ 0:32]
sfp_l8_sn1_2                     = '{0:032b}'.format(int(regs.value()[101]))[ 0:32]
sfp_l8_sn1_3                     = '{0:032b}'.format(int(regs.value()[102]))[ 0:32]
sfp_l8_sn1_4                     = '{0:032b}'.format(int(regs.value()[103]))[ 0:32]
sfp_l8_sn2_1                     = '{0:032b}'.format(int(regs.value()[104]))[ 0:32]
sfp_l8_sn2_2                     = '{0:032b}'.format(int(regs.value()[105]))[ 0:32]
sfp_l8_sn2_3                     = '{0:032b}'.format(int(regs.value()[106]))[ 0:32]
sfp_l8_sn2_4                     = '{0:032b}'.format(int(regs.value()[107]))[ 0:32]
sfp_l8_sn3_1                     = '{0:032b}'.format(int(regs.value()[108]))[ 0:32]
sfp_l8_sn3_2                     = '{0:032b}'.format(int(regs.value()[109]))[ 0:32]
sfp_l8_sn3_3                     = '{0:032b}'.format(int(regs.value()[110]))[ 0:32]
sfp_l8_sn3_4                     = '{0:032b}'.format(int(regs.value()[111]))[ 0:32]
sfp_l8_sn4_1                     = '{0:032b}'.format(int(regs.value()[112]))[ 0:32]
sfp_l8_sn4_2                     = '{0:032b}'.format(int(regs.value()[113]))[ 0:32]
sfp_l8_sn4_3                     = '{0:032b}'.format(int(regs.value()[114]))[ 0:32]
sfp_l8_sn4_4                     = '{0:032b}'.format(int(regs.value()[115]))[ 0:32]
sfp_l8_sn5_1                     = '{0:032b}'.format(int(regs.value()[116]))[ 0:32]
sfp_l8_sn5_2                     = '{0:032b}'.format(int(regs.value()[117]))[ 0:32]
sfp_l8_sn5_3                     = '{0:032b}'.format(int(regs.value()[118]))[ 0:32]
sfp_l8_sn5_4                     = '{0:032b}'.format(int(regs.value()[119]))[ 0:32]
sfp_l8_sn6_1                     = '{0:032b}'.format(int(regs.value()[120]))[ 0:32]
sfp_l8_sn6_2                     = '{0:032b}'.format(int(regs.value()[121]))[ 0:32]
sfp_l8_sn6_3                     = '{0:032b}'.format(int(regs.value()[122]))[ 0:32]
sfp_l8_sn6_4                     = '{0:032b}'.format(int(regs.value()[123]))[ 0:32]
sfp_l8_sn7_1                     = '{0:032b}'.format(int(regs.value()[124]))[ 0:32]
sfp_l8_sn7_2                     = '{0:032b}'.format(int(regs.value()[125]))[ 0:32]
sfp_l8_sn7_3                     = '{0:032b}'.format(int(regs.value()[126]))[ 0:32]
sfp_l8_sn7_4                     = '{0:032b}'.format(int(regs.value()[127]))[ 0:32]
trig_type_num0                   = '{0:032b}'.format(int(regs.value()[128]))[ 8:32]
trig_type_num1                   = '{0:032b}'.format(int(regs.value()[129]))[ 8:32]
trig_type_num2                   = '{0:032b}'.format(int(regs.value()[130]))[ 8:32]
trig_type_num3                   = '{0:032b}'.format(int(regs.value()[131]))[ 8:32]
trig_type_num4                   = '{0:032b}'.format(int(regs.value()[132]))[ 8:32]
trig_type_num5                   = '{0:032b}'.format(int(regs.value()[133]))[ 8:32]
trig_type_num6                   = '{0:032b}'.format(int(regs.value()[134]))[ 8:32]
trig_type_num7                   = '{0:032b}'.format(int(regs.value()[135]))[ 8:32]
trig_type_num8                   = '{0:032b}'.format(int(regs.value()[136]))[ 8:32]
trig_type_num9                   = '{0:032b}'.format(int(regs.value()[137]))[ 8:32]
trig_type_num10                  = '{0:032b}'.format(int(regs.value()[138]))[ 8:32]
trig_type_num11                  = '{0:032b}'.format(int(regs.value()[139]))[ 8:32]
trig_type_num12                  = '{0:032b}'.format(int(regs.value()[140]))[ 8:32]
trig_type_num13                  = '{0:032b}'.format(int(regs.value()[141]))[ 8:32]
trig_type_num14                  = '{0:032b}'.format(int(regs.value()[142]))[ 8:32]
trig_type_num15                  = '{0:032b}'.format(int(regs.value()[143]))[ 8:32]
trig_type_num16                  = '{0:032b}'.format(int(regs.value()[144]))[ 8:32]
trig_type_num17                  = '{0:032b}'.format(int(regs.value()[145]))[ 8:32]
trig_type_num18                  = '{0:032b}'.format(int(regs.value()[146]))[ 8:32]
trig_type_num19                  = '{0:032b}'.format(int(regs.value()[147]))[ 8:32]
trig_type_num20                  = '{0:032b}'.format(int(regs.value()[148]))[ 8:32]
trig_type_num21                  = '{0:032b}'.format(int(regs.value()[149]))[ 8:32]
trig_type_num22                  = '{0:032b}'.format(int(regs.value()[150]))[ 8:32]
trig_type_num23                  = '{0:032b}'.format(int(regs.value()[151]))[ 8:32]
trig_type_num24                  = '{0:032b}'.format(int(regs.value()[152]))[ 8:32]
trig_type_num25                  = '{0:032b}'.format(int(regs.value()[153]))[ 8:32]
trig_type_num26                  = '{0:032b}'.format(int(regs.value()[154]))[ 8:32]
trig_type_num27                  = '{0:032b}'.format(int(regs.value()[155]))[ 8:32]
trig_type_num28                  = '{0:032b}'.format(int(regs.value()[156]))[ 8:32]
trig_type_num29                  = '{0:032b}'.format(int(regs.value()[157]))[ 8:32]
trig_type_num30                  = '{0:032b}'.format(int(regs.value()[158]))[ 8:32]
trig_type_num31                  = '{0:032b}'.format(int(regs.value()[159]))[ 8:32]
aborted_cycles                   = '{0:032b}'.format(int(regs.value()[195]))[ 0:32]
next_up_state                    = '{0:032b}'.format(int(regs.value()[202]))[14:32]
# raw registers
def DUMP_REGS():
    print('')
    print(GRAY+"Register   Value                           "+RESET)
    for i in range(209):
    	print("%03d        " % (int(i))+BLUE+str('{0:032b}'.format(int(regs.value()[i])))+RESET)
    print('')
    print('')

# firmware signals
def DUMP_VARS():
    print('')
    print(GRAY+"Firmware Signal                    B/D/H/A   Value                            "+RESET)    
    print('patch_rev                        : H         '+BLUE+str(('%x' % int(patch_rev,2)).zfill(2))+RESET)
    print('minor_rev                        : H         '+BLUE+str(('%x' % int(minor_rev,2)).zfill(2))+RESET)
    print('major_rev                        : H         '+BLUE+str(('%x' % int(major_rev,2)).zfill(2))+RESET)
    print('board_type                       : B         '+BLUE+board_type+RESET)
    print('board_id                         : D         '+BLUE+str(int(board_id,2)-90)+RESET)
    print('l12_fmc_id                       : H         '+BLUE+str(('%x' % int(l12_fmc_id,2)).zfill(2))+RESET)
    print('l8_fmc_id                        : H         '+BLUE+str(('%x' % int(l8_fmc_id,2)).zfill(2))+RESET)
    print('ttc_clk_lock                     : D         '+BLUE+ttc_clk_lock+RESET)
    print('ext_clk_lock                     : D         '+BLUE+ext_clk_lock+RESET)
    print('ttc_ready                        : D         '+BLUE+ttc_ready+RESET)
    print('l12_tts_lock_mux                 : D         '+BLUE+l12_tts_lock_mux+RESET)
    print('l8_tts_lock_mux                  : D         '+BLUE+l8_tts_lock_mux+RESET)
    print('fmcs_ready                       : D         '+BLUE+fmcs_ready+RESET)
    print('fmc_eeprom_error_i2c             : D         '+BLUE+fmc_eeprom_error_i2c+RESET)
    print('fmc_eeprom_error_id              : D         '+BLUE+fmc_eeprom_error_id+RESET)
    print('fmc_ids_valid                    : D         '+BLUE+fmc_ids_valid+RESET)
    print('async_enable_sent                : D         '+BLUE+async_enable_sent+RESET)
    print('measured_temp                    : D         '+BLUE+str('%.2f' % (int(measured_temp,2)*503.975/4096.0-273.15))+' '+u'\N{DEGREE SIGN}'+'C'+RESET)
    print('measured_vccint                  : D         '+BLUE+str('%.2f' % (int(measured_vccint,2)/4096.0*3.0))+' V'+RESET)
    print('measured_vccaux                  : D         '+BLUE+str('%.2f' % (int(measured_vccaux,2)/4096.0*3.0))+' V'+RESET)
    print('measured_vccbram                 : D         '+BLUE+str('%.2f' % (int(measured_vccbram,2)/4096.0*3.0))+' V'+RESET)
    print('over_temp                        : D         '+BLUE+over_temp+RESET)
    print('alarm_temp                       : D         '+BLUE+alarm_temp+RESET)
    print('alarm_vccint                     : D         '+BLUE+alarm_vccint+RESET)
    print('alarm_vccaux                     : D         '+BLUE+alarm_vccaux+RESET)
    print('alarm_vccbram                    : D         '+BLUE+alarm_vccbram+RESET)
    print('l12_eeprom_reg_out               : H         '+BLUE+str(('%x' % int(l12_eeprom_reg_out4+l12_eeprom_reg_out3+l12_eeprom_reg_out2+l12_eeprom_reg_out1,2)).zfill(32))+RESET)
    print('l8_eeprom_reg_out                : H         '+BLUE+str(('%x' % int(l8_eeprom_reg_out4+l8_eeprom_reg_out3+l8_eeprom_reg_out2+l8_eeprom_reg_out1,2)).zfill(32))+RESET)
    print('error_l12_fmc_absent             : D         '+BLUE+error_l12_fmc_absent+RESET)
    print('error_l12_fmc_mod_type           : D         '+BLUE+error_l12_fmc_mod_type+RESET)
    print('error_l12_fmc_int_n              : D         '+BLUE+error_l12_fmc_int_n+RESET)
    print('error_l12_startup_i2c            : D         '+BLUE+error_l12_startup_i2c+RESET)
    print('sfp_en_error_l12_mod_abs         : B         '+BLUE+sfp_en_error_l12_mod_abs+RESET)
    print('sfp_en_error_l12_sfp_type        : B         '+BLUE+sfp_en_error_l12_sfp_type+RESET)
    print('sfp_en_error_l12_tx_fault        : B         '+BLUE+sfp_en_error_l12_tx_fault+RESET)
    print('sfp_en_error_l12_sfp_alarms      : B         '+BLUE+sfp_en_error_l12_sfp_alarms+RESET)
    print('error_l8_fmc_absent              : D         '+BLUE+error_l8_fmc_absent+RESET)
    print('error_l8_fmc_mod_type            : D         '+BLUE+error_l8_fmc_mod_type+RESET)
    print('error_l8_fmc_int_n               : D         '+BLUE+error_l8_fmc_int_n+RESET)
    print('error_l8_startup_i2c             : D         '+BLUE+error_l8_startup_i2c+RESET)
    print('sfp_en_error_l8_mod_abs          : B         '+BLUE+sfp_en_error_l8_mod_abs+RESET)
    print('sfp_en_error_l8_sfp_type         : B         '+BLUE+sfp_en_error_l8_sfp_type+RESET)
    print('sfp_en_error_l8_tx_fault         : B         '+BLUE+sfp_en_error_l8_tx_fault+RESET)
    print('sfp_en_error_l8_sfp_alarms       : B         '+BLUE+sfp_en_error_l8_sfp_alarms+RESET)
    print('sfp_en_alarm_l12_temp_high       : B         '+BLUE+sfp_en_alarm_l12_temp_high+RESET)
    print('sfp_en_alarm_l12_temp_low        : B         '+BLUE+sfp_en_alarm_l12_temp_low+RESET)
    print('sfp_en_alarm_l12_vcc_high        : B         '+BLUE+sfp_en_alarm_l12_vcc_high+RESET)
    print('sfp_en_alarm_l12_vcc_low         : B         '+BLUE+sfp_en_alarm_l12_vcc_low+RESET)
    print('sfp_en_alarm_l12_tx_bias_high    : B         '+BLUE+sfp_en_alarm_l12_tx_bias_high+RESET)
    print('sfp_en_alarm_l12_tx_bias_low     : B         '+BLUE+sfp_en_alarm_l12_tx_bias_low+RESET)
    print('sfp_en_alarm_l12_tx_power_high   : B         '+BLUE+sfp_en_alarm_l12_tx_power_high+RESET)
    print('sfp_en_alarm_l12_tx_power_low    : B         '+BLUE+sfp_en_alarm_l12_tx_power_low+RESET)
    print('sfp_en_alarm_l12_rx_power_high   : B         '+BLUE+sfp_en_alarm_l12_rx_power_high+RESET)
    print('sfp_en_alarm_l12_rx_power_low    : B         '+BLUE+sfp_en_alarm_l12_rx_power_low+RESET)
    print('sfp_en_alarm_l8_temp_high        : B         '+BLUE+sfp_en_alarm_l8_temp_high+RESET)
    print('sfp_en_alarm_l8_temp_low         : B         '+BLUE+sfp_en_alarm_l8_temp_low+RESET)
    print('sfp_en_alarm_l8_vcc_high         : B         '+BLUE+sfp_en_alarm_l8_vcc_high+RESET)
    print('sfp_en_alarm_l8_vcc_low          : B         '+BLUE+sfp_en_alarm_l8_vcc_low+RESET)
    print('sfp_en_alarm_l8_tx_bias_high     : B         '+BLUE+sfp_en_alarm_l8_tx_bias_high+RESET)
    print('sfp_en_alarm_l8_tx_bias_low      : B         '+BLUE+sfp_en_alarm_l8_tx_bias_low+RESET)
    print('sfp_en_alarm_l8_tx_power_high    : B         '+BLUE+sfp_en_alarm_l8_tx_power_high+RESET)
    print('sfp_en_alarm_l8_tx_power_low     : B         '+BLUE+sfp_en_alarm_l8_tx_power_low+RESET)
    print('sfp_en_alarm_l8_rx_power_high    : B         '+BLUE+sfp_en_alarm_l8_rx_power_high+RESET)
    print('sfp_en_alarm_l8_rx_power_low     : B         '+BLUE+sfp_en_alarm_l8_rx_power_low+RESET)
    print('sfp_en_warning_l12_temp_high     : B         '+BLUE+sfp_en_warning_l12_temp_high+RESET)
    print('sfp_en_warning_l12_temp_low      : B         '+BLUE+sfp_en_warning_l12_temp_low+RESET)
    print('sfp_en_warning_l12_vcc_high      : B         '+BLUE+sfp_en_warning_l12_vcc_high+RESET)
    print('sfp_en_warning_l12_vcc_low       : B         '+BLUE+sfp_en_warning_l12_vcc_low+RESET)
    print('sfp_en_warning_l12_tx_bias_high  : B         '+BLUE+sfp_en_warning_l12_tx_bias_high+RESET)
    print('sfp_en_warning_l12_tx_bias_low   : B         '+BLUE+sfp_en_warning_l12_tx_bias_low+RESET)
    print('sfp_en_warning_l12_tx_power_high : B         '+BLUE+sfp_en_warning_l12_tx_power_high+RESET)
    print('sfp_en_warning_l12_tx_power_low  : B         '+BLUE+sfp_en_warning_l12_tx_power_low+RESET)
    print('sfp_en_warning_l12_rx_power_high : B         '+BLUE+sfp_en_warning_l12_rx_power_high+RESET)
    print('sfp_en_warning_l12_rx_power_low  : B         '+BLUE+sfp_en_warning_l12_rx_power_low+RESET)
    print('sfp_en_warning_l8_temp_high      : B         '+BLUE+sfp_en_warning_l8_temp_high+RESET)
    print('sfp_en_warning_l8_temp_low       : B         '+BLUE+sfp_en_warning_l8_temp_low+RESET)
    print('sfp_en_warning_l8_vcc_high       : B         '+BLUE+sfp_en_warning_l8_vcc_high+RESET)
    print('sfp_en_warning_l8_vcc_low        : B         '+BLUE+sfp_en_warning_l8_vcc_low+RESET)
    print('sfp_en_warning_l8_tx_bias_high   : B         '+BLUE+sfp_en_warning_l8_tx_bias_high+RESET)
    print('sfp_en_warning_l8_tx_bias_low    : B         '+BLUE+sfp_en_warning_l8_tx_bias_low+RESET)
    print('sfp_en_warning_l8_tx_power_high  : B         '+BLUE+sfp_en_warning_l8_tx_power_high+RESET)
    print('sfp_en_warning_l8_tx_power_low   : B         '+BLUE+sfp_en_warning_l8_tx_power_low+RESET)
    print('sfp_en_warning_l8_rx_power_high  : B         '+BLUE+sfp_en_warning_l8_rx_power_high+RESET)
    print('sfp_en_warning_l8_rx_power_low   : B         '+BLUE+sfp_en_warning_l8_rx_power_low+RESET)
    print('sfp_l12_enabled_ports            : B         '+BLUE+sfp_l12_enabled_ports+RESET)
    print('sfp_l8_enabled_ports             : B         '+BLUE+sfp_l8_enabled_ports+RESET)
    print('sfp_l12_mod_abs                  : B         '+BLUE+sfp_l12_mod_abs+RESET)
    print('change_l12_mod_abs               : B         '+BLUE+change_l12_mod_abs+RESET)
    print('change_error_l12_mod_abs         : B         '+BLUE+change_error_l12_mod_abs+RESET)
    print('sfp_l8_mod_abs                   : B         '+BLUE+sfp_l8_mod_abs+RESET)
    print('change_l8_mod_abs                : B         '+BLUE+change_l8_mod_abs+RESET)
    print('change_error_l8_mod_abs          : B         '+BLUE+change_error_l8_mod_abs+RESET)
    print('sfp_l12_tx_fault                 : B         '+BLUE+sfp_l12_tx_fault+RESET)
    print('change_l12_tx_fault              : B         '+BLUE+change_l12_tx_fault+RESET)
    print('change_error_l12_tx_fault        : B         '+BLUE+change_error_l12_tx_fault+RESET)
    print('sfp_l8_tx_fault                  : B         '+BLUE+sfp_l8_tx_fault+RESET)
    print('change_l8_tx_fault               : B         '+BLUE+change_l8_tx_fault+RESET)
    print('change_error_l8_tx_fault         : B         '+BLUE+change_error_l8_tx_fault+RESET)
    print('sfp_l12_rx_los                   : B         '+BLUE+sfp_l12_rx_los+RESET)
    print('change_l12_rx_los                : B         '+BLUE+change_l12_rx_los+RESET)
    print('change_error_l12_rx_los          : B         '+BLUE+change_error_l12_rx_los+RESET)
    print('sfp_l8_rx_los                    : B         '+BLUE+sfp_l8_rx_los+RESET)
    print('change_l8_rx_los                 : B         '+BLUE+change_l8_rx_los+RESET)
    print('change_error_l8_rx_los           : B         '+BLUE+change_error_l8_rx_los+RESET)
    print('l12_tts_lock                     : B         '+BLUE+l12_tts_lock+RESET)
    print('l8_tts_lock                      : B         '+BLUE+l8_tts_lock+RESET)
    print('l12_tts_state                    : B         '+BLUE+l12_tts_state+RESET)
    print('l8_tts_state                     : B         '+BLUE+l8_tts_state+RESET)
    print('system_status                    : B         '+BLUE+system_status+RESET)
    print('local_tts_state                  : B         '+BLUE+local_tts_state+RESET)
    print('l12_tts_status                   : B         '+BLUE+l12_tts_status+RESET)
    print('l8_tts_status                    : B         '+BLUE+l8_tts_status+RESET)
    print('ts_state                         : B         '+BLUE+ts_state2+ts_state1+RESET)
    print('eb_state                         : B         '+BLUE+eb_state2+eb_state1+RESET)
    print('tis_state                        : B         '+BLUE+tis_state+RESET)
    print('l12_fs_state                     : B         '+BLUE+l12_fs_state+RESET)
    print('l12_st_state                     : B         '+BLUE+l12_st_state1+l12_st_state2+RESET)
    print('l8_fs_state                      : B         '+BLUE+l8_fs_state+RESET)
    print('l8_st_state                      : B         '+BLUE+l8_st_state1+l8_st_state2+RESET)
    print('l12_ssc_state                    : B         '+BLUE+l12_ssc_state+RESET)
    print('l8_ssc_state                     : B         '+BLUE+l8_ssc_state+RESET)
    print('l12_sgr_state                    : B         '+BLUE+l12_sgr_state+RESET)
    print('l8_sgr_state                     : B         '+BLUE+l8_sgr_state+RESET)
    print('fe_state                         : B         '+BLUE+fe_state+RESET)
    print('run_in_progress                  : D         '+BLUE+run_in_progress+RESET)
    print('doing_run_checks                 : D         '+BLUE+doing_run_checks+RESET)
    print('resetting_clients                : D         '+BLUE+resetting_clients+RESET)
    print('finding_cycle_start              : D         '+BLUE+finding_cycle_start+RESET)
    print('run_aborted                      : D         '+BLUE+run_aborted+RESET)
    print('trig_index                       : D         '+BLUE+str(int(trig_index,2))+RESET)
    print('trig_sub_index                   : D         '+BLUE+str(int(trig_sub_index,2))+RESET)
    print('trig_num                         : D         '+BLUE+str(int(trig_num,2))+RESET)
    print('trig_timestamp                   : D         '+BLUE+str(int(trig_timestamp2+trig_timestamp1,2))+RESET)
    print('ttc_sbit_error_cnt               : D         '+BLUE+str(int(ttc_sbit_error_cnt,2))+RESET)
    print('ttc_mbit_error_cnt               : D         '+BLUE+str(int(ttc_mbit_error_cnt,2))+RESET)
    print('error_ttc_sbit_limit             : D         '+BLUE+error_ttc_sbit_limit+RESET)
    print('error_ttc_mbit_limit             : D         '+BLUE+error_ttc_mbit_limit+RESET)
    print('ofw_trig_count_running           : D         '+BLUE+str(int(ofw_trig_count_running,2))+RESET)
    print('ofw_trig_count                   : D         '+BLUE+str(int(ofw_trig_count,2))+RESET)
    print('ofw_limit_reached                : D         '+BLUE+ofw_limit_reached+RESET)
    print('l12_tts_tap_delay_1              : D         '+BLUE+l12_tts_tap_delay_1+RESET)
    print('l12_tts_tap_delay_2              : D         '+BLUE+l12_tts_tap_delay_2+RESET)
    print('l12_tts_tap_delay_3              : D         '+BLUE+l12_tts_tap_delay_3+RESET)
    print('l12_tts_tap_delay_4              : D         '+BLUE+l12_tts_tap_delay_4+RESET)
    print('l12_tts_tap_delay_5              : D         '+BLUE+l12_tts_tap_delay_5+RESET)
    print('l12_tts_tap_delay_6              : D         '+BLUE+l12_tts_tap_delay_6+RESET)
    print('l12_tts_tap_delay_7              : D         '+BLUE+l12_tts_tap_delay_7+RESET)
    print('l12_tts_tap_delay_8              : D         '+BLUE+l12_tts_tap_delay_8+RESET)
    print('l8_tts_tap_delay_1               : D         '+BLUE+l8_tts_tap_delay_1+RESET)
    print('l8_tts_tap_delay_2               : D         '+BLUE+l8_tts_tap_delay_2+RESET)
    print('l8_tts_tap_delay_3               : D         '+BLUE+l8_tts_tap_delay_3+RESET)
    print('l8_tts_tap_delay_4               : D         '+BLUE+l8_tts_tap_delay_4+RESET)
    print('l8_tts_tap_delay_5               : D         '+BLUE+l8_tts_tap_delay_5+RESET)
    print('l8_tts_tap_delay_6               : D         '+BLUE+l8_tts_tap_delay_6+RESET)
    print('l8_tts_tap_delay_7               : D         '+BLUE+l8_tts_tap_delay_7+RESET)
    print('l8_tts_tap_delay_8               : D         '+BLUE+l8_tts_tap_delay_8+RESET)
    print('sfp_l12_sn0                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn0_4+sfp_l12_sn0_3+sfp_l12_sn0_2+sfp_l12_sn0_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn1                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn1_4+sfp_l12_sn1_3+sfp_l12_sn1_2+sfp_l12_sn1_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn2                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn2_4+sfp_l12_sn2_3+sfp_l12_sn2_2+sfp_l12_sn2_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn3                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn3_4+sfp_l12_sn3_3+sfp_l12_sn3_2+sfp_l12_sn3_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn4                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn4_4+sfp_l12_sn4_3+sfp_l12_sn4_2+sfp_l12_sn4_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn5                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn5_4+sfp_l12_sn5_3+sfp_l12_sn5_2+sfp_l12_sn5_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn6                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn6_4+sfp_l12_sn6_3+sfp_l12_sn6_2+sfp_l12_sn6_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l12_sn7                      : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l12_sn7_4+sfp_l12_sn7_3+sfp_l12_sn7_2+sfp_l12_sn7_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn0                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn0_4+sfp_l8_sn0_3+sfp_l8_sn0_2+sfp_l8_sn0_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn1                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn1_4+sfp_l8_sn1_3+sfp_l8_sn1_2+sfp_l8_sn1_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn2                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn2_4+sfp_l8_sn2_3+sfp_l8_sn2_2+sfp_l8_sn2_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn3                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn3_4+sfp_l8_sn3_3+sfp_l8_sn3_2+sfp_l8_sn3_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn4                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn4_4+sfp_l8_sn4_3+sfp_l8_sn4_2+sfp_l8_sn4_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn5                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn5_4+sfp_l8_sn5_3+sfp_l8_sn5_2+sfp_l8_sn5_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn6                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn6_4+sfp_l8_sn6_3+sfp_l8_sn6_2+sfp_l8_sn6_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('sfp_l8_sn7                       : A         '+BLUE+(binascii.unhexlify( ('%x' % int(sfp_l8_sn7_4+sfp_l8_sn7_3+sfp_l8_sn7_2+sfp_l8_sn7_1,2)).zfill(8)).decode("utf-8") )+RESET)
    print('trig_type_num0                   : D         '+BLUE+str(int(trig_type_num0,2))+RESET)
    print('trig_type_num1                   : D         '+BLUE+str(int(trig_type_num1,2))+RESET)
    print('trig_type_num2                   : D         '+BLUE+str(int(trig_type_num2,2))+RESET)
    print('trig_type_num3                   : D         '+BLUE+str(int(trig_type_num3,2))+RESET)
    print('trig_type_num4                   : D         '+BLUE+str(int(trig_type_num4,2))+RESET)
    print('trig_type_num5                   : D         '+BLUE+str(int(trig_type_num5,2))+RESET)
    print('trig_type_num6                   : D         '+BLUE+str(int(trig_type_num6,2))+RESET)
    print('trig_type_num7                   : D         '+BLUE+str(int(trig_type_num7,2))+RESET)
    print('trig_type_num8                   : D         '+BLUE+str(int(trig_type_num8,2))+RESET)
    print('trig_type_num9                   : D         '+BLUE+str(int(trig_type_num9,2))+RESET)
    print('trig_type_num10                  : D         '+BLUE+str(int(trig_type_num10,2))+RESET)
    print('trig_type_num11                  : D         '+BLUE+str(int(trig_type_num11,2))+RESET)
    print('trig_type_num12                  : D         '+BLUE+str(int(trig_type_num12,2))+RESET)
    print('trig_type_num13                  : D         '+BLUE+str(int(trig_type_num13,2))+RESET)
    print('trig_type_num14                  : D         '+BLUE+str(int(trig_type_num14,2))+RESET)
    print('trig_type_num15                  : D         '+BLUE+str(int(trig_type_num15,2))+RESET)
    print('trig_type_num16                  : D         '+BLUE+str(int(trig_type_num16,2))+RESET)
    print('trig_type_num17                  : D         '+BLUE+str(int(trig_type_num17,2))+RESET)
    print('trig_type_num18                  : D         '+BLUE+str(int(trig_type_num18,2))+RESET)
    print('trig_type_num19                  : D         '+BLUE+str(int(trig_type_num19,2))+RESET)
    print('trig_type_num20                  : D         '+BLUE+str(int(trig_type_num20,2))+RESET)
    print('trig_type_num21                  : D         '+BLUE+str(int(trig_type_num21,2))+RESET)
    print('trig_type_num22                  : D         '+BLUE+str(int(trig_type_num22,2))+RESET)
    print('trig_type_num23                  : D         '+BLUE+str(int(trig_type_num23,2))+RESET)
    print('trig_type_num24                  : D         '+BLUE+str(int(trig_type_num24,2))+RESET)
    print('trig_type_num25                  : D         '+BLUE+str(int(trig_type_num25,2))+RESET)
    print('trig_type_num26                  : D         '+BLUE+str(int(trig_type_num26,2))+RESET)
    print('trig_type_num27                  : D         '+BLUE+str(int(trig_type_num27,2))+RESET)
    print('trig_type_num28                  : D         '+BLUE+str(int(trig_type_num28,2))+RESET)
    print('trig_type_num29                  : D         '+BLUE+str(int(trig_type_num29,2))+RESET)
    print('trig_type_num30                  : D         '+BLUE+str(int(trig_type_num30,2))+RESET)
    print('trig_type_num31                  : D         '+BLUE+str(int(trig_type_num31,2))+RESET)
    print('aborted_cycles                   : D         '+BLUE+str(int(aborted_cycles,2))+RESET)
    print('next_up_state                    : D         '+BLUE+next_up_state+RESET)
    print('')
    print('')

# parse argument options
if len(sys.argv)==3:
    DUMP_REGS()
elif sys.argv[3]=='expert' or sys.argv[3]=='e':
    DUMP_VARS()
