#!/bin/bash

IYG_DIR=$1
PRIV_DATA_DIR=$2
PUB_DATA_DIR=$3
LOG_DIR=$4

echo "Getting description text from SOT..."
(${IYG_DIR}/import/get-sot/get-sot.sh ${PUB_DATA_DIR}/sot-snp-category-trait-shortname.txt ${PUB_DATA_DIR} 2>&1 ) > ${LOG_DIR}/get-sot.log

echo "Initialising database..."
${IYG_DIR}/build/init-db.sh ${PRIV_DATA_DIR} 2>&1 > ${LOG_DIR}/init-db.log

echo "Importing into database..."
${IYG_DIR}/import/import-db.sh ${PRIV_DATA_DIR} 2>&1 > ${LOG_DIR}/import-db.log

