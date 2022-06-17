# Trigger FC7 pulse train storage script
# Usage: python store_triggers.py [crate] [slot] [csv file]

import uhal, sys, csv
uhal.disableLogging()

# help menu
def HELP_MENU():
    print( 'usage: python store_triggers.py [crate] [slot] [csv file]')

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
#address_table = "file://address_tables/address_table.xml"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# .csv file format:
# [channel], [sequence], [pulse], [delay], [width], [enable]

with open(sys.argv[3], 'r') as infile:
    # read in settings
    reader = csv.reader(infile)
    settings = list(map(tuple, reader))

    # verify settings
    for setting in settings[1:]:
        # number of columns
        if len(setting) != 6:
            print( 'File format error: incorrect number of columns (6)!')
            sys.exit(2)
        # channel number
        if int(setting[0]) < 1 or int(setting[0]) > 16:
            print( 'File format error: channel number out of range (1-16)!')
            sys.exit(2)
        # sequence number
        if int(setting[1]) < 1 or int(setting[1]) > 16:
            print( 'File format error: sequence number out of range (1-16)!')
            sys.exit(2)
        # pulse number
        if int(setting[2]) < 1 or int(setting[2]) > 4:
            print( 'File format error: pulse number out of range (1-4)!')
            sys.exit(2)
        # delay value
        if int(setting[3]) < 0 or int(setting[3]) > 16777215:
            print( 'File format error: delay value out of range (0-16777215)!')
            sys.exit(2)
        # width value
        if int(setting[4]) < 0 or int(setting[4]) > 16777215:
            print( 'File format error: width value out of range (0-16777215)!')
            sys.exit(2)
        # enable value
        if not (int(setting[5]) == 0 or int(setting[5]) == 1):
            print( 'File format error: enable value is neither 0 nor 1!')
            sys.exit(2)

    # write registers
    for setting in settings[1:]:
        loop0 =  int(setting[3],0)        & 0x3F
        loop1 = (int(setting[3],0) >>  6) & 0x3F
        loop2 = (int(setting[3],0) >> 12) & 0x3F
        loop3 = (int(setting[3],0) >> 18) & 0x3F
        fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP0_PULSE"+str(int(setting[2])-1)).write(loop0)
        fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP1_PULSE"+str(int(setting[2])-1)).write(loop1)
        fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP2_PULSE"+str(int(setting[2])-1)).write(loop2)
        fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP3_PULSE"+str(int(setting[2])-1)).write(loop3)

        loop0 =  int(setting[4],0)       & 0xF
        loop1 = (int(setting[4],0) >> 4) & 0xF
        #enable = 0 if int(setting[4],0) == 0 else 1
        enable = int(setting[5])
        fc7.getNode("WIDTH.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP0_PULSE"+str(int(setting[2])-1)).write(loop0)
        fc7.getNode("WIDTH.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".LOOP1_PULSE"+str(int(setting[2])-1)).write(loop1)
        fc7.getNode("WIDTH.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".ENABLE_PULSE"+str(int(setting[2])-1)).write(enable)

        # old
        # fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".PULSE"+str(int(setting[2])-1)).write(int(setting[3]))
        # fc7.getNode("WIDTH.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".PULSE"+str(int(setting[2])-1)).write(int(setting[4]))
    fc7.dispatch()

print( 'Trigger settings stored successfully!')
