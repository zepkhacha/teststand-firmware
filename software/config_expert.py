# FC7 expert configuration script
# Usage: python config_expert.py [crate] [slot] [options]

import uhal, sys, getopt, ctypes, time
uhal.disableLogging()

# help menu
def HELP_MENU():
    print( 'usage: python config_expert.py [crate] [slot] [options]')
    print( '')
    print( 'options:')
    print( '  -h       : show this help menu and exit')
    print( '  -t MODE  : TTS manual tap delay mode (on, off)')
    print( '  -d DELAY : TTS tap delay value')
    print( '  -u       : toggle TTS tap delay strobe')
    print( '  -r       : toggle TTS realign setting')
    print( '  -o FMC   : reset TTS receiver logic (L08, L12)')
    print( '  -g       : reset TTC decoder logic')
    print( '  -c CHAN  : transceiver channel select')
    print( '  -m MAP   : transceiver EEPROM map select')
    print( '  -a ADDR  : transceiver EEPROM start address')
    print( '  -n COUNT : transceiver EEPROM register count')
    print( '  -x FMC   : read transceiver EEPROM (L08, L12)')
    print( '  -e FMC   : reset FMC I2C expander chips (L08, L12)')
    print( '  -i ID    : requested L12 FMC ID number, in binary')
    print( '  -j ID    : requested L08 FMC ID number, in binary')
    print( '  -w       : write requested FMC ID numbers')
    print( '  -s DELAY : begin-of-cycle left output trigger delay')
    print( '  -l WIDTH : begin-of-cycle left output trigger width')
    print( '  -f MODE  : begin-of-cycle left output trigger disable (on, off)')
    print( '  -k DELAY : begin-of-cycle right output trigger delay')
    print( '  -p WIDTH : begin-of-cycle right output trigger width')
    print( '  -q MODE  : begin-of-cycle right output trigger disable (on, off)')
    print( '  -b SEL   : input LEMO trigger select (left, right)')
    print( '  -v MODE  : send BOC in overflow state (on, off)')
    print( '  -y COUNT : end-of-run asynchronous readout wait count')
    print( '  -z       : reprogram Kintex-7 FPGA')

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
try:
    opts, args = getopt.getopt(sys.argv[3:],"ht:d:uro:gc:m:a:n:x:e:i:j:ws:l:f:k:p:q:b:v:y:z")
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

    # TTS manual tap delay mode
    elif opt in ("-t"):
        if arg=='on':
            fc7.getNode("TTS.RX.TAP.MANUAL").write(1)
            fc7.dispatch()
            print( 'TTS manual tap delay enabled.')
        elif arg=='off':
            fc7.getNode("TTS.RX.TAP.MANUAL").write(0)
            fc7.dispatch()
            print( 'TTS manual tap delay disabled.')

    # TTS tap delay value
    elif opt in ("-d"):
        fc7.getNode("TTS.RX.TAP.DELAY").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'TTS tap delay value set.')
        
    # toggle TTS tap delay strobe
    elif opt in ("-u"):
        fc7.getNode("TTS.RX.TAP.STROBE").write(1)
        fc7.dispatch()
        fc7.getNode("TTS.RX.TAP.STROBE").write(0)
        fc7.dispatch()
        print( 'TTS tap delay strobe toggled.')

    # toggle TTS realign setting
    elif opt in ("-r"):
        fc7.getNode("TTS.RX.REALIGN").write(1)
        fc7.dispatch()
        fc7.getNode("TTS.RX.REALIGN").write(0)
        fc7.dispatch()
        print( 'TTS realign setting toggled.')
        
    # reset TTS receiver logic
    elif opt in ("-o"):
        if arg=='L08':
            fc7.getNode("TTS.RX.RESET.L08").write(1)
            fc7.dispatch()
            fc7.getNode("TTS.RX.RESET.L08").write(0)
            fc7.dispatch()
            print( 'Reset to L08 TTS receiver logic issued.')
        elif arg=='L12':
            fc7.getNode("TTS.RX.RESET.L12").write(1)
            fc7.dispatch()
            fc7.getNode("TTS.RX.RESET.L12").write(0)
            fc7.dispatch()
            print( 'Reset to L12 TTS receiver logic issued.')
        
    # reset TTC decoder logic
    elif opt in ("-g"):
        fc7.getNode("TTC.DECODER.RST").write(1)
        fc7.dispatch()
        fc7.getNode("TTC.DECODER.RST").write(0)
        fc7.dispatch()
        print( 'Reset to TTC decoder logic issued.')

    # transceiver channel select
    elif opt in ("-c"):
        fc7.getNode("I2C.CHANNEL").write(ctypes.c_uint32(int(arg,2)).value)
        fc7.dispatch()
        print( 'Transceiver channel select set.')
        
    # transceiver EEPROM map select
    elif opt in ("-m"):
        fc7.getNode("I2C.EEPROM.MAP").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Transceiver EEPROM map select set.')
        
    # transceiver EEPROM start address
    elif opt in ("-a"):
        fc7.getNode("I2C.EEPROM.ADR").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Transceiver EEPROM start address set.')
        
    # transceiver EEPROM register count
    elif opt in ("-n"):
        fc7.getNode("I2C.EEPROM.NUM").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Transceiver EEPROM register count set.')
        
    # read transceiver EEPROM
    elif opt in ("-x"):
        if arg=='L08':
            fc7.getNode("I2C.READ.L08").write(1)
            fc7.dispatch()
            fc7.getNode("I2C.READ.L08").write(0)
            fc7.dispatch()
            time.sleep(2)
            regs = fc7.getNode("STATUS").readBlock(14)
            fc7.dispatch()
            val1 = '{0:032b}'.format(int(regs.value()[10]))[0:32]
            val2 = '{0:032b}'.format(int(regs.value()[11]))[0:32]
            val3 = '{0:032b}'.format(int(regs.value()[12]))[0:32]
            val4 = '{0:032b}'.format(int(regs.value()[13]))[0:32]
            print( 'L08 I2C read returned : 0x '+('%x' % int(val4+val3+val2+val1,2)).zfill(32)+'.')
        elif arg=='L12':
            fc7.getNode("I2C.READ.L12").write(1)
            fc7.dispatch()
            fc7.getNode("I2C.READ.L12").write(0)
            fc7.dispatch()
            time.sleep(2)
            regs = fc7.getNode("STATUS").readBlock(14)
            fc7.dispatch()
            val1 = '{0:032b}'.format(int(regs.value()[6]))[0:32]
            val2 = '{0:032b}'.format(int(regs.value()[7]))[0:32]
            val3 = '{0:032b}'.format(int(regs.value()[8]))[0:32]
            val4 = '{0:032b}'.format(int(regs.value()[9]))[0:32]
            print( 'L12 I2C read returned : 0x '+('%x' % int(val4+val3+val2+val1,2)).zfill(32)+'.')
        
    # reset FMC I2C expander chips
    elif opt in ("-e"):
        if arg=='L08':
            fc7.getNode("I2C.RESET.L08").write(1)
            fc7.dispatch()
            fc7.getNode("I2C.RESET.L08").write(0)
            fc7.dispatch()
            print( 'Reset to L08 FMC I2C expander chips issued.')
        elif arg=='L12':
            fc7.getNode("I2C.RESET.L12").write(1)
            fc7.dispatch()
            fc7.getNode("I2C.RESET.L12").write(0)
            fc7.dispatch()
            print( 'Reset to L12 FMC I2C expander chips issued.')
        
    # requested L12 FMC ID number, in binary
    elif opt in ("-i"):
        fc7.getNode("FMC.ID.REQUEST.L12").write(ctypes.c_uint32(int(arg,2)).value)
        fc7.dispatch()
        print( 'Requested L12 FMC ID number set.')
        
    # requested L08 FMC ID number, in binary
    elif opt in ("-j"):
        fc7.getNode("FMC.ID.REQUEST.L08").write(ctypes.c_uint32(int(arg,2)).value)
        fc7.dispatch()
        print( 'Requested L08 FMC ID number set.')
        
    # write requested FMC ID numbers
    elif opt in ("-w"):
        fc7.getNode("FMC.ID.WRITE").write(1)
        fc7.dispatch()
        fc7.getNode("FMC.ID.WRITE").write(0)
        fc7.dispatch()
        print( 'Requested FMC ID numbers written.')

    # begin-of-cycle left output trigger delay
    elif opt in ("-s"):
        fc7.getNode("OTRIG.DELAY.A").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Begin-of-cycle left output trigger delay set.')

    # begin-of-cycle left output trigger width
    elif opt in ("-l"):
        fc7.getNode("OTRIG.WIDTH.A").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Begin-of-cycle left output trigger width set.')

    # begin-of-cycle left output trigger disable
    elif opt in ("-f"):
        if arg=='on':
            fc7.getNode("OTRIG.DISABLE.A").write(0)
            fc7.dispatch()
            print( 'Begin-of-cycle left output trigger enabled.')
        elif arg=='off':
            fc7.getNode("OTRIG.DISABLE.A").write(1)
            fc7.dispatch()
            print( 'Begin-of-cycle left output trigger disabled.')

    # begin-of-cycle right output trigger delay
    elif opt in ("-k"):
        fc7.getNode("OTRIG.DELAY.B").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Begin-of-cycle right output trigger delay set.')

    # begin-of-cycle right output trigger width
    elif opt in ("-p"):
        fc7.getNode("OTRIG.WIDTH.B").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'Begin-of-cycle right output trigger width set.')

    # begin-of-cycle right output trigger disable
    elif opt in ("-q"):
        if arg=='on':
            fc7.getNode("OTRIG.DISABLE.B").write(0)
            fc7.dispatch()
            print( 'Begin-of-cycle right output trigger enabled.')
        elif arg=='off':
            fc7.getNode("OTRIG.DISABLE.B").write(1)
            fc7.dispatch()
            print( 'Begin-of-cycle right output trigger disabled.')

    # input LEMO trigger select
    elif opt in ("-b"):
        if arg=='left':
            fc7.getNode("TRX.LEMO.SEL").write(0)
            fc7.dispatch()
        if arg=='right':
            fc7.getNode("TRX.LEMO.SEL").write(1)
            fc7.dispatch()
        print( 'Input LEMO trigger select set.')

    # end-of-run asynchronous readout wait count
    elif opt in ("-y"):
        fc7.getNode("EOR.ASYNC.WAIT").write(ctypes.c_uint32(int(arg)).value)
        fc7.dispatch()
        print( 'End-of-run asynchronous readout wait count set.')

    # send BOC even when in overflow mode
    elif opt in ("-v"):
        if arg=='on':
            fc7.getNode("SEND.OFW.BOC").write(1)
            fc7.dispatch()
            print( 'send BOC in overflow state enabled.')
        elif arg=='off':
            fc7.getNode("SEND.OFW.BOC").write(0)
            fc7.dispatch()
            print( 'send BOC in overflow state enabled.')

    # reprogram Kintex-7 FPGA
    elif opt in ("-z"):
        fc7.getNode("SYSTEM.FPGA_REPROG").write(1)
        fc7.dispatch()
        print( 'Kintex-7 FPGA reprogramming request issued.')
