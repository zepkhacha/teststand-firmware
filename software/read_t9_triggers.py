# Trigger FC7 channel status script
# Usage: python read_triggers.py [crate] [slot] [channel]

import uhal, sys
uhal.disableLogging()

# check number of arguments
if len(sys.argv)!=3:
    print 'usage: python read_t9_triggers.py [crate] [slot]'
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# parse arguments
crate = sys.argv[1]
slot = sys.argv[2]

T9_CHANNELS_ENABLED     = fc7.getNode("T9.CHANNELS.ENABLED"     ).read()
T9_CHANNELS_PULSE_WIDTH = fc7.getNode("T9.CHANNELS.PULSE.WIDTH" ).read()
fc7.dispatch()

print ''
print 'T9.CHANNELS.ENABLED     :   '+              str(int( T9_CHANNELS_ENABLED    .value() ))
print 'T9.CHANNELS.PULSE.WIDTH :   '+              str(int( T9_CHANNELS_PULSE_WIDTH.value() ))




# colors
GRAY  = "\033[47;30m"
BLUE  = "\033[0;34m"
RESET = "\033[m\017"

for channel in range(4):
    # print header
    print ''
    print GRAY+"Channel   Sequence   Delay      Sequence   Delay"+RESET

    for sequence in range(8):
        sequence8 = sequence + 8
        # read trigger registers
        DELAY  = fc7.getNode("T9.DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence ))).read()
        DELAY8 = fc7.getNode("T9.DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence8))).read()
        fc7.dispatch()

        # print configuration
        print "%02d        %02d         " % (int(channel), int(sequence))+\
              BLUE+"%s" % (str(DELAY.value()).ljust(8))+RESET+"   "\
                  "%02d         " % (int(sequence8))+\
              BLUE+"%s" % (str(DELAY8.value()).ljust(8))+RESET
print ''
print ''
