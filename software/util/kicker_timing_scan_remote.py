# takes one argument, the number of seconds to measure the ctag table for
# outputs results as a CSV into a new file under <dir>

import sys
import dqmlib
import csv
import time
import os

def main():
    if len(sys.argv) != 2:
        print('Usage: kicker_timing_scan_remote <dir>')
        #print('example: measure_ctag_for -1 localhost:3333')
        sys.exit(0)
    host = "localhost:3333"
    wait_time = 60
    wait_time_before = 20
    dir_name = sys.argv[1]

    url = 'http://' + host + '/ctagTableJSON'

    def f_name_gen():
        i = 1
        while True:
            yield dir_name + '/ctag_%03d.csv' % i
            i += 1

    f_name = f_name_gen()

    #delays = [0, -6, 6, -12, 12]

    delays = [0, -25, -22, -28, -19, -31] 

    #while True:
    os.system('ssh g2be1 "cd gm2ccc/software/; python read_triggers_csv_python3.py 0 4 kicker-timings-plot.csv; cp kicker-timings-plot.csv kicker-timings-plot.csv.start"')
    for delay in delays:
        os.system('ssh g2be1 "cd gm2ccc/software/; . delayKickers.sh %i; . loadTrigger.sh"' % delay)
        print("load new values: delay %i" % delay)

        time.sleep(wait_time_before)
        
        f_csv = next(f_name)
        print("storing ctags in " + f_csv)
        ctag_df = dqmlib.measure_ctag_for(wait_time, url)

        if ctag_df.iat[0,2] != 0:
            print("All ctags/t0: ", ctag_df.iat[0,4]/ctag_df.iat[0,2])
            print("All ctags/n fill: ", ctag_df.iat[0,4]/ctag_df.iat[0,1])

        with open(f_csv, 'w') as outfile:
            ctag_csv = ctag_df.to_csv(columns=dqmlib.COLUMN_ORDER)
            outfile.write(ctag_csv)

        #input("Hit Enter to continue...")


if __name__ == '__main__':
    main()
