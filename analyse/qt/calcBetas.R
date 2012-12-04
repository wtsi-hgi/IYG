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