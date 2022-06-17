import argparse
import psycopg2 
import sys
import csv
import datetime

parser = argparse.ArgumentParser(description='Take kicker timings and add offset to create quad timings')
parser.add_argument('--db', type=str, required=True, dest='db', choices=['g2db-priv','localhost'],action='store',help='Database host')
parser.add_argument('--id', type=int, required=True, dest='id', action='store',help='ID')
parser.add_argument('--offset', type=int, required=True, dest='offset', action='store',help='Timing shift in us')

args = parser.parse_args()
db = args.db
ID = args.id
offset = args.offset

if (db == 'g2db-priv'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=g2db-priv port=5433"
elif (db == 'localhost'):    
    dsn = "dbname=gm2_online_prod user=gm2_writer host=localhost port=5434"

conn = psycopg2.connect(dsn)
curr = conn.cursor()

for seq in range(16):
	sequence = seq+1
	# Get kicker-1 timing
	sql = "select id,channel,sequence,pulse_index,delay from \
	gm2trigger_analog_a6_2019 where id=%d and channel=1 and sequence=%d and pulse_index=1" % (ID,sequence)
	print sql
	curr.execute(sql)
	conn.commit()
	rows = curr.fetchall()
	row = rows[0]
	kicker_delay = int(row[4])
	offset_ticks = offset*500 # offset in us to offset in ticks 
	quad_delay = kicker_delay + 600 - offset_ticks  
	sql = "update gm2trigger_analog_a6_2019 \
	set delay=%d where id=%d and channel=4 and sequence=%d and pulse_index=1" % (quad_delay,ID,sequence)
	print sql
	curr.execute(sql)
	conn.commit()


curr.close()
conn.close()
