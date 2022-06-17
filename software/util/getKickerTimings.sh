#!/bin/bash
ssh -t g2gateway 'ssh -t daq@g2be1 "cd gm2ccc/software && python read_triggers_csv_python3.py 0 4 kicker-timings-plot.csv" ' 
rsync g2be1:~/gm2ccc/software/kicker-timings-plot.csv ./ -vaP
