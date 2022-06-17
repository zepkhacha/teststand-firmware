# Trigger FC7 pulse train read script
# Usage: python read_triggers.py [crate] [slot] [csv file]

import uhal, sys, csv
uhal.disableLogging()

# help menu
def HELP_MENU():
    print 'usage: python read_ttc_csv.py [crate] [slot] [csv file]'

# check number of arguments
if len(sys.argv)<4:
    HELP_MENU()
    sys.exit(2)

# parse argument options
uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://address_tables/address_table.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# .csv file format:
# [trigger], [gap], [type]

with open(sys.argv[3], 'wb') as outfile:
    # read in settings
    writer = csv.writer(outfile)
    t = []
    #settings = map(tuple, reader)

    global_count = fc7.getNode("SEQ.COUNT").read()
    fc7.dispatch()

    # read registers
    for sequence in range(0, int(global_count.value()) + 1):
        seq_count = fc7.getNode("SEQ"+str(sequence)+".COUNT").read()
        fc7.dispatch()

        for trigger in range(0, int(seq_count.value()) + 1):
            tr_gap = fc7.getNode("SEQ"+str(sequence)+".PRE.TRIG.GAP"+str(trigger)).read() 
            tr_type = fc7.getNode("SEQ"+str(sequence)+".TRIG.TYPE"+str(trigger)).read() 
            fc7.dispatch()
            t.append((sequence + 1, int(tr_gap.value()), int(tr_type.value())))

    writer.writerow(["Trigger", "Gap", "Type"])
    writer.writerows(t)

print 'TTC settings read successfully!'

