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
	    --user iygrw \
	    --barcodes ${IYG_PRIVATE_DATA_DIR}/barcodes.list \
	    --snps ../public_data/snp-info.txt \
	    --traits ../public_data/master-trait-info.txt \
	    --results ${IYG_PRIVATE_DATA_DIR}/iyg
    else 
	echo "Error: required files are issing in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi
    else
    echo "${usage}"
    exit 1
fi



