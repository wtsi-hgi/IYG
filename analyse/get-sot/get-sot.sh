#!/bin/bash

usage="
get-sot.sh public_data/sot-snp-category-trait-shortname.txt public_data/sotdesc/
"

SOT_LIST_FILE="$1"
DEST_DIR="$2"

WGET="wget --no-check-certificate"

if [[ ! -f ${SOT_LIST_FILE} ]]; 
then
    echo "${usage}"
    exit 2
fi


# get trait_description_SHORTNAME from https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_description_SHORTNAME
TRAIT_DESC_DIR="${DEST_DIR}/trait_descriptions"
if [[ ! -d ${TRAIT_DESC_DIR} ]];
then
    echo "directory ${TRAIT_DESC_DIR} does not exist, attempting to create it"
    mkdir -p ${TRAIT_DESC_DIR} || exit 1;
fi
for trait_shortname in `awk 'BEGIN {FS="\t";} NR!=1 {traits[$4]=1;} END {for(trait in traits) {print trait;}}' ${SOT_LIST_FILE}`; 
do 
    url="https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_description_${trait_shortname}"
    echo "fetching ${url}"
    ${WGET} "${url}" -O - > ${TRAIT_DESC_DIR}/${trait_shortname}.txt
done;

# get trait_snp_description_SHORTNAME_SNPNAME from https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_snp_description_SHORTNAME_SNPNAME
TRAIT_SNP_DESC_DIR="${DEST_DIR}/trait_snp_descriptions"
if [[ ! -d ${TRAIT_SNP_DESC_DIR} ]];
then
    echo "directory ${TRAIT_SNP_DESC_DIR} does not exist, attempting to create it"
    mkdir -p ${TRAIT_SNP_DESC_DIR} || exit 1;
fi
for trait_shortname_snp in `awk 'BEGIN {FS="\t";} NR!=1 {print $4"_"$1;}' ${SOT_LIST_FILE}`; 
do 
    url="https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_snp_description_${trait_shortname_snp}"
    echo "fetching ${url}"
    ${WGET} "${url}" -O - > ${TRAIT_SNP_DESC_DIR}/${trait_shortname_snp}.txt
done;

