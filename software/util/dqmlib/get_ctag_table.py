# some functions for pulling the CTAG values from the dqm
# returns results as a pandas dataframe

import urllib
import urllib.request
import json
import sys
import pandas as pd
from itertools import product
from time import sleep

URL = 'http://localhost:3333/ctagTableJSON'
VARIABLES = ['t0Integrals', 'clusterTag', 'muonTag']
PULSE_NUMS = ['all'] + ['{}'.format(i) for i in range(16)]
COLUMN_ORDER = ['pulse', 'nshots'] + VARIABLES

# we use urllib differently in python3 from in python2
IS_PYTHON_3 = sys.version_info >= (3, 0)
import urllib

def get_ctag_json(url):
    if IS_PYTHON_3:
        with urllib.request.urlopen(url) as page:
                return json.load(page)
    else:
        return json.load(urllib.urlopen(url))


def dataframe_from_json(json_data, start_run=0, start_event=0):
    # adjust start_run and start_event if we have crossed into a new run
    if json_data['lastRun'] != start_run:
        start_run = 0
        start_event = 0

    df_dict = {}

    for pulse_num in PULSE_NUMS:
        pulse_list = df_dict.setdefault('pulse', [])
        pulse_list.append(pulse_num)

        n_pulses_list = df_dict.setdefault('nshots', [])
        n_pulses = None

        for var in VARIABLES:
            var_name = var
            var_name += '' if pulse_num == 'all' else '_' + pulse_num
            data = json_data[var_name]
            last_history_vals = data['lastHistory']['y']

            # drop events before start event
            last_history_events = data['lastHistory']['x']
            start_index = 0
            for index, event in enumerate(last_history_events):
                if event <= start_event:
                    start_index = index + 1
                elif event > start_event:
                    start_index = index
                    break

            last_history_vals = last_history_vals[start_index:]

            # count number of pulses we are including
            n_pulses_this_var = len(last_history_vals)
            if n_pulses is None:
                n_pulses = n_pulses_this_var
            elif n_pulses != n_pulses_this_var:
                raise RuntimeError('problem with pulse ' + pulse_num +
                                   ', differing number of'
                                   + ' pulses for each variable')

            var_list = df_dict.setdefault(var, [])
            try:
                var_list.append(sum(last_history_vals))
            except TypeError:
                var_list.append(0)

        n_pulses_list.append(n_pulses)

    return pd.DataFrame(df_dict)


def measure_ctag_for(wait_time, url=URL):
    '''input a number of seconds to measure for (wait_time). 
    Returns a pandas dataframe containing the CTAGs collected over that time period.
    Note: DQM only stores a history of 1000 shots, so don't wait for longer than the
    time required to collect 1000 shots for a given pulse in the cycle'''
    start_json = get_ctag_json(url)
    start_run = start_json['lastRun']
    start_event = start_json['lastEvent']
    if (wait_time < 0):
        raise RuntimeError('You must use a wait time > 0!')

    sleep(wait_time)
    json_data = get_ctag_json(url)
    return dataframe_from_json(json_data, start_run, start_event)


def get_ctag_dataframe(url=URL):
    return dataframe_from_json(get_ctag_json(url))


def main():
    ctag_df = dataframe_from_json(get_ctag_json(URL))
    print(ctag_df)

    print(ctag_df.to_csv(columns=COLUMN_ORDER))
    print(measure_ctag_for(10).to_csv(columns=COLUMN_ORDER))


if __name__ == '__main__':
    main()
