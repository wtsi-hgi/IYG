#!/bin/bash

usage="
Usage: import_pred-db.sh ~/iyg-private-data/
"

IYG_PRIVATE_DATA_DIR="$1"
IYG_DIR=`dirname $0`/../

IMPORT_PY=${IYG_DIR}/import/import.py

if [[ -n "${IYG_PRIVATE_DATA_DIR}" ]] && \
    [[ -d ${IYG_PRIVATE_DATA_DIR} ]] 
then
    
    echo "purging prediction data from db..."
    awk 'BEGIN {FS="\t";} $1=="iygrw" {print $2;}' ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt |  ${IMPORT_PY} \
	--db-user iygrw \
	--purge-pred
	
    echo "import prediction output data..."
    if [[ -d ${IYG_PRIVATE_DATA_DIR}/pred_results/out/ ]] 
    then
	pred_out_files=`find ${IYG_PRIVATE_DATA_DIR}/pred_results/out/ -maxdepth 2 -type f -name pred.\*.txt`
	if [[ -n "${pred_out_files}" ]]
	then
	    awk 'BEGIN {FS="\t";} $1=="iygrw" {print $2;}' ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt |  ${IMPORT_PY} \
		--db-user iygrw \
		$(for pred_out_file in ${pred_out_files}; do echo -n "--trait-profile-pred-file ${pred_out_file} "; done)
	else 
	    echo "[ERROR] no pred.*.txt files found in ${IYG_PRIVATE_DATA_DIR}/pred_results/out/"
	    exit 3
	fi
    else 
	echo "Error: required files are missing in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi

    echo "import resource file names..."
    if [[ -d ${IYG_PRIVATE_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d/ ]] 
    then
	resourcemd5files=`find ${IYG_PRIVATE_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d/ -maxdepth 1 -type f -name \*.resourcemd5.txt`
	if [[ -n "${resourcemd5files}" ]]
	then
	    awk 'BEGIN {FS="\t";} $1=="iygrw" {print $2;}' ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt |  ${IMPORT_PY} \
		--db-user iygrw \
		$(for resourcemd5file in ${resourcemd5files}; do echo -n "--trait-profile-pred-file ${resourcemd5file} "; done)
	else 
	    echo "[ERROR] no *.resourcemd5.txt files in ${IYG_PRIVATE_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d/"    
	    exit 3
	fi
    else 
	echo "Error: required files are missing in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi


else
    echo "${usage}"
    exit 1
fi
