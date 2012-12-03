args <- commandArgs(trailingOnly = TRUE)
library(Mangrove)

source("calcBetas.R")


#here we go, with this trait
thistrait<-args[1]


#Mangrove data
ped<-readPed("mangroveinput")
betas<-readBetas(paste(thistrait,"grovebeta",sep="."),h=T)

#trait Data
traitinfo<-read.table("master-trait-info.txt",h=T,sep="\t")

thisunits<-traitinfo$Units[traitinfo$ShortName==thistrait]
popmean<-traitinfo$Mean[traitinfo$ShortName==thistrait]
popsd<-traitinfo$SD[traitinfo$ShortName==thistrait]

popleft<-popmean-4*popsd
popright<-popmean+4*popsd
popx<-seq(popleft,popright,length=200)
popy<-dnorm(popx,popmean,popsd)

varexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/popsd

#Run Mangrove
predictions<-calcBetas(ped,betas)
absolutepreds<-applyBetas(predictions,popmean,1)

#Get ready to produce output
setwd(thistrait)


output<-cbind(ped$ID,predictions,absolutepreds)
write.table(output,file=paste(thistrait,"grove.out",sep="-"),quote=F,row.names=F,col.names=F)

for (i in 1:length(predictions)){
	svg(paste(names(predictions)[i],"bh",thistrait,"svg",sep="."),bg="transparent")
	hist(predictions,breaks=30,axes=F,xlab="",ylab="",main="")
	abline(v=predictions[i],lty=2,col=2,lwd=2)
	dev.off()
	
	svg(paste(names(absolutepreds)[i],"ab",thistrait,"svg",sep="."),bg="transparent")
	thisy<-dnorm(popx,absolutepreds[i],popsd-sqrt(varexpl))
	plot(popx,popy,type="l",bty="n",yaxt="n",ylab="",
		xlab=paste(thistrait,thisunits,sep=" "),ylim=c(0,1.1*max(popy)),lwd=2)
	lines(popx,thisy,col=2,lwd=2)
	dev.off()
}

