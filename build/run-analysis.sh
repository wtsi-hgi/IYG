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

#1. run QC on raw TSV
#calculate missing rate by plate
#analyse/qc/missing-by-plate.pl
#produce missing-by-plate.txt
#MANUAL: look at output and produce a list of SNPs called failed-snps.txt

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

#3. generate ABO predictions
#p-link --noweb --file ALL_assay_summary.publicid.masterplink --missing-genotype N --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out abo
(cd ${PRIV_DATA_DIR} && p-link --noweb --file iyg --missing-genotype 0 --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out abo)
${IYG_DIR}/analyse/abo/abo-matic.pl ${PRIV_DATA_DIR}/abo.ped > ${PRIV_DATA_DIR}/abo-matic.txt

#MANUAL/OPTIONAL: analyse/abo/abo-avg.pl can be used in looking at dirty intensities

#4. generate sex predictions
#use analyse/sex/sex-intensity.pl to produce sex-info.txt file
#MANUAL: use analyse/sex/sexer.R to produce sex assignments as sexpred.txt

#5. generate Y predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

#6. generate PCA predictions
#MANUAL: create worldpca.txt
#TODO Note, fix dirs to correspond to launch??
R --no-restore --no-save --args ../pca/worldpca.txt ${PRIV_DATA_DIR}/pca/ <analyse/pca/plotPCA.R

#7. generate MT predictions
#NOTE! This currently is not easily pipelineable. We can add the processed files for v1, and discuss options for v2. We'll need to do a pi->barcode transform, though.

#8. generate QT predictions
#in directory with mangroveinput.ped, mangroveinput.map, *.grovebeta
#Standard QTs
##mkdir BMI 
##R --no-restore --no-save --args BMI <mangrove-it.R
##mkdir BP
##R --no-restore --no-save --args BP <mangrove-it.R
##mkdir FPG 
##R --no-restore --no-save --args FPG <mangrove-it.R
##mkdir HDLC 
##R --no-restore --no-save --args HDLC <mangrove-it.R
##mkdir MPV 
##R --no-restore --no-save --args MPV <mangrove-it.R
##mkdir SMOK 
##R --no-restore --no-save --args SMOK <mangrove-it.R
##mkdir TC 
##R --no-restore --no-save --args TC <mangrove-it.R
##mkdir WHR 
##R --no-restore --no-save --args WHR <mangrove-it.R

#this kind of sucks
##mkdir BALD 
##R --no-restore --no-save --args BALD <mangrove-it.R

###mkdir NEAND 
#still broken
#R --no-restore --no-save --args NEAND <mangrove-it.R

#Special QTs
##mkdir CAFE 
##R --no-restore --no-save <mangrove-it-CAFE.R
##mkdir EYE 
##R --no-restore --no-save <mangrove-it-EYE.R


