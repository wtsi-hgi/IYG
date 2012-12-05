#!/bin/bash

SNP_CHR_POS=$1
ASSAY_SUMMARY=$2
PEDMAP_OUT=$3

STAGE2_PERL_SCRIPT=`dirname $0`/assaysummary2ped-s2.pl

awk 'BEGIN {FS="\t"; OFS="\t";} NR!=1 && $5!="NTC" {print $5, $6, $12, $11;} NR!=1 && $5=="NTC" {print $5"-"$6"-"$2, $6, $12, $11}' ${ASSAY_SUMMARY} | perl ${STAGE2_PERL_SCRIPT} ${SNP_CHR_POS} ${PEDMAP_OUT}

