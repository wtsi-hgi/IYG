#!/bin/bash

if [[ ! ( -n "${IYG_DIR}" && -d ${IYG_DIR} ) ]]; 
    then
    echo "Must set environment variable IYG_DIR to a valid directory"
    exit 1
fi

if [[ ! ( -n "${PRIV_DATA_DIR}" && -d ${PRIV_DATA_DIR} ) ]]; 
    then
    echo "Must set environment variable PRIV_DATA_DIR to a valid directory"
    exit 1
fi

if [[ ! ( -n "${PUB_DATA_DIR}" && -d ${PUB_DATA_DIR} ) ]]; 
    then
    echo "Must set environment variable PUB_DATA_DIR to a valid directory"
    exit 1
fi

if [[ ! ( -n "${LOG_DIR}" && -d ${LOG_DIR} ) ]]; 
    then
    echo "Must set environment variable LOG_DIR to a valid directory"
    exit 1
fi

if [[ ! -d ${PRIV_DATA_DIR}/delivery ]]
    then
    echo "PRIV_DATA_DIR does not contain delivery subdirectory"
    exit 1
fi

echo "Getting description text from SOT..."
(${IYG_DIR}/import/get-sot/get-sot.sh ${PUB_DATA_DIR}/sot-snp-category-trait-shortname.txt ${PUB_DATA_DIR} ) &> ${LOG_DIR}/get-sot.log

echo "Initialising database..."
${IYG_DIR}/build/init-db.sh ${PRIV_DATA_DIR} &> ${LOG_DIR}/init-db.log

echo "Importing into database..."
${IYG_DIR}/import/import-db.sh ${PRIV_DATA_DIR} &> ${LOG_DIR}/import-db.log

echo "Importing predictions and resource URIs into database..."
${IYG_DIR}/import_pred/import_pred-db.sh ${PRIV_DATA_DIR} &> ${LOG_DIR}/import_pred-db.log

