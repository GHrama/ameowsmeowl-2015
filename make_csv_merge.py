import csv
import matplotlib.pyplot as plt
import numpy as np
import argparse
from pandas import read_csv
import scipy as sp
import scipy.stats, math
import sys
import os
import ConfigParser


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("filelist", help="Format: Value File in each line")
    parser.add_argument("output_dir", help="output directory")
    args = parser.parse_args()

    # write header
    fout = open(args.output_dir+"merged.txt","a")
    fout.write("timestamp         type       response_time\n")

    #from each file get the data and put it in fout/merge

    with open(args.filelist) as f:
        for file in f:
            file_read = open(file.strip())
            for line in file_read:
                fout.write(line)

    fout.close()
    #now all file in filelist have been merged
    #next make them into csv files
    make_csv(args.output_dir+"merged.txt",args.output_dir+"merged_csv.csv")


def make_csv(file1,file2):
    with open(file1) as fin, open(file2, 'w') as fout:
        o=csv.writer(fout)
        for line in fin:
            o.writerow(line.split())


if __name__ == '__main__':
    main()




