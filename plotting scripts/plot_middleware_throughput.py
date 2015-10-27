__author__ = 'ramapriyasridharan'

import matplotlib.pyplot as plt
import numpy as np
import argparse
import pandas as pd
import scipy as sp
import scipy.stats, math
import sys
import os
import ConfigParser
import csv

warm_up = 100
cool_down = 100


def refine(df):
    start_time = np.min(df['timestamp'])
    #print start_time.columns[0]
    end_time = np.max(df['timestamp'])
    #print end_time.columns[0]
    new_start_time = start_time + (20 * 1000)
    #new_end_time = 0
    df = df[df['timestamp'] > new_start_time]
    #df = df[df['timestamp'] < new_end_time]
    return df


def ci(data):
    n, min_max, mean, var, skew, kurt = scipy.stats.describe(data)
    std = math.sqrt(var)
    error_margin = 1.96 * (std / np.sqrt(n))
    l, h = mean - error_margin, mean + error_margin
    return (l, h)



COLORS = ['r','g','b']


def main():
    output_path = "/Users/ramapriyasridharan/Documents/SystemsLabExperiements/24-Oct/Trace-30-mins-2/middleware/middle1.log"
    output_path1 ="/Users/ramapriyasridharan/Documents/SystemsLabExperiements/24-Oct/Trace-30-mins-2/middleware2/middle2.log"

    xlabel = "Time in minutes"
    ylabel = "Throughput (transactions/minute)"

    header_row = ['timestamp','type','response_time']
    df = pd.read_csv(output_path, header=None,sep=",")
    df.columns = ['timestamp', 'type', 'response_time']
    df = refine(df)
    min_timestamp = np.min(df['timestamp'])
    df['timestamp'] = np.round((df['timestamp'] - min_timestamp)/60000)

    df2 = pd.read_csv(output_path1, header=None,sep=",")
    df2.columns = ['timestamp', 'type', 'response_time']
    df2 = refine(df2)
    min_timestamp = np.min(df2['timestamp'])
    df2['timestamp'] = np.round((df2['timestamp'] - min_timestamp)/60000)
    df3 = pd.concat([df,df2])
    #print df3
    i=0
    for msg in ['SEND_MSG','GET_QUEUE','GET_LATEST_MSG_DELETE']:
        df1 = df3[df3['type'] == msg]
        t_per_sec = map(lambda x : len(df1[df1['timestamp'] == x]), range(1, int(np.max(df1['timestamp']))))
        tp_mean = np.mean(t_per_sec)
        tp_median = np.median(t_per_sec)
        tp_err = np.std(t_per_sec)
        l,h = ci(t_per_sec)
        #print len(t_per_sec)
        #print t_per_sec
        print '%s:\tTP = %.2f +- %.2f\tstd = %.3f\tmedian = %.3f' % (msg, np.round(tp_mean, 2), np.round(h - tp_mean, 2), np.round(np.std(t_per_sec), 3), tp_median)

        plt.plot(range(0,len(t_per_sec)), t_per_sec, 'o-', color=COLORS[i], label=msg, lw=0.5)
        #plt.fill_between(xnp, l, h, alpha=0.3, color=plots[plot_name]['color'][typ])
        i += 1

    t_per_sec = map(lambda x : len(df3[df3['timestamp'] == x]), range(1, int(np.max(df3['timestamp']))))
    tp_mean = np.mean(t_per_sec)
    tp_median = np.median(t_per_sec)
    tp_err = np.std(t_per_sec)
    l,h = ci(t_per_sec)
    print len(t_per_sec)
    print t_per_sec
    print '%s:\tTP = %.2f +- %.2f\tstd = %.3f\tmedian = %.3f' % ('ALL', np.round(tp_mean, 2), np.round(h - tp_mean, 2), np.round(np.std(t_per_sec), 3), tp_median)
    plt.plot(range(0,len(t_per_sec)), t_per_sec, 'o-', color='k', label='ALL', lw=0.5)
    max_y = np.max(t_per_sec)*1.5
    plt.xlim(xmin=0.0, xmax=30)
    plt.ylim(ymin=0.0, ymax=max_y)
    plt.grid()
    plt.legend(loc="best", fancybox=True, framealpha=0.5)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.show()




if __name__ == "__main__":
    main()