local filepath ""
clear frames

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

**
*TEST SCORES (Figure 6)
**
*overall
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau_nocont = sqrt(e(tau2))
local mu_overall = _b[_cons]
local se_overall = _se[_cons]

*cap v non-capital
robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau_capnocap = sqrt(e(tau2))
local mu_noncap = _b[_cons]
local se_noncap = _se[_cons]
lincom _cons + capital
local mu_capital = r(estimate)
local se_capital = r(se)

*LI v non-LI
robumeta EstimatedEffect_overall EstEffLI EstEffnonLI capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau_LInonLI = sqrt(e(tau2))
lincom _cons + EstEffLI
local mu_LI = r(estimate)
local se_LI = r(se)
lincom _cons + EstEffnonLI
local mu_nonLI = r(estimate)
local se_nonLI = r(se)

twoway (function y = 1 - normal((x-`mu_overall')/sqrt(`se_overall'^2 + `tau_nocont'^2)), range(-.05 .15)) ///
		(function y = 1 - normal((x-`mu_LI')/sqrt(`se_LI'^2 + `tau_LInonLI'^2)), range(-.05 .15)) ///
		(function y = 1 - normal((x-`mu_nonLI')/sqrt(`se_nonLI'^2 + `tau_LInonLI'^2)), range(-.05 .15)) ///
		(function y = 1 - normal((x-`mu_noncap')/sqrt(`se_noncap'^2 + `tau_capnocap'^2)), range(-.05 .15)) ///
		(function y = 1 - normal((x-`mu_capital')/sqrt(`se_capital'^2 + `tau_capnocap'^2)), range(-.05 .15)) ///
		, xtitle("Effect Size (Standard Deviation Units)") ytitle("Cumulative Probability") ///
		yline(.5, lcolor(gs13) lpattern(solid)) ///
		yline(.1, lcolor(gs13) lpattern(solid)) ///
		legend(order(1 "Overall" 2 "Low-Income" 3 "Non-Low Income" 4 "Non-Capital" 5 "Capital") pos(2) col(3) ring(0)) title("Test Scores") xlabel(-.05(.05).15)


cd "`filepath'/Figures and Tables"
graph export policyprob_testscore.pdf, replace

robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)
local tau_nocontONE = sqrt(e(tau2))
local mu_overallONE = _b[_cons]
local se_overallONE = _se[_cons]


**
*ED ATTAIN
**
*overall
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local tau_overall = sqrt(e(tau2))
local mu_overall = _b[_cons]
local se_overall = _se[_cons]

*LI v non-LI
robumeta EstimatedEffect_overall EstEffLI EstEffnonLI if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local tau_LInonLI = sqrt(e(tau2))
lincom _cons + EstEffLI
local mu_LI = r(estimate)
local se_LI = r(se)
lincom _cons + EstEffnonLI
local mu_nonLI = r(estimate)
local se_nonLI = r(se)


twoway (function y = 1 - normal((x-`mu_overall')/sqrt(`se_overall'^2 + `tau_overall'^2)), range(-.08 .15)) ///
		(function y = 1 - normal((x-`mu_LI')/sqrt(`se_LI'^2 + `tau_LInonLI'^2)), range(-.08 .15)) ///
			(function y = 1 - normal((x-`mu_nonLI')/sqrt(`se_nonLI'^2 + `tau_LInonLI'^2)), range(-.08 .15)) ///
		, xtitle("Effect Size (Standard Deviation Units and Percentage Point Changes)") ytitle("Cumulative Probability") ///
		yline(.5, lcolor(gs13) lpattern(solid)) ///
		yline(.1, lcolor(gs13) lpattern(solid)) ///
		legend(order(1 "Overall" 2 "Low-Income" 3 "Non-Low Income") pos(2) col(1) ring(0)) title("Educational Attainment") xlabel(-.09 `" "Standardized Effect:"   "High School Graduation:" "College Attendance:" "' -.05 `" "-0.05"   "-0.018" "-0.025" "'  0 `" "0"   "0" "0" "' 0.05 `" "0.05"   "0.018" "0.025" "' 0.1 `" "0.1"   "0.036" "0.049" "' 0.15 `" "0.15"   "0.054" "0.074" "')


cd "`filepath'/Figures and Tables"
graph export policyprob_nontestscore.pdf, replace


//regs for table //Table 3
eststo clear
*1
preserve
set seed 123634
local spec "testOverall"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
unique studyid if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"

