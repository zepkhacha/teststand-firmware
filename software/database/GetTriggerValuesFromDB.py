import argparse
import psycopg2 
import sys
import csv

parser = argparse.ArgumentParser(description='Get trigger values from DB and put in a csv')
parser.add_argument('--type', type=str, required=True, dest='trig_type', action='store',
                    choices=['a6analog','t9analog','ttc','ttcAnalog'], help='Define whether this is loading analog (A6-based kicker, quad, laser), t9analog (T9-based kicker) or TTC (calo, tracker etc) files')
parser.add_argument('--id', type=int, required=True, dest='id', action='store',help='id to get, if -1 gets the latest one (by time/id)')
parser.add_argument('--db', type=str, required=True, dest='db', choices=['g2db-priv','localhost'],action='store',help='Database host')

args = parser.parse_args()
trig_type = args.trig_type
id = args.id
db = args.db

if (db == 'g2db-priv'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=g2db-priv port=5433"
elif (db == 'localhost'):    
    dsn = "dbname=gm2_online_prod user=gm2_writer host=localhost port=5434"

conn = psycopg2.connect(dsn)
cur = conn.cursor()
    
if (trig_type == 'a6analog'):
    filename = 'gm2trigger_analog_a6_2019_id_'
    table = 'gm2trigger_analog_a6_2019'
    order = 'id,channel,sequence,pulse_index'
    title= 'Channel,Sequence,Pulse,Delay,Width,Enable'
elif (trig_type == 't9analog'):
    filename = 'gm2trigger_analog_t9_2019_id_'
    table = 'gm2trigger_analog_t9_2019'
    order = 'id,channel,sequence'
    title= 'Channel,Sequence,Delay,enabled,global_width'
elif (trig_type == 'ttc'):
    filename = 'gm2trigger_ttc_2019_id_'
    table = 'gm2trigger_ttc_2019'
    order = 'id,sequence'
    title = 'Sequence,Index,Gap,Type'
elif (trig_type == 'ttcAnalog'):
    filename = 'gm2trigger_ttc_analog_pulse_2019_id_'
    table = 'gm2trigger_ttc_analog_pulse_2019'
    order = 'id'
    title = 'Delay,Width'

if (id == -1):
    sql = 'select * from %s where id=(select max(id) from %s) order by %s' % (table,table,order)
else:    
    sql = 'select * from %s where id=%d order by %s' % (table,id,order)
    
cur.execute(sql)
conn.commit()
rows = cur.fetchall()
i = 0
for row in rows:
    id = int(row[0])
    if (i == 0):
        fname = '%s%d.txt' % (filename,id)
        file = open(fname, "w")
        file.write(title+'\n')
    i = i + 1    
    if (trig_type == 'a6analog'):
        xx='%d,%d,%d,%d,%d,%d' % (row[1],row[2],row[3],row[4],row[5],row[6])
        file.write(xx.strip()+'\n')
    elif (trig_type == 't9analog'):
        xx='%d,%d,%d,%d,%d' % (row[1],row[2],row[3],row[4],row[5])
        file.write(xx.strip()+'\n')
    elif (trig_type == 'ttc'):
        xx='%d,%d,%d,%d' % (row[1],row[2],25*row[3],row[4])
        file.write(xx.strip()+'\n')
    elif (trig_type == 'ttcAnalog'):
        xx='%d,%d,%d,%d' % (row[1],row[2],25*row[3],row[4])
        file.write(xx.strip()+'\n')

file.close()        
cur.close()
conn.close()

print ("The DB values for id=%d have been written to local file = %s" % (id,fname))
            
