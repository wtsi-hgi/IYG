#!/bin/bash

usage="
get-sot.sh public_data/sot-snp-category-trait-shortname.txt public_data/sotdesc/
"

SOT_LIST_FILE="$1"
PUB_DATA_DIR="$2"
DEST_DIR=${PUB_DATA_DIR}/desc/
IYG_DIR=`dirname $0`/../../

WGET="wget --no-check-certificate"

if [[ ! -f ${SOT_LIST_FILE} ]]; 
then
    echo "${usage}"
    exit 2
fi


# get trait_description_SHORTNAME from https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_description_SHORTNAME
TRAIT_DESC_DIR="${DEST_DIR}/sot_trait_descriptions"
if [[ ! -d ${TRAIT_DESC_DIR} ]];
then
    echo "directory ${TRAIT_DESC_DIR} does not exist, attempting to create it"
    mkdir -p ${TRAIT_DESC_DIR} || exit 1;
fi
for trait_shortname in `awk 'BEGIN {FS="\t";} NR!=1 {traits[$4]=1;} END {for(trait in traits) {print trait;}}' ${SOT_LIST_FILE}`; 
do 
    url="https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_description_${trait_shortname}"
    echo "fetching ${url}"
    ${WGET} -O - "${url}" | perl -MJSON -e 'my $buffer;while ( <STDIN> ){$buffer .= $_;} my $doc = decode_json $buffer; print $doc->{'data'}->{'html'};' > ${TRAIT_DESC_DIR}/${trait_shortname}.html
done;

# get trait_snp_description_SHORTNAME_SNPNAME from https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_snp_description_SHORTNAME_SNPNAME
TRAIT_SNP_DESC_DIR="${DEST_DIR}/sot_trait_snp_descriptions"
if [[ ! -d ${TRAIT_SNP_DESC_DIR} ]];
then
    echo "directory ${TRAIT_SNP_DESC_DIR} does not exist, attempting to create it"
    mkdir -p ${TRAIT_SNP_DESC_DIR} || exit 1;
fi
for trait_shortname_snp in `awk 'BEGIN {FS="\t";} NR!=1 {print $4"_"$1;}' ${SOT_LIST_FILE}`; 
do 
    url="https://sot.iyg-results.org/ep/api/1/getHTML?apikey=snp-o-trait&padID=trait_snp_description_${trait_shortname_snp}"
    echo "fetching ${url}"
    ${WGET} -O - "${url}" | perl -MJSON -e 'my $buffer;while ( <STDIN> ){$buffer .= $_;} my $doc = decode_json $buffer; print $doc->{'data'}->{'html'};' > ${TRAIT_SNP_DESC_DIR}/${trait_shortname_snp}.html
done;


echo "Translating SOT short names into new short names..."
mkdir -p ${DEST_DIR}/trait_descriptions
rm ${DEST_DIR}/trait_descriptions/*.html
mkdir -p ${DEST_DIR}/trait_snp_descriptions
rm ${DEST_DIR}/trait_snp_descriptions/*.html
${IYG_DIR}/analyse/get-sot/translatesot.pl ${PUB_DATA_DIR}

echo "Generating Files Of File Names..."
find ${PUB_DATA_DIR}/desc/trait_descriptions/*.html > ${DEST_DIR}/trait_descriptions.fofn
find ${PUB_DATA_DIR}/desc/trait_snp_descriptions/*.html > ${DEST_DIR}/trait_snp_descriptions.fofn

