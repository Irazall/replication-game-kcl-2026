
#install.packages('readr', dependencies = TRUE, repos='http://cran.rstudio.com/')

library(meta)
library(foreign)
library(haven)
#and also run reading in edattain data
data<-read_dta("/scores_data.dta")
#View(data)
new_mean <- data$new_mean
sd <- data$sd


# This is a function to calculate the estimates of mean and variance with the DL method.
# The estimate of the variance of the mean is calculated with the Hartung-Knapp method.
meta <- function(new_mean, sd) {
  num <- length(new_mean)
  theta <- sum(new_mean*sd^(-2))/sum(sd^(-2))
  thetav <- rep(theta, num)
  Q <- sum((new_mean-thetav)^2*sd^(-2))
  tau2 <- (Q-(num-1))/(sum(sd^(-2))-sum(sd^(-4))/sum(sd^(-2)))
  thetar <- sum(new_mean/(sd^2+tau2))/sum((sd^2+tau2)^(-1))
  seTE2 <-
    sum((new_mean-thetar)^2*((sd^2+tau2)^(-1)/sum((sd^2+tau2)^(-1))))/(num-1)
  return(list(thetar=thetar, seTE2=seTE2, tau2=tau2))
}

# This function takes the vector of observed means and the associated standard errors
# and outputs the standardized means and the p-value of the Shapiro-Wilk test.
sswtest <- function(new_mean, sd) {
  num <- length(new_mean)
  variance <- sd^2
  tau2 <- meta(new_mean,sd)$tau2
  if (any(sd<0)) stop ("Standard error(s) < 0")
  if (tau2<=0) stop("The estimated tau2 by the DL method is 0. Fixed effect model
is favored.")
  stdmean <- rep(0, num)
  for (i in 1:num) {
    thetarJ <- meta(new_mean[-i], sd[-i])$thetar
    seTE2J <- meta(new_mean[-i], sd[-i])$seTE2
    stdmean[i] <- (new_mean[i]-thetarJ)*(1/(tau2+seTE2J+variance[i]))^0.5
  }
  pvalue <- shapiro.test(stdmean)$p.value
  print(pvalue)
  result <- list(stdmean=stdmean, pvalue=pvalue)
  return(result)
}

# Unweighted Q-Q plot
stdmean <- sswtest(new_mean,sd)$stdmean
qqnorm(stdmean, main = "", xlab = "Theoretical Quantile", ylab = "Observed Quantile")
abline(0,1)
pdf("equalWeight.pdf")

# Weighted Q-Q plot
# This function is the weighted version of the ppoints function used by qqnorm.
# Ref: Dempster & Ryan, 1985.
w_points <- function (weights) {
  n <- length(weights)
  steps <- weights
  if (n<=10) {
    for (i in 1:n) {
      if (i==1L) {
        steps[i] <- 5/8*weights[i]
      } else {
        steps[i] <- 0.5*weights[i]+sum(weights[1:i-1])+1/8*weights[1]
      }
    }
    points <- steps/(sum(weights)+1/8*(weights[1]+weights[n]))
  }
  else {
    for (i in 1:n) {
      if (i==1L) {
        steps[i] <- 0.5*weights[i]
        steps[i] <- 0.5*weights[i]
      } else {
        steps[i] <- 0.5*weights[i]+sum(weights[1:i-1])
      }
    }
    points <- steps/sum(weights)
  }
  return(points)
}

# Weighted Q-Q plot
stdmean <- sswtest(new_mean,sd)$stdmean
weights <- 1/(meta(new_mean,sd)$tau2+sd^2)
plot(qnorm(w_points(weights[order(stdmean)])[order(order(stdmean))]),stdmean,
     main = "", xlab = "Theoretical Quantile", ylab = "Observed Quantile")
abline(0,1)
pdf("Weighted.pdf")
