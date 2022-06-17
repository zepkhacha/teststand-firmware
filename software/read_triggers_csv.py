# Trigger FC7 pulse train read script
# Usage: python read_triggers.py [crate] [slot] [csv file]

import uhal, sys, csv
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python read_triggers.py [crate] [slot] [csv file]'

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# .csv file format:
# [channel], [sequence], [pulse], [delay], [width]

with open(sys.argv[3], 'wb') as outfile:
    # read in settings
    writer = csv.writer(outfile)
    t = []
    #settings = map(tuple, reader)

    # read registers
    for channel in range(0, 3):  #kicker 1--3
        for sequence in range(0, 16):
            for pulse in range(0, 4):
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

		t.append((channel + 1, sequence + 1, pulse + 1, delay, width, int(ENABLE.value())))

    writer.writerow(["Channel", "Sequence", "Pulse", "Delay", "Width", "Enable"])
    writer.writerows(t)

print 'Trigger settings read successfully!'

