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


# input data goes in ${PRIV_DATA_DIR}/delivery as zip files

# unzip raw plate data
echo -n "unzipping raw plate data... "
rm -rf ${PRIV_DATA_DIR}/delivery-unzip
mkdir -p ${PRIV_DATA_DIR}/delivery-unzip
zipfiles=`find ${PRIV_DATA_DIR}/delivery/* -name \*.zip -type f`
if [[ -z "${zipfiles}" ]]
    then
    echo "PRIV_DATA_DIR/delivery does not contain any zip files"
    exit 1
fi
for zipfile in ${zipfiles}
do
    echo -n "${zipfile} "
    unzip ${zipfile} -d ${PRIV_DATA_DIR}/delivery-unzip
done
echo "done."


# link plate dirs 
echo -n "linking plate directories... "
rm -rf ${PRIV_DATA_DIR}/all-data-raw
mkdir -p ${PRIV_DATA_DIR}/all-data-raw
platedirs=`find ${PRIV_DATA_DIR}/delivery-unzip/ -name plate_\* -type d`
for platedir in ${platedirs}
do
    echo -n "${platedir} "
    ln -s ${platedir} ${PRIV_DATA_DIR}/all-data-raw/
done
echo "done."


# Generate assay summary TSV from Fluidigm plate XLSXes
echo -n "generating assay summary TSV from XLSXes... "
xlsxes=`find -L ${PRIV_DATA_DIR}/all-data-raw/ -name assay_summary\*.xlsx -type f`
echo -n "${xlsxes} "
${IYG_DIR}/convert-delivery/assay-summary-combine.pl ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv ${xlsxes}
echo ">> ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv"


# Generate PED/snpchrpos from assay summary TSV
echo -n "generating PED from assay summary TSV... "
${IYG_DIR}/convert-delivery/assaysummary2ped.sh ${IYG_DIR}/public_data/SNP-CHR-POS_GRCh37.txt ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink
echo ">> ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink.ped ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink.map"


