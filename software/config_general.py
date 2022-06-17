# FC7 general configuration script
# Usage: python config_general.py [crate] [slot] [options]

import uhal, sys, getopt, ctypes, time
uhal.disableLogging()

# help menu
def HELP_MENU():
    print ('usage: python config_general.py [crate] [slot] [options]')
    print ('')
    print ('options:')
    print ('  -h       : show this help menu and exit')
    print ('  -r TYPE  : reset the firmware logic (hard, soft)')
    print ('  -m MODE  : run mode (start, stop, pause, resume, abort)')
    print ('  -c COUNT : TTC trigger sequencer count')
    print ('  -w COUNT : overflow warning threshold, in super-cycles')
    print ('  -s COUNT : super-cycle start threshold')
    print ('  -t COUNT : TTS lock threshold')
    print ('  -u COUNT : TTS lock mismatch allowed')
    print ('  -a SLOTS : requested L12 SFP slots to enable')
    print ('  -b SLOTS : requested L08 SFP slots to enable')
    print ('  -e FMC   : enable requested SFP slots (L08, L12)')
    print ('  -x COUNT : TTC single-bit error threshold')
    print ('  -y COUNT : TTC multi-bit error threshold')
    print ('  -d MODE  : WFD5 asynchronous storage mode (on, off)')
    print ('  -f DELAY : post-trigger number reset delay')
    print ('  -g DELAY : post-timestamp reset delay')
    print ('  -i WIDTH : analog TTC trigger output width')
    print ('  -j DELAY : analog TTC trigger output delay')
    print ('  -p COUNT : prescale factor for laser prescaled trigger channel')
    print ('  -q TOGGLE: toggle between (0) 8 fills / supercycle,  and (1) 16 fills / supercycle')

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[3:],"hr:m:c:w:s:t:u:a:b:e:x:y:d:f:g:i:j:p:q:")
except getopt.GetoptError:
    HELP_MENU()
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

