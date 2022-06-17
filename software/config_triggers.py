# Trigger FC7 pulse train configuration script
# Usage: python config_triggers.py [crate] [slot] [channel] [sequence] [pulse] [options]

import uhal, sys, getopt, ctypes
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python config_triggers.py [crate] [slot] [channel] [sequence] [pulse] [options]'
    print ''
    print 'options:'
    print '  -h       : show this help menu and exit'
    print '  -d DELAY : trigger pulse delay, in clock ticks'
    print '  -w WIDTH : trigger pulse width, in clock ticks'

# check number of arguments
if len(sys.argv)<7:
    HELP_MENU()
    sys.exit(2)

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[6:],"hd:w:")
except getopt.GetoptError:
    HELP_MENU()
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

for opt, arg in opts:
    # help menu
    if opt == '-h':
        HELP_MENU()
        sys.exit()

    # trigger pulse delay
    elif opt in ("-d"):
        loop0 =  int(arg,0)        & 0x3F
        loop1 = (int(arg,0) >>  6) & 0x3F
        loop2 = (int(arg,0) >> 12) & 0x3F
        loop3 = (int(arg,0) >> 18) & 0x3F
        fc7.getNode("DELAY.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP0.PULSE"+sys.argv[5]).write(loop0)
        fc7.getNode("DELAY.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP1.PULSE"+sys.argv[5]).write(loop1)
        fc7.getNode("DELAY.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP2.PULSE"+sys.argv[5]).write(loop2)
        fc7.getNode("DELAY.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP3.PULSE"+sys.argv[5]).write(loop3)
        fc7.dispatch()

    # trigger pulse width
    elif opt in ("-w"):
        loop0 =  int(arg,0)       & 0xF
        loop1 = (int(arg,0) >> 4) & 0xF
        enable = 0 if int(arg,0) == 0 else 1
        fc7.getNode("WIDTH.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP0.PULSE"+sys.argv[5]).write(loop0)
        fc7.getNode("WIDTH.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".LOOP1.PULSE"+sys.argv[5]).write(loop1)
        fc7.getNode("WIDTH.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]+".ENABLE.PULSE"+sys.argv[5]).write(enable)
        fc7.dispatch()
