import argparse
import psycopg2 
import sys
import csv
import datetime

parser = argparse.ArgumentParser(description='Copy table and create new ID with same values')
parser.add_argument('--db', type=str, required=True, dest='db', choices=['g2db-priv','localhost'],action='store',help='Database host')
parser.add_argument('--table', type=str, required=True, dest='table', choices=['gm2trigger_ttc_2019','gm2trigger_analog_a6_2019','gm2trigger_analog_t9_2019'],action='store',help='Database host')
parser.add_argument('--oldID', type=int, required=True, dest='oldID', action='store',help='OLD ID')
parser.add_argument('--newID', type=int, required=True, dest='newID', action='store',help='NEW ID')
parser.add_argument('--scraping_delay', type=int, required=False, dest='scraping_delay', action='store',help='Extra delay to add to scraping in us: 1500 = 3us',default=0)


args = parser.parse_args()
db = args.db
table = args.table
oldID = args.oldID
newID = args.newID
scraping_delay = args.scraping_delay

if (db == 'g2db-priv'):
    dsn = "dbname=gm2_online_prod user=gm2_writer host=g2db-priv port=5433"
elif (db == 'localhost'):    
    dsn = "dbname=gm2_online_prod user=gm2_writer host=localhost port=5434"

conn = psycopg2.connect(dsn)
curr = conn.cursor()

if (table == "gm2trigger_ttc_2019"):
	sqlS = "select id, sequence, pulse_index,gap,type,time from gm2trigger_ttc_2019 where id = %d" % (oldID)
elif (table == "gm2trigger_analog_a6_2019"):
	sqlS = "select id,channel,sequence,pulse_index,delay,width,enabled,time from \
	gm2trigger_analog_a6_2019 where id=%d order by id,channel,sequence,pulse_index" % (oldID) 
elif (table == "gm2trigger_analog_t9_2019"):
        sqlS = "select id,channel,sequence,delay,enabled,global_width,time from \
	gm2trigger_analog_t9_2019 where id=%d order by id,channel,sequence" % (oldID) 

print "Copying ID = %d to ID = %d in table: %s" % (oldID,newID,table)
curr.execute(sqlS)
conn.commit()
rows = curr.fetchall()

for row in rows:
	timestamp = datetime.datetime.now()
        if (table == 'gm2trigger_analog_a6_2019'):
            channel = int(row[1])
            pulse_index = int(row[3])
            delay = int(row[4])
            if (channel == 4 and pulse_index == 1 and scraping_delay != 0):
		print("Applying scraping_delay of %d ticks" % (scraping_delay))  
		delay = delay + scraping_delay   # 500 ticks = 1000 ns = 1us
                
	if (table == "gm2trigger_analog_a6_2019"):
		sql = "insert into gm2trigger_analog_a6_2019 \
	values (%d,%d,%d,%d,%d,%d,%d,'%s')" % \
	(newID,int(row[1]),int(row[2]),int(row[3]),delay,int(row[5]),int(row[6]),timestamp)

	elif (table == "gm2trigger_analog_t9_2019"):
		sql = "insert into gm2trigger_analog_t9_2019 \
	values (%d,%d,%d,%d,%d,%d,'%s')" % \
	(newID,int(row[1]),int(row[2]),int(row[3]),int(row[4]),int(row[5]),timestamp)

	
	elif (table == "gm2trigger_ttc_2019"):
		sql = "insert into gm2trigger_ttc_2019 \
	values (%d,%d,%d,%d,%d,'%s')" % \
	(newID,int(row[1]),int(row[2]),int(row[3]),int(row[4]),timestamp)


	print sql
	curr.execute(sql)
	conn.commit()


curr.close()
conn.close()
