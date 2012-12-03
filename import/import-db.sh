#!/bin/bash

usage="
Usage: import-db.sh ~/iyg-private-data/
"

IYG_PRIVATE_DATA_DIR="$1"

if [[ -n "${IYG_PRIVATE_DATA_DIR}" ]] && \
    [[ -d ${IYG_PRIVATE_DATA_DIR} ]] 
then
    if [[ -f ${IYG_PRIVATE_DATA_DIR}/barcodes.list ]] && \
	[[ -f ${IYG_PRIVATE_DATA_DIR}/iyg.ped ]] && \
 	[[ -f ${IYG_PRIVATE_DATA_DIR}/iyg.map ]] 
    then
	awk 'BEGIN {FS="\t";} $1=="iygrw" {print $2;}' ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt | ./import.py \
	    --db-user iygrw \
	    --purge-all \
	    --barcodes-file ${IYG_PRIVATE_DATA_DIR}/barcodes.list \
	    --snp-info-file ../public_data/master-snp-info.txt \
	    --trait-info-file ../public_data/master-trait-info.txt \
#	    --snp-trait-genotype-effect-file ../public_data/master-snp-trait-genotype-effect.txt \
#	    --results-file ${IYG_PRIVATE_DATA_DIR}/iyg
    else 
	echo "Error: required files are issing in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi
    else
    echo "${usage}"
    exit 1
fi



