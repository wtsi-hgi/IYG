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
    unzip ${zipfile} -d ${PRIV_DATA_DIR}/delivery-unzip &>> ${LOG_DIR}/unzip.log
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
    ln -s ${platedir} ${PRIV_DATA_DIR}/all-data-raw/ &>> ${LOG_DIR}/link_plate.log
done
echo "done."

echo "disable: ${IYG_DISABLE_XLSX} fakeout: ${IYG_FAKEOUT}"

# Generate assay summary TSV from Fluidigm plate XLSXes
if [[ "${IYG_DISABLE_XLSX}" != "" ]]
then
    echo -n "generating assay summary TSV from XLSXes... "
    xlsxes=`find -L ${PRIV_DATA_DIR}/all-data-raw/ -name assay_summary\*.xlsx -type f`
    echo -n "${xlsxes} "
    ${IYG_DIR}/convert-delivery/assay-summary-combine.pl ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv ${xlsxes} &>> ${LOG_DIR}/assay-summary-combine.log
    echo ">> ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv"
else
    echo "XLSX import disabled by environment variable (IYG_DISABLE_XLSX)"
fi

# Override fake data if requested
if [[ "${IYG_FAKEOUT}" != "" ]]
then
    echo "********** OVERRIDING RAW DATA WITH FAKE FOR TESTING, to disable, unset IYG_FAKEOUT"
    cp ${PRIV_DATA_DIR}/fake-data-raw/ALL_assay_summary.fakebarcode.tsv ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv
fi

# Generate initial PED/MAP from assay summary TSV
echo -n "generating PED from assay summary TSV... "
${IYG_DIR}/convert-delivery/assaysummary2ped.sh ${IYG_DIR}/public_data/SNP-CHR-POS_GRCh37.txt ${PRIV_DATA_DIR}/all-data-raw/ALL_assay_summary.tsv ${PRIV_DATA_DIR}/ALL_assay_summary.initialplink &>> ${LOG_DIR}/assaysummary2ped.log
echo ">> ${PRIV_DATA_DIR}/ALL_assay_summary.initialplink.ped ${PRIV_DATA_DIR}/ALL_assay_summary.initialplink.map"

# Generate list of NTC samples to remove
awk 'BEGIN {FS="\t";} $1 ~ "^NTC-" {print $1" "$1;}' ${PRIV_DATA_DIR}/ALL_assay_summary.initialplink.ped > ${PRIV_DATA_DIR}/ALL_assay_summary.NTC.indlist 

# Recode PED/MAP to standard format and remove NTC samples
echo -n "generating PED from assay summary TSV... "
p-link --no-fid --no-parents --no-sex --allow-no-sex --missing-genotype N --map3 --nonfounders --remove ${PRIV_DATA_DIR}/ALL_assay_summary.NTC.indlist --file ${PRIV_DATA_DIR}/ALL_assay_summary.initialplink --recode --out ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink &>> ${LOG_DIR}/initialplink2masterplink.log
echo ">> ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink.ped ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink.map"


