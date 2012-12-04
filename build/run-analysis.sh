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
PRED_DATA_DIR=${PUB_DATA_DIR}/pred_results/

if [[ ! -e ${PRIV_DATA_DIR}/iyg.ped ]]
    then
    echo "Must specify PRIV_DATA_DIR as first argument"
    exit 1
fi

##########################
#1. run QC on raw TSV
#calculate missing rate by plate
#analyse/qc/missing-by-plate.pl
#produce missing-by-plate.txt
#MANUAL: look at output and produce a list of SNPs called failed-snps.txt

##########################
#2. run QC on Josh's input PED file
#remove failed SNPs
###p-link --noweb --file ALL_assay_summary.publicid.masterplink --missing-genotype N --exclude failed-snps.txt --make-bed --out iyg-1

#view missing rates in this file (autosomes only)
#MANUAL: produce sample-fails.txt for exclusions (currently MISS > 0.5)
#MANUAL: produce flagged-samples.txt for flagging (currently 0.05 > MISS > 0.50)

#MANUAL: negative-snps.txt is file of SNPs on - strand in Source file
#analyse/qc/negative-snps.txt can be reproduced using matchalleles.pl, ensembl-alleles.txt, compare-alleles.pl, snpseqs.txt

#removed failed samples, flip strands
###p-link --noweb --bfile iyg-1 --remove sample-fails.txt --flip negative-snps.txt --make-bed --out iyg-2

#MANUAL: max-ibs.pl can be used, along with PLINK --genome, to find duplicates.

#create input pedfile for DB load
###p-link --noweb --bfile iyg-2 --recode --out iyg

mkdir -p ${PRED_DATA_DIR}

##########################
#3. generate ABO predictions
#MANUAL/OPTIONAL: analyse/abo/abo-avg.pl can be used in looking at dirty intensities
#put in public_data/pred_results/
mkdir ${PRED_DATA_DIR}/ABO/
(cd ${PRIV_DATA_DIR} && p-link --noweb --file iyg --missing-genotype 0 --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out abo)
${IYG_DIR}/analyse/abo/abo-matic.pl ${PRIV_DATA_DIR}/abo.ped > ${PRED_DATA_DIR}/ABO/abo-matic.txt

##########################
#4. generate sex predictions
#use analyse/sex/sex-intensity.pl to produce sex-info.txt file
#MANUAL: use analyse/sex/sexer.R to produce sex assignments as sexpred.txt

##########################
#5. generate Y predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

##########################
#6. generate PCA predictions
mkdir ${PRED_DATA_DIR}/AIM/
#create merged file for PCA
p-link --noweb --bfile ${PUB_DATA_DIR}/pca/1KGdata --merge ${PRIV_DATA_DIR}/iyg.ped ${PRIV_DATA_DIR}/iyg.map --extract ${PUB_DATA_DIR}/pca/PCAsnps.txt --out ${PRED_DATA_DIR}/AIM/1KG_IYG_merged --make-bed

#run PCA
R --no-restore --no-save --args ${PRED_DATA_DIR}/AIM ${PUB_DATA_DIR}/pca <${IYG_DIR}/analyse/pca/doPCA.R

#make plots
R --no-restore --no-save --args ${PRED_DATA_DIR}/AIM/PCA_worldwide.txt ${PRED_DATA_DIR}/AIM/ < ${IYG_DIR}/analyse/pca/plotPCA.R 

##########################
#7. generate MT predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

##########################
#8. generate QT predictions
#in directory with mangroveinput.ped, mangroveinput.map, *.grovebeta
#Standard QTs
mkdir ${PRED_DATA_DIR}/BMI/ 
R --no-restore --no-save --args BMI <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/BP/
R --no-restore --no-save --args BP <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/FPG/
R --no-restore --no-save --args FPG <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/HDLC/
R --no-restore --no-save --args HDLC <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/MPV/
R --no-restore --no-save --args MPV <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/SMOK/ 
R --no-restore --no-save --args SMOK <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/TC/
R --no-restore --no-save --args TC <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir ${PRED_DATA_DIR}/WHR/
R --no-restore --no-save --args WHR <${IYG_DIR}/analyse/qt/mangrove-it.R

#this kind of sucks
mkdir ${PRED_DATA_DIR}/BALD 
R --no-restore --no-save --args BALD <${IYG_DIR}/analyse/qt/mangrove-it.R

mkdir ${PRED_DATA_DIR}/NEAND 
##still broken
R --no-restore --no-save --args NEAND <${IYG_DIR}/analyse/qt/mangrove-it.R

#Special QTs, this is sloppy.
mkdir ${PRED_DATA_DIR}/CAFE 
R --no-restore --no-save <${IYG_DIR}/analyse/qt/mangrove-it-CAFE.R
mkdir ${PRED_DATA_DIR}/EYE 
R --no-restore --no-save <${IYG_DIR}/analyse/qt/mangrove-it-EYE.R


