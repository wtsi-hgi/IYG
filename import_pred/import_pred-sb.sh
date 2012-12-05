#!/bin/bash

usage="
Usage: import-db.sh ~/iyg-private-data/
"

IYG_PRIVATE_DATA_DIR="$1"
IYG_DIR=`dirname $0`/../

IYG_PUBLIC_DATA_DIR=${IYG_DIR}/public_data
IMPORT_PY=${IYG_DIR}/import/import.py

if [[ -n "${IYG_PRIVATE_DATA_DIR}" ]] && \
    [[ -d ${IYG_PRIVATE_DATA_DIR} ]] 
then
    if [[ -f ${IYG_PRIVATE_DATA_DIR}/barcodes.list ]] && \
	[[ -f ${IYG_PRIVATE_DATA_DIR}/iyg.ped ]] && \
 	[[ -f ${IYG_PRIVATE_DATA_DIR}/iyg.map ]] 
    then
	awk 'BEGIN {FS="\t";} $1=="iygrw" {print $2;}' ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt |  ${IMPORT_PY} \
	    --db-user iygrw \
	    --purge-all \
	    --barcodes-file ${IYG_PRIVATE_DATA_DIR}/barcodes.list \
	    --snp-info-file ${IYG_PUBLIC_DATA_DIR}/master-snp-info.txt \
	    --trait-info-file ${IYG_PUBLIC_DATA_DIR}/master-trait-info.txt \
	    --snp-trait-genotype-effect-file ${IYG_PUBLIC_DATA_DIR}/master-snp-trait-genotype-effect.txt \
	    --trait-description-fofn ${IYG_PUBLIC_DATA_DIR}/desc/trait_descriptions.fofn \
	    --trait-snp-description-fofn ${IYG_PUBLIC_DATA_DIR}/desc/trait_snp_descriptions.fofn \
	    --results-file ${IYG_PRIVATE_DATA_DIR}/iyg \
	    --update-popfreqs
    else 
	echo "Error: required files are issing in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi
    else
    echo "${usage}"
    exit 1
fi



