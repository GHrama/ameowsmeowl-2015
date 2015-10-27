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
    new_end_time = end_time - (20 * 1000)
    df = df[df['timestamp'] > new_start_time]
    df = df[df['timestamp'] < new_end_time]
    return df


def ci(data):
    n, min_max, mean, var, skew, kurt = scipy.stats.describe(data)
    std = math.sqrt(var)
    error_margin = 1.96 * (std / np.sqrt(n))
    l, h = mean - error_margin, mean + error_margin
    return (l, h)



COLORS = ['r','g','b']


def main():
    output_path = "/Users/ramapriyasridharan/Documents/SystemsLabExperiements/24-Oct/Trace-30-mins/01/client/client1.log"
    output_path1 ="/Users/ramapriyasridharan/Documents/SystemsLabExperiements/24-Oct/Trace-30-mins/01/client2/client2.log"

    xlabel = "Time in minutes"
    ylabel = "Response time in ms"
    header_row = ['timestamp','type','response_time']
    df = pd.read_csv(output_path, header=None,sep=",")
    df.columns = ['timestamp', 'type', 'response_time']
    df = refine(df)
    #df['response_time'] = df[df['response_time'] < 300]
    min_timestamp = np.min(df['timestamp'])
    df['timestamp'] = np.round((df['timestamp'] - min_timestamp)/60000)

    df2 = pd.read_csv(output_path1, header=None,sep=",")
    df2.columns = ['timestamp', 'type', 'response_time']
    df2 = refine(df2)
    #df2['response_time'] = df2[df2['response_time'] < 300]
    min_timestamp = np.min(df2['timestamp'])
    df2['timestamp'] = np.round((df2['timestamp'] - min_timestamp)/60000)
    df3 = pd.concat([df,df2])
    i = 0

    #print df
    for msg in ['GET_LATEST_MSG_DELETE','SEND_MSG','GET_QUEUE']:
        print msg
        df1 = df3.loc[df3['type'] == msg]
        print len(df1)
        response_mean = np.mean(df1['response_time'])
        response_median = np.median(df1['response_time'])
        response_std = np.std(df1['response_time'])
        l,h = ci(df1['response_time'])
        max_resp = np.max(df1['response_time'])
        print "For msg_type = %s maximum response time %s"%(msg,max_resp)
        print "For msg_type = %s Response time avg = %.3f +- %.3f std = %.3f and Median = %.3f "%(msg,np.round(response_mean,3),np.round(h-response_mean,3),np.round(response_median,3),np.round(response_std,3))
        grp_by = df1.groupby('timestamp')
        response_time_grp = grp_by['response_time'].mean()
        plt.plot(response_time_grp, 'o-', color=COLORS[i], label=msg, lw=0.5)
        #plt.fill_between(range(0,40),l, h, alpha=0.3, color=COLORS[i])
        i += 1

    response_mean = np.mean(df3['response_time'])
    response_median = np.median(df3['response_time'])
    response_std = np.std(df3['response_time'])
    l,h = ci(df3['response_time'])
    max_resp = np.max(df3['response_time'])
    print "For msg_type = %s maximum response time %s"%('ALL',max_resp)
    print "For msg_type = %s Response time avg = %.3f +- %.3f std = %.3f and Median = %.3f "%('ALL',np.round(response_mean,3),np.round(h-response_mean,3),np.round(response_median,3),np.round(response_std,3))
    # round to nearest minute
    #find number of timestamps greater than 100
    #print df[df['response_time'] > 70]
    grp_by_timestamp_df = df3.groupby('timestamp')
    mean_resp_per_min = grp_by_timestamp_df['response_time'].mean()


    plt.plot(mean_resp_per_min, 'o-', color='k', label='ALL', lw=0.5)
    #plt.fill_between(range(0,40), l, h, alpha=0.3, color='k')

    plt.xlim(xmin=0.0,xmax=30)
    plt.ylim(ymin=0.0,ymax=100)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend(loc="best", fancybox=True, framealpha=0.5)
    plt.grid()
    plt.show()

    #print df['response_time']'''




if __name__ == "__main__":
    main()