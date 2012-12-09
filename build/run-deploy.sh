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

if [[ ! -f ${PRIV_DATA_DIR}/mysql-iygadmin.cnf ]] 
    then
    echo "PRIV_DATA_DIR does not contain mysql-iygadmin.cnf"
    exit
fi

if [[ ! -f ${PRIV_DATA_DIR}/iyg-secondary-servers.txt ]]
    then
    echo "PRIV_DATA_DIR does not contain yg-secondary-servers.txt"
    exit
fi

iyg_secondary_hosts=`cat ${PRIV_DATA_DIR}/iyg-secondary-servers.txt`

echo -n "saving mysqldump..."
    mysqldump --defaults-file=${PRIV_DATA_DIR}/mysql-iygadmin.cnf iyg > ${PRIV_DATA_DIR}/iyg.mysqldump
echo "done."

for server in ${iyg_secondary_hosts}; do 
    echo -n "copying database dump to ${server}..."
    (scp -r ${PRIV_DATA_DIR}/iyg.mysqldump ${server}:${PRIV_DATA_DIR}/iyg.mysqldump && echo "done.") || (echo "fail!" && exit 1)

    echo -n "loading database on ${server}..."
    ((ssh ${server} 'mysql --defaults-file='"${PRIV_DATA_DIR}"'/mysql-iygadmin.cnf iyg < '"${PRIV_DATA_DIR}"'/iyg.mysqldump' > ${PRIV_DATA_DIR}/iyg.mysqldump.${server}.load) && echo "done.") || (echo "fail!" && exit 1)

    echo -n "copying pred_results to ${server}... "
    (scp -q -r ${PUB_DATA_DIR}/pred_results ${server}:${PUB_DATA_DIR}/ && echo "done.") || (echo "fail!" && exit 1)

    echo -n "copying webresource to ${server}... "
    (scp -q -r ${PUB_DATA_DIR}/webresource ${server}:${PUB_DATA_DIR}/ && echo "done.") || (echo "fail!" && exit 1)

done

