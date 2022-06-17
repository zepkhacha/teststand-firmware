# trigger FC7 internal triggering configuration script
# Usage: python config_general.py [crate] [slot] [options]

import uhal, sys, getopt, ctypes, time
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python config_triggering.py [crate] [slot] [options]'
    print ''
    print 'options:'
    print '  -h        : show this help menu and exit'
    print '  -e MODE   : enable fallback to internal trigger (on, off)'
    print '  -f MODE   : force internal trigger (on, off)' 
    print '  -i MODE   : use boc generated from internal trigger (on, off)' 
    print '  -a MODE   : enable T9x to A6 skew correction (on, off)'
    print '  -r        : reset the t9x to A6 running skew correction calculation'
    print '  -d DELAY  : internal trigger delay (in 25 ns ticks) bewteen internal T93 (or T94) and first A6 signal.'
    print '              Doubles as the parameter to which the T9x/A6 skew correction corrects.'
    print '  -m COUNT  : maximum allowed measured T9x to A6 time (in 25 ns counts) used in the running skew correction'
    print '  -p PERIOD : period for the 8-fill cycle (nominally 10 ms).  In 25 ns ticks'
    print '  -g DELAY  : The delay (or gap) between the last A6 of the first 8-fill cycle and the T4 initiating the second'
    print '  -s PERIOD : supercycle period (nominally 1.4 s)'
    print '  -t COUNT  : threshold after which to declare A6 missing (nominally 7 seconds = 5 supercycles)'
    
# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[3:],"hre:f:i:a:d:m:p:g:s:t:")
except getopt.GetoptError:
    HELP_MENU()
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

for opt, arg in opts:
    # help menu
    if opt in ("-h"):
        HELP_MENU()
        sys.exit()

    # reset
    elif opt in ("-r"):
            fc7.getNode("RESET.T9.CORR").write(1)
            fc7.dispatch()
            fc7.getNode("RESET.T9.CORR").write(0)
            fc7.dispatch()
            time.sleep(2)
            print 'T9x to A6 clock skew correction reset to zero.'

    # run mode
    elif opt in ("-e"):
        if arg=='on':
            fc7.getNode("ENABLE.ITRIG").write(1)
            fc7.dispatch()
            print 'Fallback to internal triggering has been enabled.'
        elif arg=='off':
            fc7.getNode("ENABLE.ITRIG").write(0)
            fc7.dispatch()
            print 'Fallback to internal triggering has been disabled.'

    elif opt in ("-f"):
        if arg=='on':
            fc7.getNode("FORCE.ITRIG").write(1)
            fc7.dispatch()
            print 'Internal triggering override enabled. (WARNING: Real accelerator signals ignored!)'
        elif arg=='off':
            fc7.getNode("FORCE.ITRIG").write(0)
            fc7.dispatch()
            print 'Internal triggering override disabled.'

    elif opt in ("-i"):
        if arg=='on':
            fc7.getNode("INTERNAL.BOC").write(1)
            fc7.dispatch()
            print 'Begin-of-supercycle signal from internal triggering enabled. (WARNING: Encoder boc ignored!)'
        elif arg=='off':
            fc7.getNode("INTERNAL.BOC").write(0)
            fc7.dispatch()
            print 'Begin-of-supercycle signal from internal triggering disabled.'

    elif opt in ("-a"):
        if arg=='on':
            fc7.getNode("ENABLE.T9.ADJUST").write(1)
            fc7.dispatch()
            print 'T9x to A6 running clock skew correction enabled'
        elif arg=='off':
            fc7.getNode("ENABLE.T9.ADJUST").write(0)
            fc7.dispatch()
            print 'T9x to A6 running clock skew correction disabled.'

    # THe delay from the T93 or T94 signal to the first A6: Exact in internal triggering, value corrected to with accel signals
    elif opt in ("-d"):
        fc7.getNode("IDEAL.T9.A6.GAP").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'T9x to A6 ideal delay set.'

    # Maximum allowed measured T9x to A6 delay to be used in running skew correction
    elif opt in ("-m"):
        fc7.getNode("MAX.T9.A6.GAP").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'Maximum allowed T9x to A6 delay set.'

    # 8-fill cycle period
    elif opt in ("-p"):
        fc7.getNode("EIGHT.FILL.PERIOD").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'Internal trigger: period between fills in the 8-fill cycle set.'

    # time between last A6 of first cycle and T94 of second cycle
    elif opt in ("-g"):
        fc7.getNode("CYCLE.GAP").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'Internal trigger: time between last A6 of first cycle and T94 of second cycle is set.'

    # SUPERCYCLE.PERIOD
    elif opt in ("-s"):
        fc7.getNode("SUPERCYCLE.PERIOD").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'Internal trigger: supercycle period set.'

    # A6 missing threshold for internal trigger fallback
    elif opt in ("-t"):
        fc7.getNode("ITRIG.THRESHOLD").write(ctypes.c_uint32(int(arg,0)).value)
        fc7.dispatch()
        print 'Length of time with no A6 triggers to fallback to internal triggering set.'

