
cp kicker-timings-plot.csv.start kicker-timings-plot.csv
echo "python /home/daq/gm2ccc/software/delay_triggers_python3.py 1-3 1-16 $1 kicker-timings-plot.csv"
python /home/daq/gm2ccc/software/delay_triggers_python3.py 1-3 1-16 $1 kicker-timings-plot.csv

