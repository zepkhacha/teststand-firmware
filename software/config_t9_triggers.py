# Trigger FC7 pulsing based on
# Usage: python config_triggers.py [crate] [slot] [channel] [sequence] [pulse] [options]

import uhal, sys, getopt, ctypes
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage 1: python config_t9_triggers.py [crate] [slot] [options]'
    print 'usage 2: python config_t9_triggers.py [crate] [slot] [channel] [sequence] [delay]'
    print ''
    print 'options:'
    print '  -h       : show this help menu and exit'
    print '  -e MASK  : enabled channel bit mask -- one bit per channel'
    print '  -w WIDTH : trigger pulse width, in clock ticks'

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# common fc7 uhal setup
uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# version 2 of command: set a delay for one channel/sequence
if len(sys.argv) == 6:
    fc7.getNode("T9.DELAY.CHAN"+sys.argv[3]+".SEQ"+sys.argv[4]).write(int(sys.argv[5],0))
    print "Setting trigger delay for T9-based channel #" + sys.argv[3] + " fill #" + sys.argv[4] + " to " + sys.argv[5]

else: 
    # parse argument options
    try:
        opts, args = getopt.getopt(sys.argv[3:],"he:w:")
    except getopt.GetoptError:
        HELP_MENU()
        sys.exit(2)


    for opt, arg in opts:
        # help menu
        if opt == '-h':
            HELP_MENU()
            sys.exit()
    
        # trigger pulse delay
        elif opt in ("-e"):
            fc7.getNode("T9.CHANNELS.ENABLED").write(int(arg,0))
            print 'Enabled T9-based trigger channels using mask  "' + arg + '"'
    
        # trigger pulse width
        elif opt in ("-w"):
            fc7.getNode("T9.CHANNELS.PULSE.WIDTH").write(int(arg,0))
            print 'Settin width of T9-based trigger channels to ' + arg

# get it done
fc7.dispatch()
