__author__ = 'ramapriyasridharan'
__author__ = 'ramapriyasridharan'
import matplotlib.pyplot as plt
import numpy as np
import argparse
import  pandas as pd
import scipy as sp
import scipy.stats, math
import sys
import os
import ConfigParser



WARMUP_SECS = 0
COOLDOWN_SECS = 20



def mean_confidence_interval(data, confidence=0.95):
    # a = 1.0*np.array(data)
    n = len(data)
    # m, se = np.mean(a), scipy.stats.sem(a)
    # h = se * sp.stats.t._ppf((1+confidence)/2.0, n-1)
    n, min_max, mean, var, skew, kurt = scipy.stats.describe(data)
    std = math.sqrt(var)
    # l, h = scipy.stats.norm.interval(0.05, loc=mean, scale=std)
    margin_of_error = 1.96 * (std / np.sqrt(n))
    l, h = mean - margin_of_error, mean + margin_of_error
    # return m, m-h, m+h
    return (l, h)


def refine(df):
    start_time = np.min(df['timestamp'])
    end_time   = np.max(df['timestamp'])
    new_start_time = start_time + (WARMUP_SECS * 1000)
    new_end_time = end_time - (COOLDOWN_SECS * 1000)
    df = df[df['timestamp'] > new_start_time]
    df = df[df['timestamp'] < new_end_time]
    return df


def main():

    output_path = "/Users/ramapriyasridharan/Documents/data_loc.txt"

    responses = []
    responses.append(0)
    xlabel = " Number of Clients"
    ylabel = " Average response time in ms"
    ll = []
    hh = []
    std = []
    std.append(0)
    ll.append(0)
    hh.append(0)


    #plt.fill_between(0, 0, 0, alpha=0.3, color='r')
    with open(output_path) as f:
        i = 1
        for exptini_path_raw in f:
            df = None
            exptini_path = exptini_path_raw.strip()
            df = pd.read_csv(exptini_path, header=None,sep=",")
            df.columns = ['timestamp', 'type', 'response_time']
            df = refine(df)
            min_timestamp = np.min(df['timestamp'])
            df['timestamp'] = np.round((df['timestamp'] - min_timestamp)/1000)
            responses.append(np.mean(df['response_time']))
            l,h = mean_confidence_interval(df['response_time'])
            std.append(np.std(df['response_time']))
            ll.append(l)
            hh.append(h)



            i += 1
    #print len(throughputs)
    plt.plot(range(0,110,10), responses, 'o-', color='b', label='ALL', lw=0.5)
    plt.fill_between(range(0,110,10), ll, hh, alpha=0.3, color='b')
    plt.errorbar(range(0,110,10), responses, yerr=std, label='Deviation From Mean', fmt='--o')
    max_y = np.max(responses)*1.5
    plt.xlim(xmin=0.0, xmax=100)
    plt.ylim(ymin=0.0, ymax=max_y)
    plt.grid()
    plt.legend(loc="best", fancybox=True, framealpha=0.5)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.show()



if __name__ == '__main__':
  main()
