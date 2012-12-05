#!/bin/bash

#To run in testing mode;
# IYG_DIR=.
# PRIV_DATA_DIR=${IYG_DIR}/priv/
# PUB_DATA_DIR=${IYG_DIR}/public_data/
# LOG_DIR=${IYG_DIR}/log/


if [[ -z "${IYG_DIR}" || ! -d ${IYG_DIR} ]]; 
    then
    echo "Must set environment variable IYG_DIR to a valid directory"
    exit 1
fi

if [[ -z "${PRIV_DATA_DIR}" || ! -d ${PRIV_DATA_DIR} ]]; 
    then
    echo "Must set environment variable PRIV_DATA_DIR to a valid directory"
    exit 1
fi

if [[ -z "${PUB_DATA_DIR}" || ! -d ${PUB_DATA_DIR} ]]; 
    then
    echo "Must set environment variable PUB_DATA_DIR to a valid directory"
    exit 1
fi

if [[ -z "${LOG_DIR}" || ! -d ${LOG_DIR} ]]; 
    then
    echo "Must set environment variable LOG_DIR to a valid directory"
    exit 1
fi

if [[ ! -e ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink.ped ]]
    then
    echo "PRIV_DATA_DIR does not contain ALL_assay_summary.masterplink.ped"
    exit 1
fi

WEB_DATA_DIR=${PRIV_DATA_DIR}/pred_results/web/
rm -rf ${PRIV_DATA_DIR}/pred_results/web/ && mkdir -p ${WEB_DATA_DIR}

OUT_DATA_DIR=${PRIV_DATA_DIR}/pred_results/out/
rm -rf ${PRIV_DATA_DIR}/pred_results/out/ && mkdir -p ${OUT_DATA_DIR}


##########################
#1. run QC on raw TSV
#calculate missing rate by plate
#analyse/qc/missing-by-plate.pl
#produce missing-by-plate.txt
#MANUAL: look at output and produce a list of SNPs called failed-snps.txt
if [[ ! -e ${PRIV_DATA_DIR}/qc/failed-snps.txt ]]
then
    echo "[ERROR] Required file ${PRIV_DATA_DIR}/qc/failed-snps.txt not present! Please perform manual SNP QC and re-run once this file exists."
    exit 1
fi


##########################
#2. run QC on Josh's input PED file
#remove failed SNPs
p-link --noweb --file ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink --missing-genotype N --exclude ${PRIV_DATA_DIR}/qc/failed-snps.txt --make-bed --out ${PRIV_DATA_DIR}/iyg-snpqc &> ${LOG_DIR}/plink-snpqc.log

#view missing rates in this file (autosomes only)
#MANUAL: produce sample-fails.txt for exclusions (currently MISS > 0.5)
#MANUAL: produce flagged-samples.txt for flagging (currently 0.05 > MISS > 0.50)

#MANUAL: negative-snps.txt is file of SNPs on - strand in Source file
#analyse/qc/negative-snps.txt can be reproduced using matchalleles.pl, ensembl-alleles.txt, compare-alleles.pl, snpseqs.txt
# TODO use flagged-samples.txt somewhere
qc_files="sample-fails.txt flagged-samples.txt negative-snps.txt"
for qc_file in ${qc_files}
do 
    if [[ ! -e ${PRIV_DATA_DIR}/qc/${qc_file} ]]
    then
	echo "[ERROR] Required file ${PRIV_DATA_DIR}/qc/${qc_file} not present! Please perform manual sample QC and re-run once this file exists."
	exit 1
    fi
done
p-link --noweb --bfile ${PRIV_DATA_DIR}/iyg-snpqc --remove ${PRIV_DATA_DIR}/qc/sample-fails.txt --flip ${PRIV_DATA_DIR}/qc/negative-snps.txt --make-bed --out ${PRIV_DATA_DIR}/iyg &> ${LOG_DIR}/plink-finalqc.log

#MANUAL: max-ibs.pl can be used, along with PLINK --genome, to find duplicates.

#create input pedfile for DB load
p-link --noweb --bfile ${PRIV_DATA_DIR}/iyg --recode --out ${PRIV_DATA_DIR}/iyg &> ${LOG_DIR}/plink-final-recodeped.log

echo "Initializing the jammer..."

##########################
#3. generate ABO predictions
#MANUAL/OPTIONAL: analyse/abo/abo-avg.pl can be used in looking at dirty intensities
#put in public_data/pred_results/
echo "Predicting ABO blood type..."
mkdir -p ${OUT_DATA_DIR}/ABO/
p-link --noweb --file ${PRIV_DATA_DIR}/ALL_assay_summary.masterplink --missing-genotype N --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out ${OUT_DATA_DIR}/ABO/abo &> ${LOG_DIR}/plink-abo.log
${IYG_DIR}/analyse/abo/abo-matic.pl ${OUT_DATA_DIR}/ABO/abo.ped > ${OUT_DATA_DIR}/ABO/pred.ABO.txt 2> ${LOG_DIR}/abo-matic.log

##########################
#4. generate sex predictions
#use analyse/sex/sex-intensity.pl to produce sex-info.txt file
#MANUAL: use analyse/sex/sexer.R to produce sex assignments as sexpred.txt

