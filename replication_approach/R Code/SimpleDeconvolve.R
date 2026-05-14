
library(foreign)
library(decon)

data1<-read.dta("Created Datasets/scores_data.dta")
data2<-read.dta("Created Datasets/edattain_data.dta")

y1  <- data1$effect_est
sig1  <- data1$effect_se

y2  <- data2$effect_est
sig2  <- data2$effect_se


# use the 0.008 bandwidth for both
(f3a <-  DeconPdf(y1,sig1,error="normal", bw=0.008, fft=FALSE , from=-.1 , to=0.15))
# plot the results
plot(f3a,  col="red", lwd=3, lty=2, xlab="x", ylab="f(x)", main="")
# Output to another file for export to stata (did it one variable at a time)
write.csv(f3a$y, file = "Created Datasets/scores_decondata1.csv")
write.csv(f3a$x, file = "Created Datasets/scores_decondata2.csv")


# use the 0.008 bandwidth for both
(f3b <-  DeconPdf(y2,sig2,error="normal", bw=0.008, fft=FALSE , from=-.1 , to=0.15))
# plot the results
plot(f3b,  col="red", lwd=3, lty=2, xlab="x", ylab="f(x)", main="")
# Output to another file for export to stata (did it one variable at a time)
write.csv(f3b$y, file = "Created Datasets/edattain_decondata1.csv")
write.csv(f3b$x, file = "Created Datasets/edattain_decondata2.csv")

