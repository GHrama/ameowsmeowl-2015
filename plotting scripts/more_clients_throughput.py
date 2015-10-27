author__ = 'ramapriyasridharan'


import matplotlib.pyplot as plt
import numpy as np
import argparse
import  pandas as pd
import scipy as sp
import scipy.stats, math
import sys
import os
import ConfigParser



WARMUP_SECS = 20
COOLDOWN_SECS = 70



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
    #df = df[df['response_time'] > 15]
    return df


def main():

    output_path = "/Users/ramapriyasridharan/Documents/clients_file.txt"

    throughputs = []
    throughputs.append(0)
    xlabel = " Number of Clients"
    ylabel = " Average throughput (transactions/second)"
    ll = []
    hh = []

    ll.append(0)
    hh.append(0)
    path = []
    #plt.fill_between(0, 0, 0, alpha=0.3, color='r')
    with open(output_path) as f:
        for exptini_path_raw in f:
            exptini_path = exptini_path_raw.strip()
            path.append(exptini_path)


    for i in range(1,11):
        df = None
        #df.columns = ['timestamp', 'type', 'response_time']
        for j in range(0,2):
            if i < 10:
                p = "/%s/0%d/middleware"%(path[j],i)
            else:
                p = "/%s/%d/middleware"%(path[j],i)
            for root, _, files in os.walk(p):
                for f in files:
                    f1 = os.path.join(p,f)
                    df1 = pd.read_csv(f1, header=None,sep=",")
                    #print df1
                    print len(df1)
                    df1.columns = ['timestamp', 'type', 'response_time']
                    #df1 = df1[df1['type'] == 'GET_QUEUE']
                    df1 = refine(df1)
                    min_timestamp = np.min(df1['timestamp'])
                    df1['timestamp'] = np.round((df1['timestamp'] - min_timestamp)/1000)
                    df = pd.concat([df,df1])
                    #print df
        t_per_sec = map(lambda x : len(df[df['timestamp'] == x]), range(1, int(np.max(df['timestamp']))))
        l,h = mean_confidence_interval(t_per_sec)
        ll.append(l/3)
        hh.append(h/3)
        print "appending %d"%i
        throughputs.append(np.mean(t_per_sec)/3)









    print len(throughputs)
    plt.plot(range(0,110,10), throughputs, 'o-', color='r', label='ALL', lw=0.5)
    plt.fill_between(range(0,110,10), ll, hh, alpha=0.3, color='r')
    #plt.errorbar(range(0,110,10), throughputs, yerr=std, label='Deviation From Mean', fmt='--o')
    max_y = np.max(throughputs)*1.5
    plt.xlim(xmin=0, xmax=100)
    #plt.ylim(ymin=0.0, ymax=max_y)
    plt.grid()
    plt.legend(loc="best", fancybox=True, framealpha=0.5)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.show()



if __name__ == '__main__':
  main()