for opt, arg in opts:
    # help menu
    if opt in ("-h"):
        HELP_MENU()
        sys.exit()

    # reset
    elif opt in ("-r"):
        if arg=='hard':
            fc7.getNode("SYSTEM.HARD.RESET").write(1)
            fc7.dispatch()
            time.sleep(2)
            print ('System hard reset issued.')
        elif arg=='soft':
            fc7.getNode("SYSTEM.SOFT.RESET").write(1)
            fc7.dispatch()
            fc7.getNode("SYSTEM.SOFT.RESET").write(0)
            fc7.dispatch()
            time.sleep(2)
            print ('System soft reset issued.')

    # run mode
    elif opt in ("-m"):
        if arg=='start':
            fc7.getNode("SYSTEM.RUN_ENABLE").write(1)
            fc7.dispatch()
            print ('Run has started.')
        elif arg=='stop':
            fc7.getNode("SYSTEM.RUN_ABORT").write(0)
            fc7.dispatch()
            fc7.getNode("SYSTEM.RUN_ENABLE").write(0)
            fc7.dispatch()
            print ('Run has stopped.')
        elif arg=='pause':
            fc7.getNode("SYSTEM.RUN_PAUSE").write(1)
            fc7.dispatch()
            print ('Run has paused.')
        elif arg=='resume':
            fc7.getNode("SYSTEM.RUN_PAUSE").write(0)
            fc7.dispatch()
            print ('Run has resumed.')
        elif arg=='abort':
            fc7.getNode("SYSTEM.RUN_ABORT").write(1)
            fc7.dispatch()
            print ('Run has aborted.')

    # TTC trigger sequencer count
    elif opt in ("-c"):
        fc7.getNode("SEQ.COUNT").write(ctypes.c_uint32(int(arg)-1).value)
        fc7.dispatch()
        print ('TTC trigger sequencer count set.')

    # overflow warning threshold, in super-cycles
    elif opt in ("-w"):
        fc7.getNode("OFW.THRES").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Overflow warning threshold set.')

    # super-cycle start threshold
    elif opt in ("-s"):
        fc7.getNode("CYCLE.THRES").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Super-cycle start threshold set.')

    # TTS lock threshold
    elif opt in ("-t"):
        fc7.getNode("TTS.LOCK.THRES").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('TTS lock threshold set.')

    # TTS lock mismatch allowed
    elif opt in ("-u"):
        fc7.getNode("TTS.LOCK.MISMATCH").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('TTS lock mismatch allowed set.')

    # requested L12 SFP slots to enable
    elif opt in ("-a"):
        fc7.getNode("SFP.REQUEST.L12").write(ctypes.c_uint32(int(arg,2)).value)
        fc7.dispatch()
        print ('Enabled top FMC SFP slots have been requested.')

    # requested L08 SFP slots to enable
    elif opt in ("-b"):
        fc7.getNode("SFP.REQUEST.L08").write(ctypes.c_uint32(int(arg,2)).value)
        fc7.dispatch()
        print ('Enabled bottom FMC SFP slots have been requested.')

    # enable requested SFP slots
    elif opt in ("-e"):
        if arg=='L08':
            fc7.getNode("SFP.ENABLE.L08").write(1)
            fc7.dispatch()
            fc7.getNode("SFP.ENABLE.L08").write(0)
            fc7.dispatch()
            time.sleep(1)
            fc7.getNode("TTS.RX.RESET.L08").write(1)
            fc7.dispatch()
            fc7.getNode("TTS.RX.RESET.L08").write(0)
            fc7.dispatch()
            time.sleep(1)
            ports = fc7.getNode("SFP.REQUEST.L08").read()
            fc7.dispatch()
            enabled = bin(int(ports)).count("1")
            time.sleep(2*enabled)
            regs = fc7.getNode("STATUS").readBlock(29)
            fc7.dispatch()
            val = '{0:032b}'.format(int(regs.value()[28]))[16:24]
            print ('Enabled L08 SFP slots : '+val+'.')
        if arg=='L12':
            fc7.getNode("SFP.ENABLE.L12").write(1)
            fc7.dispatch()
            fc7.getNode("SFP.ENABLE.L12").write(0)
            fc7.dispatch()
            time.sleep(1)
            fc7.getNode("TTS.RX.RESET.L12").write(1)
            fc7.dispatch()
            fc7.getNode("TTS.RX.RESET.L12").write(0)
            fc7.dispatch()
            time.sleep(1)
            ports = fc7.getNode("SFP.REQUEST.L12").read()
            fc7.dispatch()
            enabled = bin(int(ports)).count("1")
            time.sleep(2*enabled)
            regs = fc7.getNode("STATUS").readBlock(29)
            fc7.dispatch()
            val = '{0:032b}'.format(int(regs.value()[28]))[24:32]
            print ('Enabled L12 SFP slots : '+val+'.')

    # TTC single-bit error threshold
    elif opt in ("-x"):
        fc7.getNode("TTC.SBIT.THRES").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('TTC single-bit error threshold set.')
        
    # TTC multi-bit error threshold
    elif opt in ("-y"):
        fc7.getNode("TTC.MBIT.THRES").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('TTC multi-bit error threshold set.')

    # WFD5 asynchronous storage mode
    elif opt in ("-d"):
        if arg=='on':
            fc7.getNode("ASYNC.STORAGE.EN").write(1)
            fc7.dispatch()
            print ('WFD5 asynchronous storage mode will be used.')
        elif arg=='off':
            fc7.getNode("ASYNC.STORAGE.EN").write(0)
            fc7.dispatch()
            print ('WFD5 asynchronous storage mode will not be used.')
    
    # post-trigger number reset delay
    elif opt in ("-f"):
        # check range
        if int(arg)<16:
            print ('Post-trigger number reset delay error: out of range:')
            print ('  DELAY:',arg)
            sys.exit(2)
        
        fc7.getNode("POST.RST.TN.DELAY").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Post-trigger number reset delay set.')

    # post-timestamp reset delay
    elif opt in ("-g"):
        # check range
        if int(arg)<16:
            print ('Post-timestamp reset delay error: out of range:')
            print ('  DELAY:',arg)
            sys.exit(2)
        
        fc7.getNode("POST.RST.TS.DELAY").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Post-timestamp reset delay set.')

    # analog TTC trigger output width
    elif opt in ("-i"):
        # check range
        if int(arg)<0 or int(arg)>255:
            print ('Analog TTC trigger output width error: out of range:')
            print ('  WIDTH:',arg)
            sys.exit(2)

        fc7.getNode("TTC.TRIG.WIDTH").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Analog TTC trigger output width set.')

    # analog TTC trigger output delay
    elif opt in ("-j"):
        # check range
        if int(arg)<0 or int(arg)>4294967295:
            print ('Analog TTC trigger output delay error: out of range:')
            print ('  WIDTH:',arg)
            sys.exit(2)

        fc7.getNode("TTC.TRIG.DELAY").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Analog TTC trigger output delay set.')

    # laser prescale factor (channel 9 appears instead of channel 8 every FACTOR cycles)
    elif opt in ("-p"):
        # check range
        if int(arg)<0 or int(arg)>15:
            print ('Channel 14/15 prescale factor error: out of range')
            print ('  FACTOR:',arg)
            sys.exit(2)

        fc7.getNode("LASER.PRESCALE").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('Laser prescale factor set to '+arg)

    # toggle between 8 fills and 16 fills per supercycle
    elif opt in ("-q"):
        # check range
        if int(arg)<0 or int(arg)>1:
            print ('8/16 fill toggle: choice out of range')
            print ('  VALUE:',arg)
            sys.exit(2)

        fc7.getNode("CYCLE_SIZE_TOGGLE").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print ('8/16 Toggle value set to ',arg)