*2
preserve
set seed 123634
local spec "testCap"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est2
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
lincom _cons + capital
local tstat = r(estimate)/r(se)
di `tstat'
if `tstat' > 2.5758{
	local sigstar "***"
}
else if (`tstat' > 1.96 & `tstat' < 2.5758){
	local sigstar "**"
}
else if (`tstat' > 1.6449 & `tstat' < 1.96){
	local sigstar "***"
}
else{
	local sigstar ""
}
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") //+ "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"
unique studyid if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"

*3
preserve
set seed 123634
local spec "testLI"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall EstEffLI EstEffnonLI capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall EstEffLI EstEffnonLI capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local tau2 = e(tau2)
local PW_mean = _b[_cons]
lincom EstEffLI - EstEffnonLI
local tstat = r(estimate)/r(se)
di `tstat'
if `tstat' > 2.5758{
	local sigstar "***"
}
else if (`tstat' > 1.96 & `tstat' < 2.5758){
	local sigstar "**"
}
else if (`tstat' > 1.6449 & `tstat' < 1.96){
	local sigstar "***"
}
else{
	local sigstar ""
}
estadd local LInonLISum = string(round(r(estimate), .0001), "%9.3f") //+ "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local LInonLISE = "(`SE')"
esttab est3
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
lincom _cons + capital
local tstat = r(estimate)/r(se)
di `tstat'
if `tstat' > 2.5758{
	local sigstar "***"
}
else if (`tstat' > 1.96 & `tstat' < 2.5758){
	local sigstar "**"
}
else if (`tstat' > 1.6449 & `tstat' < 1.96){
	local sigstar "***"
}
else{
	local sigstar ""
}
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") //+ "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"
unique studyid if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"

*4
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est4
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
unique studyid if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"


*5
preserve
set seed 123634
local spec "nontestOverall"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local tau2 = e(tau2)
local PW_mean = _b[_cons]
esttab est5
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
unique studyid if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"

*6
preserve
set seed 123634
local spec "nontestLI"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall EstEffLI EstEffnonLI if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall EstEffLI EstEffnonLI if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local tau2 = e(tau2)
local PW_mean = _b[_cons]
lincom EstEffLI - EstEffnonLI
local tstat = r(estimate)/r(se)
di `tstat'
if `tstat' > 2.5758{
	local sigstar "***"
}
else if (`tstat' > 1.96 & `tstat' < 2.5758){
	local sigstar "**"
}
else if (`tstat' > 1.6449 & `tstat' < 1.96){
	local sigstar "***"
}
else{
	local sigstar ""
}
estadd local LInonLISum = string(round(r(estimate), .0001), "%9.3f") //+ "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local LInonLISE = "(`SE')"
esttab est6
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
unique studyid if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"



*7
preserve
set seed 123634
local spec "nontestOne"
cd "`filepath'/BS Data"
bs e(tau2) , saving(bstest`spec', replace) r(400): robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen tau_temp = sqrt(_bs_1)
sum tau_temp if tau_temp > 0
local bs_tau_SD = string(round(r(sd), .0001), "%9.3f")
restore

eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)

estadd scalar TableTau = sqrt(e(tau2))
local tau2 = e(tau2)
local PW_mean = _b[_cons]
esttab est7
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.28*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI80_avg = "[`lowerPI',`upperPI']"
local lowerPI = string(round(`PW_mean' - 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.96*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI95_avg = "[`lowerPI',`upperPI']"
unique studyid if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
estadd scalar N_2 = r(unique)
estadd local bs_tau_SD = "(`bs_tau_SD')"


cd "`filepath'/Figures and Tables"
esttab using PolicyProbRegs.tex, replace se title("Meta-Regression Estimates" "\label{tab:MainPolicyRegs}") l varlabels(_cons "Overall" EstEffnonLI "Non-Low-Income") stats(capitalEff capitalSE LInonLISum LInonLISE k N N_2 TableTau bs_tau_SD PI80_avg PI90_avg PI95_avg, labels("Capital" "(se)" "LI - Non-LI" "(se)" "\hline" "Observations" "Clusters" "\$\tau\$" "\$\hat{\sigma_{\tau}}\$" "Average 80\% PI" "Average 90\% PI" "Average 95\% PI")) order(_cons capital EstEffLI EstEffnonLI) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "Out of `total_studies' total studies on test score outcomes, `unique_cap' are estimates of effects of capital spending." "The reported $\hat{\sigma}_{\tau}$ is estimated by bootstrap." "Columns (4) and (7) report for one estimate per study-outcome.") mgroups("Test Scores" "Educational Attainment" , pattern(1 0 0 0 1 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) substitute(_ _) nostar nomtitles

