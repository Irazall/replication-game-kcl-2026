local filepath "" //(Figure 7) // (Figure A.16)

* Test Scores 

* pulling the results from deconvolve in R (the simple case)
import delimited "`filepath'/Created Datasets/scores_decondata1.csv", clear 
rename x y
save temp.dta, replace
import delimited "`filepath'/Created Datasets/scores_decondata2.csv", clear
merge 1:1 v1 using temp.dta
 
twoway (line y x)
* take out that blip at the top and bottom for test score
replace y=0 if x>.129
replace y=0 if x<-0.05
twoway (line y x if x>-.05, text( 18 -.07 "A. Test Scores", place(e) size(.5cm))),  ytitle("Density") xtitle("Marginal Effect") title("Deconvolved Density")

cd "`filepath'/Figures and Tables"
graph save "Graph" "test_decon.gph" , replace
 * Compute implied means and variance
gen xy= x*y
egen sum_xy=total(xy) 
egen sum_den=sum(y)
gen mean = sum_xy/sum_den
sum mean

gen x2y= x^2*y
egen sum_x2y=sum(x2y)
gen mean_x2y=sum_x2y/sum_den
gen sd=(mean_x2y - mean^2)^(1/2)
* Gives mean and spread of estimated deconvolved distrubtion
sum mean
local deconmean = string(round(r(mean), .0001), "%9.3f")
sum sd
local deconSD = string(round(r(mean), .0001), "%9.3f")

* These are predicted effects based on flexible deconvolved distrubtions
gen cum_density = sum(y)
gen prob=1-(cum_density/sum_den)
twoway (line prob x if x>-.05 , xline(0 0.05 0.1)  )
* add the normal for comparison (use the one-per study estimates)

gen z_orig=(x-0.0323)/0.0221
gen p=1-normal(z)
label var prob Deconvolved
label var p Normal_Orig
twoway (line prob x if x>-.05 , xline(0 0.05 0.1)) (line p x, sort)

*** We can put in the Bayesian estimate it is also similar.

gen z_bayes=(x-.0336547 )/0.02488373
gen p_bayes=1-normal(z_bayes)
label var p_bayes Normal_Bayes
twoway (line prob x if x>-.05 , xline(0 0.05 0.1) xscale(range(-.05(.05).15))) (line p x if x>-.05, sort) (line p_bayes x if x>-.05, sort), ytitle("Cumulative" "Probability") xtitle("Marginal Effect") title("Tail Probability") legend(pos(7) col(3) order(1 "Deconvolved" 2 "Normal Original" 3 "Normal Bayes")) note("Deconvolve mean: `deconmean', sd: `deconSD'")
cd "`filepath'/Figures and Tables"
graph save "Graph" "test_decon_policy.gph" , replace

graph combine test_decon.gph test_decon_policy.gph, col(1)

graph export "test_decon.pdf", replace
**************************************************


* Educational Attainment
cd "`filepath'/Created Datasets"
* pulling the results from deconvolve in R (the simple case)
import delimited "edattain_decondata1.csv", clear 
rename x y
save temp.dta, replace
import delimited "edattain_decondata2.csv", clear
merge 1:1 v1 using temp.dta
 
twoway (line y x)
* take out that blip at the top for ed attain
replace y=0 if x>.12
twoway (line y x if x>-.05, text( 23 -.07 "B. Educational Attainment", place(e) size(.5cm))), ytitle("Density") xtitle("Marginal Effect") title("Deconvolved Density")
graph save "Graph" "ed_decon.gph" , replace

 * Compute implied means and variance
gen xy= x*y
egen sum_xy=total(xy) 
egen sum_den=sum(y)
gen mean = sum_xy/sum_den
sum mean

gen x2y= x^2*y
egen sum_x2y=sum(x2y)
gen mean_x2y=sum_x2y/sum_den
gen sd=(mean_x2y - mean^2)^(1/2)

