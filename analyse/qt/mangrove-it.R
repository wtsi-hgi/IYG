args <- commandArgs(trailingOnly = TRUE)
library(Mangrove)

#QT pred fix by LJ
calcBetas<- function (ped, betas)
{
   if (any(sapply(betas$rsID, function(x) length(grep(x, dimnames(ped)[[2]]))) ==
       0)) {
       stop("Not all SNPs in the odds ratio file are present in the ped file.")
   }

   ped <- cbind(ped[,1:6],ped[,paste(rep(betas$rsID, rep(2, length(betas$rsID))), rep(c(".1", ".2"), length(betas$rsID)), sep = "")])

   out1 <- t((t(ped[, 5 + 2 * (1:((length(ped[1, ]) - 6)/2))]) ==
       (betas$RiskAllele)) + (t(ped[, 6 + 2 * (1:((length(ped[1,
       ]) - 6)/2))]) == (betas$RiskAllele)))
   missing <- (ped[, 5 + 2 * (1:((length(ped[1, ]) - 6)/2))] ==
       "N") + (ped[, 5 + 2 * (1:((length(ped[1, ]) - 6)/2))] ==
       "0") + (ped[, 6 + 2 * (1:((length(ped[1, ]) - 6)/2))] ==
       "N") + (ped[, 6 + 2 * (1:((length(ped[1, ]) - 6)/2))] ==
       "0")
   out1[missing] <- NA
   prediction <- as.numeric(((betas$beta %*% t(out1)) - sum(betas$betaBar)))
   names(prediction) <- dimnames(ped)[[1]]
   totMissing <- apply(ped[, 7:length(ped[1, ])], 1, function(x) all(x ==
       "0" | x == "N"))
   prediction[totMissing] <- NA
   class(prediction) <- "MangroveContPreds"
   return(prediction)
}

#here we go, with this trait
thistrait<-args[1]


#Mangrove data
ped<-readPed("mangroveinput")
betas<-readBetas(paste(thistrait,"grovebeta",sep="."),h=T)

#trait Data
traitinfo<-read.table("trait-info.txt",h=T)

thisunits<-traitinfo$units[traitinfo$shortname==thistrait]
popmean<-traitinfo$mean[traitinfo$shortname==thistrait]
popsd<-traitinfo$sd[traitinfo$shortname==thistrait]

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

