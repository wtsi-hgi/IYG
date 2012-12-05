#!/bin/bash

PRIV_DATA_DIR=$1
reldir=`dirname $0`
if [[ `echo "${reldir}" | cut -c1` = "/" ]]
then
    IYG_DIR=${reldir}/../
else
    IYG_DIR=`pwd`/${reldir}/../
fi
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


echo "Running import script... "
${IYG_DIR}/build/run-import.sh ${IYG_DIR} ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${LOG_DIR} 2>&1 > ${LOG_DIR}/run-import.log


echo "Running analysis... "
${IYG_DIR}/build/run-analysis.sh ${IYG_DIR} ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${LOG_DIR} 2>&1 > ${LOG_DIR}/run-analysis.log



