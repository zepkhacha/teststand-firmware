# Trigger FC7 channel status script
# Usage: python read_triggers.py [crate] [slot] [channel]

import uhal, sys
uhal.disableLogging()

# check number of arguments
if len(sys.argv)!=4:
    print 'usage: python read_triggers.py [crate] [slot] [channel]'
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# parse arguments
crate = sys.argv[1]
slot = sys.argv[2]
channel = sys.argv[3]

# colors
GRAY  = "\033[47;30m"
BLUE  = "\033[0;34m"
RESET = "\033[m\017"

for sequence in range(0, 16):
    # print header
    print ''
    print GRAY+"Channel   Sequence   Trigger   Delay      Width   Enabled "+RESET

    for pulse in range(0, 4):
        # read trigger registers
        DELAY0 = fc7.getNode("DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP0.PULSE"+str(int(pulse))).read()
        DELAY1 = fc7.getNode("DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP1.PULSE"+str(int(pulse))).read()
        DELAY2 = fc7.getNode("DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP2.PULSE"+str(int(pulse))).read()
        DELAY3 = fc7.getNode("DELAY.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP3.PULSE"+str(int(pulse))).read()
        fc7.dispatch()
        WIDTH0 = fc7.getNode("WIDTH.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP0.PULSE"+str(int(pulse))).read()
        WIDTH1 = fc7.getNode("WIDTH.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".LOOP1.PULSE"+str(int(pulse))).read()
        ENABLE = fc7.getNode("WIDTH.CHAN"+str(int(channel))+".SEQ"+str(int(sequence))+".ENABLE.PULSE"+str(int(pulse))).read()
        fc7.dispatch()

        delay = (int(DELAY3.value()) << 18) + (int(DELAY2.value()) << 12) + (int(DELAY1.value()) << 6) + int(DELAY0.value())
        width = (int(WIDTH1.value()) <<  4) +  int(WIDTH0.value())

        # print configuration
        print "%02d        %02d         %01d         " % (int(channel), int(sequence), int(pulse))+\
              BLUE+"%s   %s   %s" % (str(delay).ljust(8), str(width).ljust(8), str(int(ENABLE.value())).ljust(8))+RESET

print ''
print ''
