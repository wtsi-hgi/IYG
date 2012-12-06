#!/usr/bin/env python

import sys

print "Barcode\tTraitShortName\tHaplogroup\tInfoText\n";
TEXTFILE=open(sys.argv[1])
HAPFILE=open(sys.argv[2])
textdict = {}
for line_raw in TEXTFILE:
    line=line_raw.split("\t")
    textdict[line[0]] = line[1]

for line_raw in HAPFILE:
    line=line_raw.split()
    print line[0] + "\tY\t" + line[1] + "\t" + textdict[line[1]],
