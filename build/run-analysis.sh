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

echo "Initializing the jammer..."

mkdir -p ${PRED_DATA_DIR}

##########################
#3. generate ABO predictions
#MANUAL/OPTIONAL: analyse/abo/abo-avg.pl can be used in looking at dirty intensities
#put in public_data/pred_results/
echo "Predicting ABO blood type..."
mkdir ${PRED_DATA_DIR}/ABO/
(cd ${PRIV_DATA_DIR} && p-link --noweb --file iyg --missing-genotype 0 --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out abo)
${IYG_DIR}/analyse/abo/abo-matic.pl ${PRIV_DATA_DIR}/abo.ped > ${PRED_DATA_DIR}/ABO/abo-matic.txt

##########################
#4. generate sex predictions
#use analyse/sex/sex-intensity.pl to produce sex-info.txt file
#MANUAL: use analyse/sex/sexer.R to produce sex assignments as sexpred.txt

##########################
#5. generate Y predictions
echo "Predicting Y haplogroup..."
YFIT_DIR=${IYG_DIR}/analyse/tree/Yfitter
mkdir ${PRED_DATA_DIR}/Y/
# extract Y chromosome and convert to qcall format
p-link --noweb --file ${PRIV_DATA_DIR}/iyg --chr Y --transpose --recode --out ${PRED_DATA_DIR}/Y/out
${YFIT_DIR}/tped2qcall.py out > out.qcall

# do the haplogrouping
${YFIT_DIR}/Yfitter -m -q 1 ${YFIT_DIR}/karafet_tree_b37.xml ${PRED_DATA_DIR}/Y/out.qcall > ${PRED_DATA_DIR}/Y/out.yfit

# name the haplogroups
awk 'NF < 5' ${PRED_DATA_DIR}/Y/out.yfit | awk '{print $1,$3}' > ${PRED_DATA_DIR}/Y/out.haps
awk 'NF == 10' ${PRED_DATA_DIR}/Y/out.yfit | awk '{print $1,"BDE"}' >> ${PRED_DATA_DIR}/Y/out.haps
awk 'NF == 28' ${PRED_DATA_DIR}/Y/out.yfit | awk '{print $1,"Ambig1"}' >> ${PRED_DATA_DIR}/Y/out.haps
awk 'NF != 10 && NF != 28 && NF > 5 && NF <= 32' ${PRED_DATA_DIR}/Y/out.yfit | awk '{print $1,"Ambig2"}' >> ${PRED_DATA_DIR}/Y/out.haps
awk 'NF > 32' ${PRED_DATA_DIR}/Y/out.yfit | awk '{print $1,"Unknown"}' >> ${PRED_DATA_DIR}/Y/out.haps

#add HTML
${YFIT_DIR}/addText.py ${PUB_DATA}/tree/Ychromtext.txt ${PRED_DATA_DIR}/Y/out.haps | sort -k1,1n > ${PRED_DATA_DIR}/Y/Youtput.txt


##########################
#6. generate MT predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

##########################
#7. generate PCA predictions
echo "Performing world-wide PCA..."
mkdir ${PRED_DATA_DIR}/AIM/
#create merged file for PCA
p-link --noweb --bfile ${PUB_DATA_DIR}/pca/1KGdata --merge ${PRIV_DATA_DIR}/iyg.ped ${PRIV_DATA_DIR}/iyg.map --extract ${PUB_DATA_DIR}/pca/PCAsnps.txt --out ${PRED_DATA_DIR}/AIM/1KG_IYG_merged --make-bed

#run PCA
R --no-restore --no-save --args ${PRED_DATA_DIR}/AIM ${PUB_DATA_DIR}/pca <${IYG_DIR}/analyse/pca/doPCA.R

#make plots
R --no-restore --no-save --args ${PRED_DATA_DIR}/AIM/PCA_worldwide.txt ${PRED_DATA_DIR}/AIM/ < ${IYG_DIR}/analyse/pca/plotPCA.R 

##########################
#8. generate QT predictions
#in directory with mangroveinput.ped, mangroveinput.map, *.grovebeta
#Standard QTs
#Note: ones with few SNPs kind of suck!!
echo "Predicting QTs and generating images..."
mkdir -p ${PRED_DATA_DIR}/BALD/IYGHIST/
R --no-restore --no-save --args BALD ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/BMI/IYGHIST/
mkdir ${PRED_DATA_DIR}/BMI/POPDIST/
R --no-restore --no-save --args BMI ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/BP/IYGHIST/
mkdir ${PRED_DATA_DIR}/BP/POPDIST/
R --no-restore --no-save --args BP ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/CAFE/IYGHIST/
mkdir ${PRED_DATA_DIR}/CAFE/POPDIST/
R --no-restore --no-save --args CAFE ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/EYE/IYGHIST/
R --no-restore --no-save --args EYE ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/FPG/IYGHIST/
mkdir ${PRED_DATA_DIR}/FPG/POPDIST/
R --no-restore --no-save --args FPG ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/HDLC/IYGHIST/
mkdir ${PRED_DATA_DIR}/HDLC/POPDIST/
R --no-restore --no-save --args HDLC ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/MPV/IYGHIST/
mkdir ${PRED_DATA_DIR}/MPV/POPDIST/
R --no-restore --no-save --args MPV ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/SMOK/IYGHIST/
mkdir ${PRED_DATA_DIR}/SMOK/POPDIST/
R --no-restore --no-save --args SMOK ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/TC/IYGHIST/
mkdir ${PRED_DATA_DIR}/TC/POPDIST/
R --no-restore --no-save --args TC ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R
mkdir -p ${PRED_DATA_DIR}/WHR/IYGHIST/
mkdir ${PRED_DATA_DIR}/WHR/POPDIST/
R --no-restore --no-save --args WHR ${PRIV_DATA_DIR} ${PUB_DATA_DIR} ${PRED_DATA_DIR} <${IYG_DIR}/analyse/qt/mangrove-it.R

mkdir ${PRED_DATA_DIR}/NEAND 
##still broken
#R --no-restore --no-save --args NEAND <${IYG_DIR}/analyse/qt/mangrove-it.R


