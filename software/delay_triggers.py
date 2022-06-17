import sys, csv

# help menu
def HELP_MENU():
    print ('usage: python delay_trigger_simple.py [channels] [bunches] [delay] [csv file]')

# check number of arguments
if len(sys.argv) < 5:
    HELP_MENU()
    sys.exit(2)

# parse argument options
def PARSE_ARG(arg):
    parsed = []
    csplit = arg.split(',')
    for c in csplit:
        dsplit = c.split('-')
        if len(dsplit)==1:
            parsed.append(dsplit[0])
        else:
            for d in xrange(int(dsplit[0]),int(dsplit[1])+1):
                parsed.append(str(d))
    return parsed

channels = PARSE_ARG(sys.argv[1])
seqs  = PARSE_ARG(sys.argv[2])
delay  = int(sys.argv[3])
csv_f = sys.argv[4]

#print (channels)
#print (seqs)
#print (delay)
#print (csv_f)

# .csv file format:
# [channel], [sequence], [pulse], [delay], [width], [enable]

trigger_out = []

with open(csv_f, 'rb') as infile:
    # read in settings
    reader = csv.reader(infile)
    
    next(reader)
    for setting in reader:

        if ( setting[0] in channels and 
             setting[1] in seqs and 
             int(setting[2]) == 1 and # delay muon fills 
             int(setting[3]) != 0 # only non-zero delays
            ):

            setting[3] = str(int(setting[3]) + delay)
            #print(setting)


        #analog fanout counts from $a6 event
        #ttc fanout counts from the previous trigger
        #for laser also delay out-of-fill laser triggers here,
        #not to change the ttc configuration
        #if ( setting[0] in channels and int(setting[0]) == 15 and
        #     setting[1] in seqs and
        #     int(setting[2]) == 2 and # delay laser fills 
        #     int(setting[3]) != 0  # only non-zero delays
        #    ):

        #   setting[3] = str(int(setting[3]) + delay)
        #    #print(setting)


        trigger_out.append(setting)


with open(csv_f, 'wb') as outfile:
    writer = csv.writer(outfile)

    writer.writerow(["Channel", "Sequence", "Pulse", "Delay", "Width", "Enable"])
    writer.writerows(trigger_out)



