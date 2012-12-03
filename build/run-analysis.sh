#1. run QC on raw TSV
#calculate missing rate by plate
#analyse/qc/missing-by-plate.pl
#produce missing-by-plate.txt
#MANUAL: look at output and produce a list of SNPs called failed-snps.txt

#2. run QC on Josh's input PED file
#remove failed SNPs
plink --noweb --file ALL_assay_summary.fakebarcode.masterplink --missing-genotype N --exclude failed-snps.txt --make-bed --out iyg-1

#view missing rates in this file (autosomes only)
#MANUAL: produce sample-fails.txt for exclusions (currently MISS > 0.5)
#MANUAL: produce flagged-samples.txt for flagging (currently 0.05 > MISS > 0.50)

#MANUAL: negative-snps.txt is file of SNPs on - strand in Source file
#negative-snps.txt can be reproduced using matchalleles.pl, ensembl-alleles.txt, compare-alleles.pl,
#snpseqs.txt

#removed failed samples, flip strands
plink --noweb --bfile iyg-1 --remove sample-fails.txt --flip negative-snps.txt --make-bed --out iyg-2

#MANUAL: max-ibs.pl can be used, along with PLINK --genome, to find duplicates.

#3. generate ABO predictions
plink --noweb --file ALL_assay_summary.fakebarcode.masterplink --missing-genotype N --snps rs8176743,rs8176746,rs8176747,rs8176719 --recode --out abo

#MANUAL: analyse/abo/abo-avg.pl can be used in looking at dirty intensities
#generate abo predictions using abo-matic.pl

#4. generate sex predictions
#use analyse/sex/sex-intensity.pl to produce sex-info.txt file
#MANUAL: use analyse/sex/sexer.R to produce sex assignments as sexpred.txt

#5. generate Y predictions


#6. generate PCA predictions
#MANUAL: create worldpca.txt
#run analyse/pca/plotPCA.R

#7. generate MT predictions

#8. generate QT predictions
#in directory with mangroveinput.ped, mangroveinput.map, *.grovebeta
#Standard QTs
mkdir BMI 
R --no-restore --no-save --args BMI <mangrove-it.R
mkdir BP
R --no-restore --no-save --args BP <mangrove-it.R
mkdir FPG 
R --no-restore --no-save --args FPG <mangrove-it.R
mkdir HDLC 
R --no-restore --no-save --args HDLC <mangrove-it.R
mkdir MPV 
R --no-restore --no-save --args MPV <mangrove-it.R
mkdir SMOK 
R --no-restore --no-save --args SMOK <mangrove-it.R
mkdir TC 
R --no-restore --no-save --args TC <mangrove-it.R
mkdir WHR 
R --no-restore --no-save --args WHR <mangrove-it.R
#Special QTs
mkdir CAFE 
R --no-restore --no-save --args CAFE <mangrove-it.R
mkdir EYE 
R --no-restore --no-save --args EYE <mangrove-it.R
mkdir BALD 
R --no-restore --no-save --args BALD <mangrove-it.R
mkdir NEAND 
R --no-restore --no-save --args NEAND <mangrove-it.R

#9. run SOT annotations
#run MP's SOT puller?
#analyse/sot/translatesot.pl
