#usage: doPCA.R --args indir pubdatadir
args <- commandArgs(trailingOnly = TRUE)
indir<-args[1]
refdir<-args[2]

library(snpStats)

# read in a merge ped file with 1KG and IYG individuals in
dat <- read.plink(paste(indir,"/",'1KG_IYG_merged',sep=""))$genotypes

# read in populations
pops <- read.table(paste(refdir,"/",'./1KG_pops.txt',sep=""),sep="\t",header=T)
popn <- pops[,2]
names(popn) <- pops[,1]

#identify 1KG samples
hapmap <- dimnames(dat)[[1]] %in% names(popn)
dathm <- dat[hapmap,]

# calculate loadings
xxmat <- xxt(dathm)
evv <- eigen(xxmat, symmetric = TRUE)
pcs <- evv$vectors[, 1:5]
evals <- evv$values[1:5]
btr <- snp.pre.multiply(dathm, diag(1/sqrt(evals)) %*% t(pcs))

#project
pcs <- snp.post.multiply(dat, t(btr))

labs <- dimnames(dat)[[1]]
labs[hapmap] <- paste(labs[hapmap],popn[labs[hapmap]],sep="-")

write.table(data.frame(IDs=labs,PC1 = pcs[,1],PC2 = pcs[,2], PC3=pcs[,3]),file=paste(indir,"/",'pred.PCA.txt',sep=""),row.names=F,sep="\t",quote=F)
