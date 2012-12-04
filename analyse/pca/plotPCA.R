#usage: plotPCA.R --args infile outdir
args <- commandArgs(trailingOnly = TRUE)

## read in the data
a <- read.table(args[1],header=T)

# get the populations out of the names
popn <- sapply(strsplit(as.character(a[,1]),"-"),function(x) x[2])
popn[is.na(popn)] <- "IYG"

# set the continents and continent colours
euro <- c("CEU","TSI","GBR","IBS","FIN")
afr <- c("ASW","LWK","YRI")
asia <- c("CHB","CHS","JPT")
america <- c("CLM","MXL","PUR")

cols <- rep("grey",length(popn))
cols[popn %in% euro] <- "green"
cols[popn %in% afr] <- "red"
cols[popn %in% asia] <- "blue"
cols[popn %in% america] <- "orange"

## make the all-sample PCA
svg(paste(args[2],"/","all-iyg-pca.svg",sep=""))
par(mar=c(0,0,0,0))
plot(a[,2],a[,3],col=cols,pch=20,axes=F,xlab="",ylab="",cex=2)
legend(4,9,text.font=c(1,1,1,1,3,1),legend=c("Africans","Europeans","East Asians","Central Americans","Inside Your Genome","participants"),pch=20,col=c("red","green","blue","orange","grey",NA),cex=1.5,pt.cex=2,bty="n")
dev.off()
stop()

## the function for making per-individual plots
makePCA <- function(you){
	
	# figure out where the arrow should go
	delta1 <- 0.3
	delta2 <- 1
	x0 <- 4
	y0 <- 2
	x <- a[a[,1] == you,2]
	y <- a[a[,1] == you,3]
	flip <- 1
	if (y < y0 & x > x0) flip <- -1
	theta <- atan((y - y0)/(x - x0))
	L <- sqrt((x - x0)^2 + (y - y0)^2)
	L2 <- L - delta2
	x2 <- flip*L2*cos(theta) + x
	y2 <- flip*L2*sin(theta) + y
	x1 <- x + delta1*cos(theta)
	y1 <- y + delta1*sin(theta)
	
	# plot it all
	plot(a[popn != "IYG",2],a[popn != "IYG",3],col=cols[popn != "IYG"],pch=20,axes=F,xlab="",ylab="",cex=2)
	text(x0,y0,"You!",font=2,cex=2)
	arrows(x2,y2,x1,y1,lwd=2)
	points(a[a[,1] == you,2],a[a[,1] == you,3],pch=20,col="black",cex=2)
	legend(4,9,legend=c("Africans","Europeans","East Asians","Central Americans"),pch=20,col=c("red","green","blue","orange"),cex=1.5,pt.cex=2,bty="n")
}


## make all per-individual plots
for (sam in a[popn == "IYG",1]){
	print(sam)
	svg(paste(args[2],"/",sam,".svg",sep=""))
	par(mar=c(0,0,0,0))
	makePCA(sam)
	dev.off()
	}