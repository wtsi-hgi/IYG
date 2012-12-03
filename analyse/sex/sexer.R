#OK. rules are as follows
#below intensity of 0.28 & callrate of 0.2 = F
#above callrate of 0.5 = M (this is also essentially 100% intensity > 0.28)
#else = unknown
#Flagged individuals should have a specific note that their sex may be wrong.

x<-read.table("sex-info.txt",h=F)
clean<-read.table("iyg-2.fam",h=F)
x<-x[x$V1%in%clean$V1,]
dim(cleansex)

#jeffnam style
#sexpred<-cbind(as.character(x$V1[which(x$V2>0.5)]),1)
#sexpred<-rbind(sexpred,cbind(as.character(x$V1[which(x$V2<0.2 & x$V3 < 0.28)]),2))
#sexpred<-rbind(sexpred,cbind(as.character(x$V1[which(x$V2<0.5 & x$V3 > 0.28)]),-9))

#luke is a cock.
sexpred <- rep("-9",length(x$V1))
sexpred[x$V2>0.5] <- 1
sexpred[x$V2<0.2 & x$V3 < 0.28] <- 2
sexpred <- cbind(x,sexpred)

write.table(sexpred,file="sexpred.txt",quote=F,sep="\t",row.names=F,col.names=F)