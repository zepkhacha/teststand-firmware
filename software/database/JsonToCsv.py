import csv, json, sys,argparse

parser = argparse.ArgumentParser(description='Reads a A6 analog json file and writes out a csv for a given channel')
parser.add_argument('--json', type=str, default='none', required=True, dest='json_filename', action='store',help='json filename')
parser.add_argument('--trig_type', type=str, required=True, dest='trig_type', action='store',
                    choices=['analog_a6','analog_t9','ttc'], help='Define whether this is loading analog A6-based, T9-based or TTC json')
parser.add_argument('--channel', default=-1, type=int, required=True, dest='channel', action='store',help='A6 trigger channel #')


args = parser.parse_args()
json_filename = args.json_filename
channel = args.channel
trig_type = args.trig_type
csvx = json_filename.split('.json')
csv_filename = "Ch%d_%s.csv" % (channel,csvx[0])
print csv_filename

inputFile = open(json_filename) #open json file
outputFile = open(csv_filename, 'w') #load csv file
data = json.load(inputFile) #load json content
inputFile.close() #close the input file
output = csv.writer(outputFile) #create a csv.write

if (trig_type == 'analog_a6'):
    header = "Channel, sequence, pulse_index, delay, width, enabled"
if (trig_type == 'analog_t9'):
    header = "Channel, sequence, delay, enabled"
print header
outputFile.write(header+'\n')
for sequence in range(16):
    seq = sequence
    if (trig_type == 'analog_a6'):
        key_delay = "Sequence%d-Trigger-Delay" % (seq)
        key_width = "Sequence%d-Trigger-Width" % (seq)
        delay_data = data[key_delay]
        width_data = data[key_width]
        for pulse in range(4):
            xdata = "%d,%d,%d,%d,%d,%d" % (channel,seq+1,pulse+1,delay_data[pulse], width_data[pulse],1)
            print xdata
            outputFile.write(xdata+'\n')
    if (trig_type == 'analog_t9'):
        key_delay = "Sequence%d-T9-trigger-Delay" % (seq)
        delay_data = data[key_delay]
        xdata = "%d,%d,%d,%d" % (channel,seq+1,delay_data, 1)
        print xdata
        outputFile.write(xdata+'\n')

            
outputFile.close()
        
