
## 

library(meta)
library(foreign)
library(haven)
library(deconvolveR)
library(ggplot2)
library(REBayes)

data<-read.dta("scores_data.dta")
## View(data)


bayes_est <- data$z_score
tau <- seq(from = -3, to = 7, by = 0.1)

result <- deconv(tau = tau, X = bayes_est, family = "Normal", , pDegree = 5)
d <- data.frame(result$stats)
indices <- seq(5, 99, 5)
##indices <- seq(0.0001, 0.01, 0.0001)
errorX <- tau[indices]
ggplot() +
    geom_line(data = d, mapping = aes(x = tau, y = g)) +
    geom_errorbar(data = d[indices, ],
                  mapping = aes(x = theta, ymin = g - SE.g, ymax = g + SE.g),
                  width = .01, color = "blue") +
    labs(x = expression(theta), y = expression(paste(g(theta), " +/- SE")))
View(d)
write.csv(d, file = "scores_deconv.csv")
####

data<-read.dta("edattain_data.dta")
## View(data)


bayes_est <- data$z_score
tau <- seq(from = -3, to = 7, by = 0.1)

result <- deconv(tau = tau, X = bayes_est, family = "Normal", , pDegree = 5)
d <- data.frame(result$stats)
indices <- seq(5, 99, 5)
##indices <- seq(0.0001, 0.01, 0.0001)
errorX <- tau[indices]
ggplot() +
  geom_line(data = d, mapping = aes(x = tau, y = g)) +
  geom_errorbar(data = d[indices, ],
                mapping = aes(x = theta, ymin = g - SE.g, ymax = g + SE.g),
                width = .01, color = "blue") +
  labs(x = expression(theta), y = expression(paste(g(theta), " +/- SE")))
View(d)
write.csv(d, file = "edattain_deconv.csv")
####