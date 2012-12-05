args <- commandArgs(trailingOnly = TRUE)
#here we go, with this trait
thistrait<-args[1]
privdir<-args[2]
pubdir<-args[3]
webdir<-paste(args[4],"/",thistrait,sep="")
outdir<-paste(args[5],"/",thistrait,sep="")

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



#Mangrove data
ped<-readPed(paste(privdir,"/","iyg",sep=""))
betas<-readBetas(paste(pubdir,"/qt/",thistrait,".grovebeta",sep=""),h=T)

#trait Data
traitinfo<-read.table(paste(pubdir,"/","master-trait-info.txt",sep=""),h=T,sep="\t")

thisunits<-traitinfo$Units[traitinfo$ShortName==thistrait]
popmean<-traitinfo$Mean[traitinfo$ShortName==thistrait]
popsd<-traitinfo$SD[traitinfo$ShortName==thistrait]



#Run Mangrove
predictions<-calcBetas(ped,betas)

#does this trait have population data?
if (!is.na(popmean)){
	popleft<-popmean-4*popsd
	popright<-popmean+4*popsd
	popx<-seq(popleft,popright,length=200)
	popy<-dnorm(popx,popmean,popsd)

	varexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/popsd
	absolutepreds<-applyBetas(predictions,popmean,1)
}

if (thistrait == "CAFE"){
	###WARNING, EXTREME HACK FOR CAFE!!
	UKmean<-1.65
	UKsd<-2.25
	NLmean<-3.91
	NLsd<-2.85
	###END HACK HERE
	popleft<-UKmean-4*UKsd
	popright<-NLmean+4*NLsd
	popx<-seq(popleft,popright,length=200)
	UKy<-dnorm(popx,UKmean,UKsd)
	NLy<-dnorm(popx,NLmean,NLsd)

	UKvarexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/UKsd
	NLvarexpl<-sum(2*betas$Freq*(1-betas$Freq)*betas$beta^2)/NLsd

	absolutepredsUK<-applyBetas(predictions,UKmean,1)
	absolutepredsNL<-applyBetas(predictions,NLmean,1)	
}

#is this the EYE trait?
if (thistrait == "EYE"){
	#get counts in different bins
	h<-hist(predictions,breaks=40,plot=F)
	numincats<-cumsum(h$counts)

	#representative colors for 23andme's 7 categories
	eyecolor7<-rgb(154/255,164/255,180/255)
	eyecolor6<-rgb(145/255,149/255,150/255)
	eyecolor5<-rgb(139/255,143/255,124/255)
	eyecolor4<-rgb(172/255,148/255,120/255)
	eyecolor3<-rgb(149/255,119/255,85/255)
	eyecolor2<-rgb(168/255,134/255,92/255)
	eyecolor1<-rgb(97/255,73/255,58/255)

	#this is the cumulative expected number of IYG people in each of 23andme's 7 categories
	#obviously massively confounded by relative ethnic constitution of 23andme and IYG
	n_iyg<-length(predictions)
	expiyg1<-0.22*n_iyg
	expiyg2<-0.06*n_iyg+expiyg1
	expiyg3<-0.17*n_iyg+expiyg2
	expiyg4<-0.03*n_iyg+expiyg3
	expiyg5<-0.18*n_iyg+expiyg4
	expiyg6<-0.12*n_iyg+expiyg5
	expiyg7<-0.22*n_iyg+expiyg6

	#fill out vector of hist bars
	colors<-rep(eyecolor1,min(which(numincats > expiyg1)))
	colors<-c(colors,rep(eyecolor2,min(which(numincats>expiyg2))-min(which(numincats>expiyg1))))
	colors<-c(colors,rep(eyecolor3,min(which(numincats>expiyg3))-min(which(numincats>expiyg2))))
	colors<-c(colors,rep(eyecolor4,min(which(numincats>expiyg4))-min(which(numincats>expiyg3))))
	colors<-c(colors,rep(eyecolor5,min(which(numincats>expiyg5))-min(which(numincats>expiyg4))))
	colors<-c(colors,rep(eyecolor6,min(which(numincats>expiyg6))-min(which(numincats>expiyg5))))
	colors<-c(colors,rep(eyecolor7,length(h$counts)-min(which(numincats>expiyg6))))
	
}

if (!is.na(popmean)){
	output<-cbind(ped$ID,thistrait,predictions,absolutepreds)
	headernames<-c("Barcode","TraitShortname","IYGHIST","POPDIST")
}else{
	output<-cbind(ped$ID,thistrait,predictions)
	headernames<-c("Barcode","TraitShortname","IYGHIST")
}
write.table(output,file=paste(outdir,"/","pred.",thistrait,".txt",sep=""),quote=F,row.names=F,col.names=headernames,sep="\t")


for (i in 1:length(predictions)){
	print(names(predictions)[i])
	svg(paste(webdir,"/IYGHIST/",names(predictions)[i],".svg",sep=""),bg="transparent")
	if (thistrait == "EYE"){
		hist(predictions,breaks=40,axes=F,xlab="",ylab="",main="",col=colors)
	}else{
		hist(predictions,breaks=30,axes=F,xlab="",ylab="",main="")			
	}
	abline(v=predictions[i],lty=2,col=2,lwd=2)
	dev.off()
	if (!is.na(popmean)){	
		svg(paste(webdir,"/POPDIST/",names(absolutepreds)[i],".svg",sep=""),bg="transparent")
		thisy<-dnorm(popx,absolutepreds[i],popsd-sqrt(varexpl))
		plot(popx,popy,type="l",bty="n",yaxt="n",ylab="",
		xlab=paste(thistrait,thisunits,sep=" "),ylim=c(0,1.1*max(popy)),lwd=2)
		lines(popx,thisy,col=2,lwd=2)
		dev.off()
	}
	if (thistrait == "CAFE"){
		svg(paste(webdir,"/POPDIST/",names(absolutepredsUK)[i],".svg",sep=""),bg="transparent")
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
}

