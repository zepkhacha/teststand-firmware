import argparse
import psycopg2 
import datetime

parser = argparse.ArgumentParser(description='Copy table and create new ID with same values')
parser.add_argument('--db', type=str, required=True, dest='db', choices=['g2db-priv','localhost'],action='store',help='Database host')
parser.add_argument('--id', type=int, required=True, dest='id', action='store',help='ID of A6 table')
parser.add_argument('--existing_channel', type=int, required=True, dest='existing_channel', action='store',help='Existing channel number')
parser.add_argument('--new_channel', type=int, required=True, dest='new_channel', action='store',help='New channel number to create with data from specified existing channel')


args = parser.parse_args()
db = args.db
ID = int(args.id)
OLD_CHANNEL = int(args.existing_channel)
NEW_CHANNEL = int(args.new_channel)

if (db == 'g2db-priv'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=g2db-priv port=5433"
elif (db == 'localhost'):    
    dsn = "dbname=gm2_online_prod user=gm2_writer host=localhost port=5434"

conn = psycopg2.connect(dsn)
curr = conn.cursor()


sqlS = "select id,channel,sequence,pulse_index,delay,width,enabled,time from \
	gm2trigger_analog_a6_2019 where id=%d and channel=%d order by id,channel,sequence,pulse_index" % (ID,OLD_CHANNEL)

curr.execute(sqlS)
conn.commit()
rows = curr.fetchall()

for row in rows:
	timestamp = datetime.datetime(2019, 6, 21, 13, 27, 00)
	delay = int(row[4])
#	delay = delay*5/2  # convert from 200 MHz to 500 MHz

	sql = "insert into gm2trigger_analog_a6_2019 values (%d,%d,%d,%d,%d,%d,%d,'%s')" % (int(row[0]),NEW_CHANNEL,int(row[2]),int(row[3]),delay,int(row[5]),int(row[6]),timestamp)
	
	print sql

	curr.execute(sql)
	conn.commit()


curr.close()
conn.close()
