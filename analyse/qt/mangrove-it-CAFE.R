args <- commandArgs(trailingOnly = TRUE)
library(Mangrove)

source("calcBetas.R")

#here we go, with this trait
thistrait<-"CAFE"

#Mangrove data
ped<-readPed("mangroveinput")
betas<-readBetas(paste(thistrait,"grovebeta",sep="."),h=T)

#trait Data
traitinfo<-read.table("master-trait-info.txt",h=T,sep="\t")
thisunits<-traitinfo$Units[traitinfo$ShortName==thistrait]
thisname<-traitinfo$TraitName[traitinfo$ShortName==thistrait]

UKmean<-1.65
UKsd<-2.25
NLmean<-3.91
NLsd<-2.85


popleft<-UKmean-4*UKsd
popright<-NLmean+4*NLsd
popx<-seq(popleft,popright,length=200)
UKy<-dnorm(popx,UKmean,UKsd)
NLy<-dnorm(popx,NLmean,NLsd)

UKvarexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/UKsd
NLvarexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/NLsd

#Run Mangrove
predictions<-calcBetas(ped,betas)
absolutepredsUK<-applyBetas(predictions,UKmean,1)
absolutepredsNL<-applyBetas(predictions,NLmean,1)

#Get ready to produce output
setwd(thistrait)


output<-cbind(ped$ID,predictions,absolutepredsUK)
write.table(output,file=paste(thistrait,"grove.out",sep="-"),quote=F,row.names=F,col.names=F)

for (i in 1:length(predictions)){
	svg(paste(names(predictions)[i],"bh",thistrait,"svg",sep="."),bg="transparent")
	hist(predictions,breaks=30,axes=F,xlab="",ylab="",main="")
	abline(v=predictions[i],lty=2,col=2,lwd=2)
	dev.off()
	
	svg(paste(names(absolutepredsUK)[i],"ab",thistrait,"svg",sep="."),bg="transparent")
	thisy<-dnorm(popx,absolutepredsUK[i],UKsd-sqrt(UKvarexpl))
	plot(popx,UKy,type="l",bty="n",yaxt="n",ylab="",
		xlab=paste(thistrait,thisunits,sep=" "),ylim=c(0,1.1*max(UKy)),lwd=2)
	lines(popx,thisy,col=2,lwd=2)
	lines(popx,NLy,lwd=2,lty=2)
	thisy<-dnorm(popx,absolutepredsNL[i],NLsd-sqrt(NLvarexpl))
	lines(popx,thisy,lwd=2,lty=2,col=2)
	legend("topright",legend=c("UK","NL"),lty=c(1,2),lwd=2,bty="n")
	dev.off()
}

