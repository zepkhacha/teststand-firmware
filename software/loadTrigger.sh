python /home/daq/gm2ccc/software/config_general_python3.py 0 4 -m stop
sleep 1
python /home/daq/gm2ccc/software/store_triggers_python3.py 0 4 kicker-timings-plot.csv
#python store_triggers_python3.py 0 4 kicker-timings-plot_opt.csv
sleep 1
python /home/daq/gm2ccc/software/config_general_python3.py 0 4 -m start
