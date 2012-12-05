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

# input data goes in ${PRIV_DATA_DIR}/delivery as zip files

# unzip raw plate data
echo -n "unzipping raw plate data... "
rm -rf ${PRIV_DATA_DIR}/delivery-unzip
mkdir -p ${PRIV_DATA_DIR}/delivery-unzip
zipfiles=`find ${PRIV_DATA_DIR}/delivery/* -name \*.zip -type f`
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


