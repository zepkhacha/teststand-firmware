import argparse
import psycopg2 
import sys
import csv
import datetime

parser = argparse.ArgumentParser(description='Reads a trigger file (csv) and puts into DB')
parser.add_argument('--type', type=str, required=True, dest='trig_type', action='store',
                    choices=['analog_a6','analog_t9','ttc','global_delay_width'], help='Define whether this is loading analog (A6-based or T9-based) csv, a TTC csv or loading the global ttc-analog delay and width')
parser.add_argument('--filename', type=str, default='none', required=False, dest='filename', action='store',help='filename (csv format) to read')
parser.add_argument('--description', type=str, default='none', required=False, dest='description', action='store',help='description of this trigger setting')
parser.add_argument('--db', type=str, required=True, dest='db', choices=['g2db-priv','localhost','pg1.classe.cornell.edu'],action='store',help='Database host')
parser.add_argument('--global_delay', default=-1, type=int, required=False, dest='global_delay', action='store',help='Global analog/TTC delay')
parser.add_argument('--global_width', default=-1, type=int, required=False, dest='global_width', action='store',help='Global analog/TTC width')
parser.add_argument('--id', default=-1, type=int, required=False, dest='id', action='store',help='table id to use')


args = parser.parse_args()
trig_type = args.trig_type
filename = args.filename
description = args.description
db = args.db
global_delay = int(args.global_delay)
global_width = int(args.global_width)
id = int(args.id)

if (trig_type == 'global_delay_width' and ((global_delay == -1) or (global_width == -1)) ):
    print( "You must specify --global_delay=xxx --global_width=xxx when using --type=global_delay_width")
    sys.exit(-1)
if (trig_type == 'analog_a6' and filename == 'none'):
    print( "You must specify --filename=xxx.csv when using --type=analog_a6")
    sys.exit(-1)
if (trig_type == 'analog_t9' and ((filename == 'none') or (global_width == -1))  ):
    print( "You must specify --filename=xxx.csv --global_width=zzzz when using --type=analog_t9")
    sys.exit(-1)
if (trig_type == 'ttc' and ((filename == 'none') or (description == 'none'))):
    print( "You must specify --filename=xxx.csv --description='blah' when using --type=ttc")
    sys.exit(-1)

    
if (db == 'g2db-priv'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=g2db-priv port=5433"
elif (db == 'localhost'):    
    dsn = "dbname=gm2_online_prod user=gm2_writer host=localhost port=5434"
elif (db == 'localhost'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=pg1.classe.cornell.edu port=5432"

timestamp = datetime.datetime.now()    
conn = psycopg2.connect(dsn)
cur = conn.cursor()
    
# Deal with the global analog/ttc delay width 

if (trig_type == 'global_delay_width'):
    cur.execute("select max(id) from gm2trigger_ttc_analog_pulse_2019")
#    cur.execute("select nextval('gm2trigger_ttc_analog_pulse_2019_id_seq')")
    result = cur.fetchone()
    id = int(result[0])+1
    sql = "insert into gm2trigger_ttc_analog_pulse_2019 values (%d,%d,%d)" % (global_delay, global_width, id)
    print( sql )
    cur.execute(sql)
    conn.commit()
    sys.exit(-1)

if (trig_type == 'analog_a6'):
    if ( id < 0 ):
      print( "Be patient -- this takes approx 10 secs...." )
      cur.execute("select max(id) from gm2trigger_analog_a6_2019")
      result = cur.fetchone()
      id = int(result[0])+1
      table = 'gm2trigger_analog_a6_2019'
      name = 'analog A6'
if (trig_type == 'analog_t9'):
    if ( id < 0 ):
      print( "Be patient -- this takes approx 10 secs....")
      cur.execute("select max(id) from gm2trigger_analog_a6_2019")
#      cur.execute("select nextval('gm2trigger_analog_t9_2019_id_seq')")
      result = cur.fetchone()
      id = int(result[0])+1
      table = 'gm2trigger_analog_t9_2019'
      name = 'analog T9'
elif (trig_type == 'ttc'):
    if ( id < 0 ):
      cur.execute("select max(id) from gm2trigger_ttc_a6_2019")
#      cur.execute("select nextval('gm2trigger_ttc_2019_id_seq')")
      result = cur.fetchone()
      id = int(result[0])+1
      table = 'gm2trigger_ttc_2019'
      name = 'ttc'

sql = "insert into gm2trigger_descriptions_2019(id_name,id,description) values ('%s',%d,'%s')" % (name, id,description)
print( sql )
cur.execute(sql)
conn.commit()
    

with open(filename, 'rb') as csvfile:
    reader = csv.reader(csvfile, delimiter=',') # this has a header
    next(reader)
    for row in reader:
        values= ', '.join(row)
        if (trig_type == 'analog_a6'):
            channel    = int(row[0])
            sequence = int(row[1])
            pulse       = int(row[2])
            delay       = int(row[3])
            width       = int(row[4])
            enabled      = int(row[5])
                
            sql = "insert into gm2trigger_analog_a6_2019 (id,channel,sequence,pulse_index,delay,width,enabled,time) values (%d,%d,%d,%d,%d,%d,%d,'%s')" % (id,channel,sequence,pulse,delay,width,enabled,timestamp)
            cur.execute(sql)
            conn.commit()
            
        elif (trig_type == 'analog_t9'):
            channel    = int(row[0])
            sequence = int(row[1])
            delay       = int(row[2])
            enabled      = int(row[3])
            sql = "insert into gm2trigger_analog_t9_2019 (id,channel,sequence,delay,enabled,global_width,time) values (%d,%d,%d,%d,%d,%d,'%s')" % (id,channel,sequence,delay,enabled,global_width,timestamp)
            cur.execute(sql)
            conn.commit()
        elif (trig_type == 'ttc'):
            print( row )
            sequence   = int(row[0])
            pulse_index           = int(row[1])
            gap            = int(row[2]) # in ticks
            Ttype         = int(row[3])
            sql = "insert into gm2trigger_ttc_2019 (id,sequence,pulse_index,gap,type,time) values (%d,%d,%d,%d,%d,'%s')" % (id,sequence,pulse_index,gap,Ttype,timestamp)
            cur.execute(sql)
            conn.commit()

print( "Values from file = %s have been inserted into table = %s in the DB: they have been assiged the unique id value = %d" % (filename,table,id) )

cur.close()
conn.close()
            
            
