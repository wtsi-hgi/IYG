#!/bin/bash

PRIV_DATA_DIR=$1
IYG_DIR=`pwd`/`dirname $0`/../
PUB_DATA_DIR=${IYG_DIR}/public_data/

if [[ ! -e ${PRIV_DATA_DIR}/iyg.ped ]]
    then
    echo "Must specify PRIV_DATA_DIR as first argument"
    exit 1
fi

build_date=`date +'%s'`
LOG_DIR=${IYG_DIR}/build/log-${build_date}
mkdir -p ${LOG_DIR}

echo "build-all using ${PRIV_DATA_DIR} for private data and ${IYG_DIR} as iyg root dir, logging in ${LOG_DIR}"

echo "Getting description text from SOT..."
(${IYG_DIR}/analyse/get-sot/get-sot.sh ${PUB_DATA_DIR}/sot-snp-category-trait-shortname.txt ${PUB_DATA_DIR} 2>&1 ) > ${LOG_DIR}/get-sot.log

echo "Initialising database..."
${IYG_DIR}/build/init-db.sh ${PRIV_DATA_DIR} 2>&1 > ${LOG_DIR}/init-db.log

echo "Importing into database..."
${IYG_DIR}/import/import-db.sh ${PRIV_DATA_DIR} 2>&1 > ${LOG_DIR}/import-db.log

