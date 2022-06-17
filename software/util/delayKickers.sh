#!/bin/bash
delay=$1
bunch=$2
cmd1="\"cd gm2ccc/software && python delay_triggers_python3.py 3 ${bunch} ${delay} kicker-timings-plot.csv\""
cmd2="'ssh -t daq@g2be1 ${cmd1} '"
cmd3="ssh -t G2Muon@g2gateway01 ${cmd2}"
eval $cmd3