##########################
#5. generate Y predictions
echo "Predicting Y haplogroup... "
TREE_DIR=${IYG_DIR}/analyse/tree
YFIT_BIN=${TREE_DIR}/Yfitter
if [[ ! -e ${YFIT_BIN} ]]
then
    echo "Attempting to build Yfitter... "
    (cd ${TREE_DIR} && g++ -o Yfitter Yfitter.cpp || (echo "could not build Yfitter" && exit 1))  &> ${LOG_DIR}/yfitter-build.log
fi
mkdir -p ${OUT_DATA_DIR}/Y/
# extract Y chromosome and convert to qcall format
p-link --noweb --file ${PRIV_DATA_DIR}/iyg --chr Y --transpose --recode --out ${OUT_DATA_DIR}/Y/out &> ${LOG_DIR}/plink-Yextract.log
${TREE_DIR}/tped2qcall.py ${OUT_DATA_DIR}/Y/out > ${OUT_DATA_DIR}/Y/out.qcall &> ${LOG_DIR}/tped2qcall.log

# do the haplogrouping
${YFIT_BIN} -m -q 1 ${TREE_DIR}/karafet_tree_b37.xml ${OUT_DATA_DIR}/Y/out.qcall > ${OUT_DATA_DIR}/Y/out.yfit &> ${LOG_DIR}/Yfitter.log

# name the haplogroups
awk 'NF < 5' ${OUT_DATA_DIR}/Y/out.yfit | awk '{print $1,$3}' > ${OUT_DATA_DIR}/Y/out.haps
awk 'NF == 10' ${OUT_DATA_DIR}/Y/out.yfit | awk '{print $1,"BDE"}' >> ${OUT_DATA_DIR}/Y/out.haps
awk 'NF == 28' ${OUT_DATA_DIR}/Y/out.yfit | awk '{print $1,"Ambig1"}' >> ${OUT_DATA_DIR}/Y/out.haps
awk 'NF != 10 && NF != 28 && NF > 5 && NF <= 32' ${OUT_DATA_DIR}/Y/out.yfit | awk '{print $1,"Ambig2"}' >> ${OUT_DATA_DIR}/Y/out.haps
awk 'NF > 32' ${OUT_DATA_DIR}/Y/out.yfit | awk '{print $1,"Unknown"}' >> ${OUT_DATA_DIR}/Y/out.haps

#add HTML
${TREE_DIR}/addText.py ${PUB_DATA_DIR}/tree/Ychromtext.txt ${OUT_DATA_DIR}/Y/out.haps | sort -k1,1n > ${OUT_DATA_DIR}/Y/Youtput.txt &> ${LOG_DIR}/addText.log


##########################
#6. generate MT predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

##########################
#7. generate PCA predictions
echo "Performing world-wide PCA..."
mkdir -p ${WEB_DATA_DIR}/AIM/AIM/
mkdir -p ${OUT_DATA_DIR}/AIM/
#create merged file for PCA
p-link --noweb --bfile ${PUB_DATA_DIR}/pca/1KGdata --merge ${PRIV_DATA_DIR}/iyg.ped ${PRIV_DATA_DIR}/iyg.map --extract ${PUB_DATA_DIR}/pca/PCAsnps.txt --out ${OUT_DATA_DIR}/AIM/1KG_IYG_merged --make-bed &> ${LOG_DIR}/pca-plink-merge.log

#run PCA
R --no-restore --no-save --args ${OUT_DATA_DIR}/AIM ${PUB_DATA_DIR}/pca < ${IYG_DIR}/analyse/pca/doPCA.R &> ${LOG_DIR}/pca-doPCA.log

echo "Making world-wide PCA plots..."
#make plots
R --no-restore --no-save --args ${OUT_DATA_DIR}/AIM/nopred.PCA.txt ${WEB_DATA_DIR}/AIM/AIM/ < ${IYG_DIR}/analyse/pca/plotPCA.R  &> ${LOG_DIR}/pca-plotPCA.log


##########################
#8. generate QT predictions
#in directory with mangroveinput.ped, mangroveinput.map, *.grovebeta
#Standard QTs
#Note: ones with few SNPs kind of suck!!

# These three have no population data
echo -n "Predicting QTs and generating images for qt1 traits... "
for trait in BALD EYE NEAND
do
    echo -n "${trait} "
    mkdir -p ${WEB_DATA_DIR}/${trait}/IYGHIST/
    mkdir -p ${OUT_DATA_DIR}/${trait}/
    R --no-restore --no-save --args ${trait} ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${WEB_DATA_DIR} ${OUT_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R 2> ${LOG_DIR}/qt1-mangroveit.log
done
echo "done."

# These nine have population data
echo -n "Predicting QTs and generating images for qt2 traits... "
for trait in BMI BP CAFE FPG HDLC MPV SMOK TC WHR
do
    echo -n "${trait} "
    mkdir -p ${WEB_DATA_DIR}/${trait}/IYGHIST/
    mkdir -p ${WEB_DATA_DIR}/${trait}/POPDIST/
    mkdir -p ${OUT_DATA_DIR}/${trait}/
    R --no-restore --no-save --args ${trait} ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${WEB_DATA_DIR} ${OUT_DATA_DIR} < ${IYG_DIR}/analyse/qt/mangrove-it.R 2> ${LOG_DIR}/qt2-mangroveit.log
done
echo "done."


