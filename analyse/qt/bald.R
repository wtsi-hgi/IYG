library(ReadImages)
gorb<-read.jpeg("Reagan_and_Gorbachev_signing.jpg")
grn<-rgb(0,0.8,0.3,alpha=0.3)
red<-rgb(0.9,0,0,alpha=0.3)

for (i in 1:9){
	jpeg(paste("BALD",i,".jpg",sep=""),height=500,width=750)
	par(mar=c(0,0,0,0))
	plot(gorb)
	par(new=T)
	colors<-rep(grn,9)
	colors[i]<-red
	barplot(h$counts,col=colors,border=F,axes=F)
	dev.off()
}