#!/bin/bash
cmd1="\"cd gm2ccc/software && python config_general_python3.py 0 4 -m stop && python store_triggers_python3.py 0 4 kicker-timings-plot.csv && python config_general_python3.py 0 4 -m start\""
cmd2="'ssh -t daq@g2be1 ${cmd1} '"
cmd3="ssh -t G2Muon@g2gateway01 ${cmd2}"
eval $cmd3
