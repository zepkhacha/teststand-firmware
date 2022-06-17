# FC7 control status script
# Usage: python read_controls.py [crate] [slot]

import uhal, sys
uhal.disableLogging()

# check number of arguments
if len(sys.argv)!=3:
    print ('usage: python read_controls.py [crate] [slot]')
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# read control registers
SYSTEM_HARD_RESET    = fc7.getNode("SYSTEM.HARD_RESET"   ).read()
SYSTEM_SOFT_RESET    = fc7.getNode("SYSTEM.SOFT_RESET"   ).read()
SYSTEM_RUN_ENABLE    = fc7.getNode("SYSTEM.RUN_ENABLE"   ).read()
SYSTEM_RUN_PAUSE     = fc7.getNode("SYSTEM.RUN_PAUSE"    ).read()
SYSTEM_RUN_ABORT     = fc7.getNode("SYSTEM.RUN_ABORT"    ).read()
SYSTEM_FPGA_REPROG   = fc7.getNode("SYSTEM.FPGA_REPROG"  ).read()
SEND_OFW_BOC         = fc7.getNode("SEND_OFW_BOC"        ).read()
TTS_MASK_L08         = fc7.getNode("TTS_MASK_L08"        ).read()
TTS_MASK_L12         = fc7.getNode("TTS_MASK_L12"        ).read()
TTC_TRIG_WIDTH       = fc7.getNode("TTC_TRIG_WIDTH"      ).read()
SEQ_COUNT            = fc7.getNode("SEQ_COUNT"           ).read()
OFW_THRES            = fc7.getNode("OFW_THRES"           ).read()
CYCLE_THRES          = fc7.getNode("CYCLE_THRES"         ).read()
TTS_LOCK_THRES       = fc7.getNode("TTS_LOCK_THRES"      ).read()
TTS_LOCK_MISMATCH    = fc7.getNode("TTS_LOCK_MISMATCH"   ).read()
TTS_RX_TAP_MANUAL    = fc7.getNode("TTS_RX.TAP_MANUAL"   ).read()
TTS_RX_TAP_STROBE    = fc7.getNode("TTS_RX.TAP_STROBE"   ).read()
TTS_RX_TAP_DELAY     = fc7.getNode("TTS_RX.TAP_DELAY"    ).read()
TTS_RX_REALIGN       = fc7.getNode("TTS_RX.REALIGN"      ).read()
TTS_RX_RESET_L12     = fc7.getNode("TTS_RX.RESET_L12"    ).read()
TTS_RX_RESET_L08     = fc7.getNode("TTS_RX.RESET_L08"    ).read()
I2C_CHANNEL          = fc7.getNode("I2C.CHANNEL"         ).read()
I2C_EEPROM_MAP       = fc7.getNode("I2C.EEPROM_MAP"      ).read()
I2C_EEPROM_ADR       = fc7.getNode("I2C.EEPROM_ADR"      ).read()
I2C_EEPROM_NUM       = fc7.getNode("I2C.EEPROM_NUM"      ).read()
I2C_READ_L12         = fc7.getNode("I2C.READ_L12"        ).read()
I2C_READ_L08         = fc7.getNode("I2C.READ_L08"        ).read()
I2C_RESET_L12        = fc7.getNode("I2C.RESET_L12"       ).read()
I2C_RESET_L08        = fc7.getNode("I2C.RESET_L08"       ).read()
SFP_REQUEST_L12      = fc7.getNode("SFP.REQUEST_L12"     ).read()
SFP_REQUEST_L08      = fc7.getNode("SFP.REQUEST_L08"     ).read()
SFP_ENABLE_L12       = fc7.getNode("SFP.ENABLE_L12"      ).read()
SFP_ENABLE_L08       = fc7.getNode("SFP.ENABLE_L08"      ).read()
FMC_ID_REQUEST_L12   = fc7.getNode("FMC_ID.REQUEST_L12"  ).read()
FMC_ID_REQUEST_L08   = fc7.getNode("FMC_ID.REQUEST_L08"  ).read()
FMC_ID_WRITE         = fc7.getNode("FMC_ID.WRITE"        ).read()
TTC_DELAY0_L12       = fc7.getNode("TTC.DELAY0_L12"      ).read()
TTC_DELAY1_L12       = fc7.getNode("TTC.DELAY1_L12"      ).read()
TTC_DELAY2_L12       = fc7.getNode("TTC.DELAY2_L12"      ).read()
TTC_DELAY3_L12       = fc7.getNode("TTC.DELAY3_L12"      ).read()
TTC_DELAY4_L12       = fc7.getNode("TTC.DELAY4_L12"      ).read()
TTC_DELAY5_L12       = fc7.getNode("TTC.DELAY5_L12"      ).read()
TTC_DELAY6_L12       = fc7.getNode("TTC.DELAY6_L12"      ).read()
TTC_DELAY7_L12       = fc7.getNode("TTC.DELAY7_L12"      ).read()
TTC_DELAY0_L08       = fc7.getNode("TTC.DELAY0_L08"      ).read()
TTC_DELAY1_L08       = fc7.getNode("TTC.DELAY1_L08"      ).read()
TTC_DELAY2_L08       = fc7.getNode("TTC.DELAY2_L08"      ).read()
TTC_DELAY3_L08       = fc7.getNode("TTC.DELAY3_L08"      ).read()
TTC_DELAY4_L08       = fc7.getNode("TTC.DELAY4_L08"      ).read()
TTC_DELAY5_L08       = fc7.getNode("TTC.DELAY5_L08"      ).read()
TTC_DELAY6_L08       = fc7.getNode("TTC.DELAY6_L08"      ).read()
TTC_DELAY7_L08       = fc7.getNode("TTC.DELAY7_L08"      ).read()
TTC_SBIT_THRES       = fc7.getNode("TTC_SBIT_THRES"      ).read()
TTC_MBIT_THRES       = fc7.getNode("TTC_MBIT_THRES"      ).read()
OTRIG_WIDTH_A        = fc7.getNode("OTRIG_WIDTH_A"       ).read()
OTRIG_WIDTH_B        = fc7.getNode("OTRIG_WIDTH_B"       ).read()
TTC_DECODER_RST      = fc7.getNode("TTC_DECODER_RST"     ).read()
ASYNC_STORAGE_EN     = fc7.getNode("ASYNC_STORAGE_EN"    ).read()
EOR_ASYNC_WAIT       = fc7.getNode("EOR_ASYNC_WAIT"      ).read()
OTRIG_DISABLE_A      = fc7.getNode("OTRIG_DISABLE_A"     ).read()
OTRIG_DISABLE_B      = fc7.getNode("OTRIG_DISABLE_B"     ).read()
TRX_LEMO_SEL         = fc7.getNode("TRX_LEMO_SEL"        ).read()
POST_RST_TN_DELAY    = fc7.getNode("POST_RST_TN_DELAY"   ).read()
POST_RST_TS_DELAY    = fc7.getNode("POST_RST_TS_DELAY"   ).read()
OTRIG_DELAY_A        = fc7.getNode("OTRIG_DELAY_A"       ).read()
OTRIG_DELAY_B        = fc7.getNode("OTRIG_DELAY_B"       ).read()
TTC_TRIG_DELAY       = fc7.getNode("TTC_TRIG_DELAY"      ).read()
IDEAL_T9_A6_GAP      = fc7.getNode("IDEAL_T9_A6_GAP"     ).read()
EIGHT_FILL_PERIOD    = fc7.getNode("EIGHT_FILL_PERIOD"   ).read()
CYCLE_GAP            = fc7.getNode("CYCLE_GAP"           ).read()
SUPERCYCLE_PERIOD    = fc7.getNode("SUPERCYCLE_PERIOD"   ).read()
ITRIG_THRESHOLD      = fc7.getNode("ITRIG_THRESHOLD"     ).read()
ENABLE_ITRIG         = fc7.getNode("ENABLE_ITRIG"        ).read()
FORCE_ITRIG          = fc7.getNode("FORCE_ITRIG"         ).read()
ENABLE_T9_ADJUST     = fc7.getNode("ENABLE_T9_ADJUST"    ).read()
RESET_T9_CORR        = fc7.getNode("RESET_T9_CORR"       ).read()
MAX_T9_A6_GAP        = fc7.getNode("MAX_T9_A6_GAP"       ).read()
CYCLE_SIZE_TOGGLE    = fc7.getNode("CYCLE_SIZE_TOGGLE"   ).read()
LASER_PRESCALE       = fc7.getNode("LASER_PRESCALE"      ).read()
LASER_TRIG_ALWAYS    = fc7.getNode("LASER_TRIG_ALWAYS"   ).read()
QUAD_T9_DELAY        = fc7.getNode("QUAD_T9_DELAY"       ).read()
QUAD_T9_WIDTH        = fc7.getNode("QUAD_T9_WIDTH"       ).read()
QUAD_T9_ENABLE       = fc7.getNode("QUAD_T9_ENABLE"      ).read()
QUAD_A6_ENABLE       = fc7.getNode("QUAD_A6_ENABLE"      ).read()
TTC_FEOVFLW_ENABLE   = fc7.getNode("TTC.FEOVFLW_ENABLE"  ).read()
NO_BEAM_STRUCTURE    = fc7.getNode("NO_BEAM_STRUCTURE"   ).read()
IGNORE_T9_TRIGS      = fc7.getNode("IGNORE_T9_TRIGS"     ).read()
ASYNC_START_DELAY    = fc7.getNode("ASYNC_START_DELAY"   ).read()
DEBUG1               = fc7.getNode("DEBUG1"              ).read()
DEBUG2               = fc7.getNode("DEBUG2"              ).read()
DEBUG3               = fc7.getNode("DEBUG3"              ).read()
DEBUG4               = fc7.getNode("DEBUG4"              ).read()
fc7.dispatch()

