#!/usr/bin/python

import sys

if (len(sys.argv) < 2 or sys.argv[1] == "-h"):
    print
    print "Usage: tped2qcall.py infiles > outfile.qcall"
    print
    print "Converts plink tped/tfam files with prefix infiles to a qcall file outfile.qcall"
    print
    exit(-1)

# set the likelihood error to 1 (so log-likelihood is equal to mismatch count)
errL = "1"

likedict = {}
likedict["AA"] = "0" + "\t" + "\t".join([errL]*9)
likedict["AC"] =  errL + "\t" + "0" + "\t" + "\t".join([errL]*8)
likedict["CA"] =  errL + "\t" + "0" + "\t" + "\t".join([errL]*8)
likedict["AG"] =  "\t".join(errL*2) + "\t" + "0" + "\t" + "\t".join([errL]*7)
likedict["GA"] =  "\t".join(errL*2) + "\t" + "0" + "\t" + "\t".join([errL]*7)
likedict["AT"] =  "\t".join(errL*3) + "\t" + "0" + "\t" + "\t".join([errL]*6)
likedict["TA"] =  "\t".join(errL*3) + "\t" + "0" + "\t" + "\t".join([errL]*6)
likedict["CC"] =  "\t".join(errL*4) + "\t" + "0" + "\t" + "\t".join([errL]*5)
likedict["CG"] =  "\t".join(errL*5) + "\t" + "0" + "\t" + "\t".join([errL]*4)
likedict["GC"] =  "\t".join(errL*5) + "\t" + "0" + "\t" + "\t".join([errL]*4)
likedict["CT"] =  "\t".join(errL*6) + "\t" + "0" + "\t" + "\t".join([errL]*3)
likedict["TC"] =  "\t".join(errL*6) + "\t" + "0" + "\t" + "\t".join([errL]*3)
likedict["GG"] =  "\t".join(errL*7) + "\t" + "0" + "\t" + "\t".join([errL]*2)
likedict["GT"] =  "\t".join(errL*8) + "\t" + "0" + "\t" + errL
likedict["TG"] =  "\t".join(errL*8) + "\t" + "0" + "\t" + errL
likedict["TT"] =  "\t".join(errL*9) + "\t" + "0"
likedict["NN"] =  "\t".join("0"*10)
likedict["00"] =  "\t".join("0"*10)
likedict["--"] =  "\t".join("0"*10)


TPED=open(sys.argv[1] + ".tped")
TFAM=open(sys.argv[1] + ".tfam")

ids=[]
for line_raw in TFAM:
    line=line_raw.split()
    ids.append(line[1])

for line_raw in TPED:
    line=line_raw.split()
    #print(len(line))
    #print(line[:6])
    for i in range(len(ids)):
        A1 = (line[4 + 2*i])
        A2 = (line[5 + 2*i])
        print(line[0] + "\t" + line[3] + "\t" + "N\t0\t0\t0" + "\t" + likedict[A1 + A2] + "\t" + ids[i])
        
        
