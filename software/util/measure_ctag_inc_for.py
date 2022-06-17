# takes one argument, the number of seconds to measure the ctag table for
# outputs results as a CSV into a new file under <dir>

import sys
import dqmlib
import csv


def main():
    if len(sys.argv) != 4:
        print('Usage: measure_ctag_for <time to wait> <host> <dir>')
        print('example: measure_ctag_for -1 localhost:3333')
        sys.exit(0)

    url = 'http://' + sys.argv[2] + '/ctagTableJSON'
    wait_time = int(sys.argv[1])
    dir_name = sys.argv[3]

    def f_name_gen():
        i = 1
        while True:
            yield dir_name + '/ctag_%03d.csv' % i
            i += 1

    f_name = f_name_gen()

    while True:
        f_csv = next(f_name)
        print("storing ctags in " + f_csv)
        ctag_df = dqmlib.measure_ctag_for(wait_time, url)

        if ctag_df.iat[0,2] != 0:
            print("All ctags/t0: ", ctag_df.iat[0,4]/ctag_df.iat[0,2])
            print("All ctags/n fill: ", ctag_df.iat[0,4]/ctag_df.iat[0,1])

        with open(f_csv, 'w') as outfile:
            ctag_csv = ctag_df.to_csv(columns=dqmlib.COLUMN_ORDER)
            outfile.write(ctag_csv)

        input("Hit Enter to continue...")


if __name__ == '__main__':
    main()