* Gives mean and spread of estimated deconvolved distrubtion
sum mean
local deconmean = string(round(r(mean), .0001), "%9.3f")
sum sd
local deconSD = string(round(r(mean), .0001), "%9.3f")

* these are predicted effects based on flexible deconvolved distrubtions!!!
gen cum_density = sum(y)
gen prob=1-(cum_density/sum_den)
twoway (line prob x if x>-.05 , xline(0 0.05 0.1)  )
* add the normal for comparison (use the one-per study estimates)

gen z_orig=(x-0.0568)/0.0167
gen p=1-normal(z)
label var prob Deconvolved
label var p Normal_Orig
twoway (line prob x if x>-.05 , xline(0 0.05 0.1)) (line p x, sort)

*** We can put in the Bayesian estimate it is also similar.

gen z_bayes=(x-0.0574077)/0.02099047
gen p_bayes=1-normal(z_bayes)
label var p_bayes Normal_Bayes
twoway (line prob x if x>-.05 , xline(0 0.05 0.1) xscale(range(-.05(.05).15))) (line p x if x>-.05, sort) (line p_bayes x if x>-.05, sort), xtitle("Marginal Effect") title("Tail Probability") legend(pos(7) col(3) order(1 "Deconvolved" 2 "Normal Original" 3 "Normal Bayes")) note("Deconvolve mean: `deconmean', sd: `deconSD'") ytitle("Cumulative" "Probability") 
graph save "Graph" "ed_decon_policy.gph" , replace

graph combine ed_decon.gph ed_decon_policy.gph, col(1) xcomm

graph export "edattain_decon.pdf", replace



//for probabilities in prose

cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

sort Article_Authors EstimatedEffect_lowinc EstimatedEffect_nonlowinc
order Article_Authors EstimatedEffect_lowinc EstimatedEffect_nonlowinc
quietly bysort Article_Authors Study_outcome:  gen dup = cond(_N==1,0,_n)
order dup
gen hasByIncInd = 1 if dup > 0
replace hasByIncInd = 0 if dup == 0
label var hasByIncInd "Has Estimates by Income (Indicator)"
rename EstimatedEffect_lowinc EstEffLI
rename EstimatedEffect_nonlowinc EstEffnonLI

robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)
lincom _cons
local SEsq = r(se)^2
di 1 - normal((0-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((0.01-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((0.05-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((0.08-r(estimate))/sqrt(`SEsq' + `tau2'))

robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)
lincom _cons
local SEsq = r(se)^2
*positive
di 1 - normal(((0/.357)-r(estimate))/sqrt(`SEsq' + `tau2'))

*hs completion 1pp, 2pp, 3pp
di 1 - normal(((.01/.357)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.02/.357)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.03/.357)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.032/.357)-r(estimate))/sqrt(`SEsq' + `tau2'))
*college-going 1pp, 2.5pp, 4.5 pp
di 1 - normal(((.01/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.029/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.045/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))

robumeta EstimatedEffect_overall EstEffLI EstEffnonLI if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)

lincom _cons + EstEffLI
local SEsq = r(se)^2
di 1 - normal((.0-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.02/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.05/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))

di 1 - normal((.1-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.075/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
lincom _cons + EstEffnonLI
local SEsq = r(se)^2
di 1 - normal(((.05/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal(((.02/.492)-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((.0-r(estimate))/sqrt(`SEsq'  + `tau2'))
di 1 - normal((.04-r(estimate))/sqrt(`SEsq'  + `tau2'))
di 1 - normal((.1-r(estimate))/sqrt(`SEsq'  + `tau2'))


robumeta EstimatedEffect_overall EstEffLI EstEffnonLI capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)

lincom _cons + EstEffLI
local SEsq = r(se)^2
di 1 - normal((.04-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((.06-r(estimate))/sqrt(`SEsq' + `tau2'))
lincom _cons + EstEffnonLI
di 1 - normal((.04-r(estimate))/sqrt(`SEsq' + `tau2'))
di 1 - normal((.06-r(estimate))/sqrt(`SEsq' + `tau2'))
