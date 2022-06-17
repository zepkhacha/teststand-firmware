# T9-based Trigger FC7 pulse train storage script
# Usage: python store_t9triggers.py [crate] [slot] [csv file]

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
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# .csv file format:
# [channel], [sequence], [delay], [enable], [global_width]

with open(sys.argv[3], 'rb') as infile:
    # read in settings
    reader = csv.reader(infile)
    settings = map(tuple, reader)

    # verify settings
    for setting in settings[1:]:
        # number of columns
        if len(setting) != 5:
            print( 'File format error: incorrect number of columns (5)!')
            sys.exit(2)
        # channel number
        if int(setting[0]) < 1 or int(setting[0]) > 4:
            print( 'File format error: channel number out of range (1-4)!')
            sys.exit(2)
        # sequence number
        if int(setting[1]) < 1 or int(setting[1]) > 16:
            print( 'File format error: sequence number out of range (1-16)!')
            sys.exit(2)
        # delay value
        if int(setting[2]) < 0 or int(setting[3]) > 16777215:
            print( 'File format error: delay value out of range (0-16777215)!')
            sys.exit(2)
        # enable value
        if not (int(setting[3]) == 0 or int(setting[5]) == 1):
            print( 'File format error: enable value is neither 0 nor 1!')
            sys.exit(2)
        # global width value
        if int(setting[4]) < 0 or int(setting[4]) > 255:
            print( 'File format error: width value out of range (0-255)!')
            sys.exit(2)
    
    # write registers
    last_channel = 0
    for setting in settings[1:]:
        # set the two global variables for this chanel
        if ( setting[0] != last_channel ):
            fc7.getNode("T9_CHANNELS_PULSE_WIDTH").write(setting[4])
            fc7.getNode("T9_CHANNELS_ENABLED").write(setting[3])
            last_channel = setting[0]
        # now the individual sequence settings
        fc7.getNode("T9_DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)).write(setting[3])

        # old
        # fc7.getNode("DELAY.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".PULSE"+str(int(setting[2])-1)).write(int(setting[3]))
        # fc7.getNode("WIDTH.CHAN"+str(int(setting[0])-1)+".SEQ"+str(int(setting[1])-1)+".PULSE"+str(int(setting[2])-1)).write(int(setting[4]))
    fc7.dispatch()

print( 'Trigger settings stored successfully!')
