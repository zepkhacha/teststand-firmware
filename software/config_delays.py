# FC7 TTC output delay configuration script
# Usage: python config_delays.py [crate] [slot] [fmc] [options]

import uhal, sys, getopt, ctypes
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python config_delays.py [crate] [slot] [fmc] [options]'
    print ''
    print 'options:'
    print '  -h       : show this help menu and exit'
    print '  -a DELAY : TTC output delay for SFP 1'
    print '  -b DELAY : TTC output delay for SFP 2'
    print '  -c DELAY : TTC output delay for SFP 3'
    print '  -d DELAY : TTC output delay for SFP 4'
    print '  -e DELAY : TTC output delay for SFP 5'
    print '  -f DELAY : TTC output delay for SFP 6'
    print '  -g DELAY : TTC output delay for SFP 7'
    print '  -h DELAY : TTC output delay for SFP 8'

# check number of arguments
if len(sys.argv)<5:
    HELP_MENU()
    sys.exit(2)

if   sys.argv[3]=='L12': fmc = 'L12'
elif sys.argv[3]=='L8' : fmc = 'L08'

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[3:],"ha:b:c:d:e:f:g:h:")
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

    # TTC output delay for SFP 1
    elif opt in ("-a"):
        fc7.getNode("TTC.DELAY0."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 1.'

    # TTC output delay for SFP 2
    elif opt in ("-b"):
        fc7.getNode("TTC.DELAY1."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 2.'

    # TTC output delay for SFP 3
    elif opt in ("-c"):
        fc7.getNode("TTC.DELAY2."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 3.'

    # TTC output delay for SFP 4
    elif opt in ("-d"):
        fc7.getNode("TTC.DELAY3."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 4.'

    # TTC output delay for SFP 5
    elif opt in ("-e"):
        fc7.getNode("TTC.DELAY4."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 5.'

    # TTC output delay for SFP 6
    elif opt in ("-f"):
        fc7.getNode("TTC.DELAY5."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 6.'

    # TTC output delay for SFP 7
    elif opt in ("-g"):
        fc7.getNode("TTC.DELAY6."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 7.'

    # TTC output delay for SFP 8
    elif opt in ("-h"):
        fc7.getNode("TTC.DELAY7."+fmc).write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print 'TTC output delay set for SFP 8.'
