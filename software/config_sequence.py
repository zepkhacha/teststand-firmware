# Encoder FC7 sequencer configuration script
# Usage: python config_sequence.py [crate] [slot] [sequence] [trigger] [options]

import uhal, sys, getopt, ctypes
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python config_sequence.py [crate] [slot] [sequence] [trigger] [options]'
    print ''
    print 'options:'
    print '  -h       : show this help menu and exit'
    print '  -c COUNT : number of triggers in that sequence'
    print '  -t TYPE  : trigger type for that trigger, in binary'
    print '  -g GAP   : pre-trigger gap for that trigger'

# check number of arguments
if len(sys.argv)<6:
    HELP_MENU()
    sys.exit(2)

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[5:],"hc:t:g:")
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

    # trigger count
    elif opt in ("-c"):
        fc7.getNode("SEQ"+sys.argv[3]+".COUNT").write(int(arg)-1)
        fc7.dispatch()

    # trigger type
    elif opt in ("-t"):
        fc7.getNode("SEQ"+sys.argv[3]+".TRIG.TYPE"+sys.argv[4]).write(int(arg,2))
        fc7.dispatch()

    # pre-trigger gap
    elif opt in ("-g"):
        fc7.getNode("SEQ"+sys.argv[3]+".PRE.TRIG.GAP"+sys.argv[4]).write(int(arg))
        fc7.dispatch()
