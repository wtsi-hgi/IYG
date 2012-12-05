#!/bin/bash

PRIV_DATA_DIR=$1
runscripts=$2

if [[ -z "${runscripts}" || "${runscripts}" == "all" ]]
then
    # default to run all
    runscripts="convert-delivery analysis import import_pred"
    echo "individual runscripts not specified, defaulting to: [${runscripts}]"
fi


reldir=`dirname $0`
if [[ `echo "${reldir}" | cut -c1` = "/" ]]
then
    IYG_DIR=${reldir}/../
else
    IYG_DIR=`pwd`/${reldir}/../
fi
PUB_DATA_DIR=${IYG_DIR}/public_data/

if [[ ! -d ${PRIV_DATA_DIR}/delivery ]]
    then
    echo "Must specify PRIV_DATA_DIR as first argument"
    exit 1
fi

#build_date=`date +'%s'`
#LOG_DIR=${IYG_DIR}/build/log-${build_date}
#mkdir -p ${LOG_DIR}
rm -rf ${IYG_DIR}/build/log && mkdir ${IYG_DIR}/build/log
LOG_DIR=${IYG_DIR}/build/log

echo "build-all using ${PRIV_DATA_DIR} for private data and ${IYG_DIR} as iyg root dir, logging in ${LOG_DIR}"

export IYG_DIR
export PRIV_DATA_DIR
export PUB_DATA_DIR
export LOG_DIR_TOP=${LOG_DIR}

# run all run scripts 
for runscript in ${runscripts}; 
do
    echo "Running ${runscript} script... "
    if [[ -e  ${IYG_DIR}/build/run-${runscript}.sh ]]
    then
	export LOG_DIR=${LOG_DIR_TOP}/run-${runscript}/
	mkdir -p ${LOG_DIR}
	${IYG_DIR}/build/run-${runscript}.sh          # &> ${LOG_DIR}/run-${runscript}.log
    else
	echo "[ERROR] ${IYG_DIR}/build/run-${runscript}.sh does not exist!"
	exit 1
    fi
done

