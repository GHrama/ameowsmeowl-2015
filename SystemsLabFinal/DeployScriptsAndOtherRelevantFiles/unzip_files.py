author__ = 'ramapriyasridharan'



import os
import os.path
import tarfile

def main():
    output_path = "/Users/ramapriyasridharan/Documents/clients_file.txt"
    path = []
    with open(output_path) as f:
        for exptini_path_raw in f:
            exptini_path = exptini_path_raw.strip()
            path.append(exptini_path)
            print path

    for i in range(6,11):
        print i
        for j in range(0,len(path)):
            print j
            if i < 10:
                p = "/%s/0%d"%(path[j],i)
            else:
                p = "/%s/%d"%(path[j],i)
            print p
            for root, _, files in os.walk(p):
                for f in files:
                    if f.endswith('.tgz'):
                        print 'going to extract %s'%f
                        f1 = os.path.join(p,f)
                        print f1
                        tar = tarfile.open(f1)
                        tar.extractall(p)
                        tar.close()



if __name__ == '__main__':
    main()
