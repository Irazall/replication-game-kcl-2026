
library(meta)
library(foreign)
library(haven)
library(deconvolveR)
library(ggplot2)
library(REBayes)
library(metaplus)
library(readr)
library(xtable)


#test scores
data_score<-read.dta("scores_data.dta")
data_primary <- subset(data_score, Study_isprimary == 1)
testscore.mixture <- metaplus(EstimatedEffect_overall,EstimatedEffect_overall_SE, random="mixture",data = data_primary)
testscore.mixture$results
testscore.tdist <- metaplus(EstimatedEffect_overall,EstimatedEffect_overall_SE, random="t-dist",data = data_primary)
testscore.tdist$results

#edattain
data_ed<-read.dta("edattainALL_data.dta")
data_primaryED <- subset(data_ed, Study_isprimary == 1)
edattain.mixture <- metaplus(EstimatedEffect_overall,EstimatedEffect_overall_SE, random="mixture",data = data_primaryED)
edattain.mixture$results
edattain.tdist <- metaplus(EstimatedEffect_overall,EstimatedEffect_overall_SE, random="t-dist",data = data_primaryED)
edattain.tdist$results


