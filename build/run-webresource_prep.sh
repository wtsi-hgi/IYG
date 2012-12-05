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


echo "run-webresource_prep.sh"

# TODO load data files


echo -n "creating md5sum versions of all resource files to be put on the web/... "
rm -rf ${PRIV_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d
mkdir -p ${PRIV_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d
OUT_DIR=${PRIV_DATA_DIR}/pred_results/web-barcode-traitshortname-md5.d
# don't need to remove webresource as everything in it is content-addressed
mkdir -p ${PUB_DATA_DIR}/webresource/
OUT_WEB_RESOURCE_DIR=${PUB_DATA_DIR}/webresource/
for trait in `(cd ${PRIV_DATA_DIR}/pred_results/web && (find * -maxdepth 0 -type d))`
do
    echo -n "${trait} "
    vars=`(cd ${PRIV_DATA_DIR}/pred_results/web/${trait} && (find * -maxdepth 0 -type d))`
    (echo "Barcode TraitShortName "`for var in ${vars}; do echo -n "${trait}_${var} "; done`) | perl -pi -e 's/[[:space:]]+$//; s/[[:space:]]+/\t/g;' > ${OUT_DIR}/${trait}.resourcemd5.txt
    echo >> ${OUT_DIR}/${trait}.resourcemd5.txt
    barcodes=$((for rescpath in `(cd ${PRIV_DATA_DIR}/pred_results/web/${trait} && (find * -maxdepth 1 -type f))`; do basename ${rescpath} .`echo ${rescpath} | awk 'BEGIN {FS=".";} NR==1 {print $NF}'`; done) | sort | uniq)
    for barcode in ${barcodes}
    do
	values=""
	for var in ${vars}
	do
	    for resource in `(cd ${PRIV_DATA_DIR}/pred_results/web/${trait}/${var} && (find * -maxdepth 0 -type f -name ${barcode}.\*))`
	    do
		rescext=`echo ${resource} | awk 'BEGIN {FS=".";} NR==1 {print $NF}'`
		md5sum=`md5sum ${PRIV_DATA_DIR}/pred_results/web/${trait}/${var}/${resource} | awk '{print $1;}'`
		# echo "var [${var}] barcode [${barcode}] trait [${trait}] rescext [${rescext}] resource [${resource}]"
		if [[ "${rescext}" == "svg" ]]; then
		    svgmd5=${md5sum}
		    gzip -c ${PRIV_DATA_DIR}/pred_results/web/${trait}/${var}/${resource} > ${OUT_WEB_RESOURCE_DIR}/${svgmd5}.svgz
		    md5sum=`md5sum ${OUT_WEB_RESOURCE_DIR}/${svgmd5}.svgz | awk '{print $1;}'`
		    mv ${OUT_WEB_RESOURCE_DIR}/${svgmd5}.svgz ${OUT_WEB_RESOURCE_DIR}/${md5sum}.svgz
		    # TODO gen PNG here?
		    values="${values}${md5sum}.svgz	"
		elif [[ "${rescext}" == "svgz" ]]; then
		    cp ${PRIV_DATA_DIR}/pred_results/web/${trait}/${var}/${resource} ${OUT_WEB_RESOURCE_DIR}/${md5sum}.svgz
		    # TODO gen PNG here?
		    values="${values}${md5sum}.svgz	"
		else 
		    echo "Encountered resource with unsupported extension ${rescext}"
		fi
	    done
	done
	echo "${barcode} ${trait} ${values}" | perl -pi -e 's/[[:space:]]+$//; s/[[:space:]]+/\t/g;' >> ${OUT_DIR}/${trait}.resourcemd5.txt
	echo >> ${OUT_DIR}/${trait}.resourcemd5.txt
    done
done
echo "done."