print ('SYSTEM.HARD.RESET    :   '+              str(int( SYSTEM_HARD_RESET   .value() )))
print ('SYSTEM.SOFT.RESET    :   '+              str(int( SYSTEM_SOFT_RESET   .value() )))
print ('SYSTEM.RUN.ENABLE    :   '+              str(int( SYSTEM_RUN_ENABLE   .value() )))
print ('SYSTEM.RUN.PAUSE     :   '+              str(int( SYSTEM_RUN_PAUSE    .value() )))
print ('SYSTEM.RUN.ABORT     :   '+              str(int( SYSTEM_RUN_ABORT    .value() )))
print ('SYSTEM.FPGA.REPROG   :   '+              str(int( SYSTEM_FPGA_REPROG  .value() )))
print ('SEND.OFW.BOC         :   '+              str(int( SEND_OFW_BOC        .value() )))
print ('TTS.MASK.L08         :   '+              str(int( TTS_MASK_L08        .value() )))
print ('TTS.MASK.L12         :   '+              str(int( TTS_MASK_L12        .value() )))
print ('TTC.TRIG.WIDTH       :   '+              str(int( TTC_TRIG_WIDTH      .value() )))
print ('SEQ.COUNT            :   '+              str(int( SEQ_COUNT           .value() )))
print ('OFW.THRES            :   '+              str(int( OFW_THRES           .value() )))
print ('CYCLE.THRES          :   '+              str(int( CYCLE_THRES         .value() )))
print ('TTS.LOCK.THRES       :   '+              str(int( TTS_LOCK_THRES      .value() )))
print ('TTS.LOCK.MISMATCH    :   '+              str(int( TTS_LOCK_MISMATCH   .value() )))
print ('TTS.RX.TAP.MANUAL    :   '+              str(int( TTS_RX_TAP_MANUAL   .value() )))
print ('TTS.RX.TAP.STROBE    :   '+              str(int( TTS_RX_TAP_STROBE   .value() )))
print ('TTS.RX.TAP.DELAY     :   '+              str(int( TTS_RX_TAP_DELAY    .value() )))
print ('TTS.RX.REALIGN       :   '+              str(int( TTS_RX_REALIGN      .value() )))
print ('TTS.RX.RESET.L12     :   '+              str(int( TTS_RX_RESET_L12    .value() )))
print ('TTS.RX.RESET.L08     :   '+              str(int( TTS_RX_RESET_L08    .value() )))
print ('I2C.CHANNEL          : b '+'{0:008b}'.format(int( I2C_CHANNEL         .value() )))
print ('I2C.EEPROM.MAP       :   '+              str(int( I2C_EEPROM_MAP      .value() )))
print ('I2C.EEPROM.ADR       :   '+              str(int( I2C_EEPROM_ADR      .value() )))
print ('I2C.EEPROM.NUM       :   '+              str(int( I2C_EEPROM_NUM      .value() )))
print ('I2C.READ.L12         :   '+              str(int( I2C_READ_L12        .value() )))
print ('I2C.READ.L08         :   '+              str(int( I2C_READ_L08        .value() )))
print ('I2C.RESET.L12        :   '+              str(int( I2C_RESET_L12       .value() )))
print ('I2C.RESET.L08        :   '+              str(int( I2C_RESET_L08       .value() )))
print ('SFP.REQUEST.L12      : b '+'{0:008b}'.format(int( SFP_REQUEST_L12     .value() )))
print ('SFP.REQUEST.L08      : b '+'{0:008b}'.format(int( SFP_REQUEST_L08     .value() )))
print ('SFP.ENABLE.L12       :   '+              str(int( SFP_ENABLE_L12      .value() )))
print ('SFP.ENABLE.L08       :   '+              str(int( SFP_ENABLE_L08      .value() )))
print ('FMC.ID.REQUEST.L12   : b '+'{0:002x}'.format(int( FMC_ID_REQUEST_L12  .value() )))
print ('FMC.ID.REQUEST.L08   : b '+'{0:002x}'.format(int( FMC_ID_REQUEST_L08  .value() )))
print ('FMC.ID.WRITE         :   '+              str(int( FMC_ID_WRITE        .value() )))
print ('TTC.DELAY0.L12       :   '+              str(int( TTC_DELAY0_L12      .value() )))
print ('TTC.DELAY1.L12       :   '+              str(int( TTC_DELAY1_L12      .value() )))
print ('TTC.DELAY2.L12       :   '+              str(int( TTC_DELAY2_L12      .value() )))
print ('TTC.DELAY3.L12       :   '+              str(int( TTC_DELAY3_L12      .value() )))
print ('TTC.DELAY4.L12       :   '+              str(int( TTC_DELAY4_L12      .value() )))
print ('TTC.DELAY5.L12       :   '+              str(int( TTC_DELAY5_L12      .value() )))
print ('TTC.DELAY6.L12       :   '+              str(int( TTC_DELAY6_L12      .value() )))
print ('TTC.DELAY7.L12       :   '+              str(int( TTC_DELAY7_L12      .value() )))
print ('TTC.DELAY0.L08       :   '+              str(int( TTC_DELAY0_L08      .value() )))
print ('TTC.DELAY1.L08       :   '+              str(int( TTC_DELAY1_L08      .value() )))
print ('TTC.DELAY2.L08       :   '+              str(int( TTC_DELAY2_L08      .value() )))
print ('TTC.DELAY3.L08       :   '+              str(int( TTC_DELAY3_L08      .value() )))
print ('TTC.DELAY4.L08       :   '+              str(int( TTC_DELAY4_L08      .value() )))
print ('TTC.DELAY5.L08       :   '+              str(int( TTC_DELAY5_L08      .value() )))
print ('TTC.DELAY6.L08       :   '+              str(int( TTC_DELAY6_L08      .value() )))
print ('TTC.DELAY7.L08       :   '+              str(int( TTC_DELAY7_L08      .value() )))
print ('TTC.SBIT.THRES       :   '+              str(int( TTC_SBIT_THRES      .value() )))
print ('TTC.MBIT.THRES       :   '+              str(int( TTC_MBIT_THRES      .value() )))
print ('OTRIG.WIDTH.A        :   '+              str(int( OTRIG_WIDTH_A       .value() )))
print ('OTRIG.WIDTH.B        :   '+              str(int( OTRIG_WIDTH_B       .value() )))
print ('TTC.DECODER.RST      :   '+              str(int( TTC_DECODER_RST     .value() )))
print ('ASYNC.STORAGE.EN     :   '+              str(int( ASYNC_STORAGE_EN    .value() )))
print ('EOR.ASYNC.WAIT       :   '+              str(int( EOR_ASYNC_WAIT      .value() )))
print ('OTRIG.DISABLE.A      : b '+'{0:032b}'.format(int( OTRIG_DISABLE_A     .value() )))
print ('OTRIG.DISABLE.B      : b '+'{0:032b}'.format(int( OTRIG_DISABLE_B     .value() )))
print ('TRX.LEMO.SEL         :   '+              str(int( TRX_LEMO_SEL        .value() )))
print ('POST.RST.TN.DELAY    :   '+              str(int( POST_RST_TN_DELAY   .value() )))
print ('POST.RST.TS.DELAY    :   '+              str(int( POST_RST_TS_DELAY   .value() )))
print ('OTRIG.DELAY.A        :   '+              str(int( OTRIG_DELAY_A       .value() )))
print ('OTRIG.DELAY.B        :   '+              str(int( OTRIG_DELAY_B       .value() )))
print ('TTC.TRIG.DELAY       :   '+              str(int( TTC_TRIG_DELAY      .value() )))
print ('IDEAL.T9.A6.GAP      :   '+              str(int( IDEAL_T9_A6_GAP     .value() )))
print ('EIGHT.FILL.PERIOD    :   '+              str(int( EIGHT_FILL_PERIOD   .value() )))
print ('CYCLE.GAP            :   '+              str(int( CYCLE_GAP           .value() )))
print ('SUPERCYCLE.PERIOD    :   '+              str(int( SUPERCYCLE_PERIOD   .value() )))
print ('ITRIG.THRESHOLD      :   '+              str(int( ITRIG_THRESHOLD     .value() )))
print ('ENABLE.ITRIG         :   '+              str(int( ENABLE_ITRIG        .value() )))
print ('FORCE.ITRIG          :   '+              str(int( FORCE_ITRIG         .value() )))
print ('ENABLE.T9.ADJUST     :   '+              str(int( ENABLE_T9_ADJUST    .value() )))
print ('RESET.T9.CORR        :   '+              str(int( RESET_T9_CORR       .value() )))
print ('MAX.T9.A6.GAP        :   '+              str(int( MAX_T9_A6_GAP       .value() )))
print ('CYCLE.SIZE.TOGGLE    :   '+              str(int( CYCLE_SIZE_TOGGLE   .value() )))
print ('LASER.PRESCALE       :   '+              str(int( LASER_PRESCALE      .value() )))
print ('LASER.PRESCALE       :   '+              str(int( LASER_PRESCALE      .value() )))
print ('LASER.TRIG.ALWAYS    :   '+              str(int( LASER_TRIG_ALWAYS   .value() )))
print ('QUAD_T9_DELAY        :   '+              str(int(QUAD_T9_DELAY        .value() )))
print ('QUAD_T9_WIDTH        :   '+              str(int(QUAD_T9_WIDTH        .value() )))
print ('QUAD_T9_ENABLE       :   '+              str(int(QUAD_T9_ENABLE       .value() )))
print ('QUAD_A6_ENABLE       :   '+              str(int(QUAD_A6_ENABLE       .value() )))
print ('TTC_FEOVFLW_ENABLE   :   '+              str(int(TTC_FEOVFLW_ENABLE   .value() )))
print ('ASYNC_START_DELAY    :   '+              str(int(ASYNC_START_DELAY    .value() )))
print ('NO_BEAM_STRUCTURE    :   '+              str(int(NO_BEAM_STRUCTURE    .value() )))
print ('IGNORE_T9_TRIGS      :   '+              str(int(IGNORE_T9_TRIGS      .value() )))
print ('ASYNC_START_DELAY    :   '+              str(int(ASYNC_START_DELAY    .value() )))
print ('DEBUG1               :   '+              str(int(DEBUG1               .value() )))
print ('DEBUG2               :   '+              str(int(DEBUG2               .value() )))
print ('DEBUG3               :   '+              str(int(DEBUG3               .value() )))
print ('DEBUG4               :   '+              str(int(DEBUG4               .value() )))
