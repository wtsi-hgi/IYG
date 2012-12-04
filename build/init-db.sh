#!/bin/bash

usage="
Usage: ./init-db.sh ~/iyg-private-data/
"

IYG_PRIVATE_DATA_DIR="$1"
IYG_DIR=`dirname $0`/../

IYG_CREATE_DB_SQL="${IYG_DIR}/iyg.sql"
IYG_DB_NAME="iyg"

if [[ -n "${IYG_PRIVATE_DATA_DIR}" ]] && \
    [[ -d ${IYG_PRIVATE_DATA_DIR} ]] 
then
    if [[ -f ${IYG_PRIVATE_DATA_DIR}/mysql-user-pass.txt && \
	  -f ${IYG_PRIVATE_DATA_DIR}/mysql-iygadmin.cnf ]] 
    then
        # drop database and re-create
	echo "DROP SCHEMA IF EXISTS ${IYG_DB_NAME};" | mysql --defaults-extra-file=${IYG_PRIVATE_DATA_DIR}/mysql-iygadmin.cnf
	cat ${IYG_CREATE_DB_SQL} | mysql --defaults-extra-file=${IYG_PRIVATE_DATA_DIR}/mysql-iygadmin.cnf 
    else 
	echo "Required files do not exist in ${IYG_PRIVATE_DATA_DIR}"
	exit 2
    fi
else 
    echo "${usage}"
    exit 1
fi


