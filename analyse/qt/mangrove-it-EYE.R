args <- commandArgs(trailingOnly = TRUE)
library(Mangrove)

source("calcBetas.R")

#here we go, with this trait
thistrait<-"EYE"


#Mangrove data
ped<-readPed("mangroveinput")
betas<-readBetas(paste(thistrait,"grovebeta",sep="."),h=T)

#Run Mangrove
predictions<-calcBetas(ped,betas)
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

#Get ready to produce output
setwd(thistrait)


output<-cbind(ped$ID,predictions,NA)
write.table(output,file=paste(thistrait,"grove.out",sep="-"),quote=F,row.names=F,col.names=F)

for (i in 1:length(predictions)){
	svg(paste(names(predictions)[i],"bh",thistrait,"svg",sep="."),bg="transparent")
	hist(predictions,breaks=40,axes=F,xlab="",ylab="",main="",col=colors)
	abline(v=predictions[i],lty=2,col=2,lwd=2)
	dev.off()
}

