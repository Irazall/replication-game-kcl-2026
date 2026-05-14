local filepath ""
clear frames

/*
by-spend change effects figure
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
keep if Study_isprimary

keep if !regexm(Article_Authors, "Chaud")
//precision-weight Baron's two test score estimates (from capital and operational)
count
forvalues i = 1/`r(N)'{
	if Article_Authors2[`i'] == "Baron" & Study_outcome[`i'] == "Test scores"{
		if PPE_dollarstype[`i'] == "capital"{
			local Effect1 = EstimatedEffect_overall[`i']
			local SE1 = EstimatedEffect_overall_SE[`i']
		}
		else if PPE_dollarstype[`i'] == "operational"{
			local Effect2 = EstimatedEffect_overall[`i']
			local SE2 = EstimatedEffect_overall_SE[`i']
		}
	}
}

local BaronTestEffect = (`Effect1' + `Effect2')/2
local BaronTestSE = (0.25*(`SE1'^2 + `SE2'^2))^(1/2)
di "`BaronTestEffect'"
di "`BaronTestSE'"

replace EstimatedEffect_overall = `BaronTestEffect' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
replace EstimatedEffect_overall_SE = `BaronTestSE' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
drop if Article_Authors=="Baron c" //then, Baron has just one test score estimate

reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2]
local coef_test =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")
local pval_test = string(round(r(table)[4,1], .000001), "%9.5f")

reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")
local naivecoef_test =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")

cd "`filepath'/Figures and Tables"
twoway (lfitci EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2], legend(off) title("Test Scores") ytitle("Effect per $1000 in PPE") xtitle("Change in Per Pupil Expenditure (2018$)") note("Precision-weighted slope: `coef_test'; Naive equal-weighted slope: `naivecoef_test'")) (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(circle_hollow) ) (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(none) mlabel(Article_Authors)) 
graph save Graph changePPE_scores.gph, replace


/*
bar chart of main estimates by approach to accounting for publication bias (Figure A.19)
*/
cd "`filepath'/Created Datasets"
import excel corrbarchart_estimates, firstrow clear

gen hiEst = EstimatedEffect + 1.65*EstimatedEffect_SE
gen loEst = EstimatedEffect - 1.65*EstimatedEffect_SE
replace counter = count + .25 if outtype == "Educational Attainment"
twoway (bar EstimatedEffect counter if approach == "main") ///
		(bar EstimatedEffect counter if approach == "withinLOWaccLOW") ///
		(bar EstimatedEffect counter if approach == "withinLOWaccHIGH") ///
		(bar EstimatedEffect counter if approach == "withinHIGHaccLOW") ///
		(bar EstimatedEffect counter if approach == "withinHIGHaccHIGH") ///
		(bar EstimatedEffect counter if approach == "fstat20") ///
		(bar EstimatedEffect counter if approach == "noprofrate") ///
		(bar EstimatedEffect counter if approach == "nodep") ///
		(bar EstimatedEffect counter if approach == "noSDassume") ///
		(bar EstimatedEffect counter if approach == "noIVconst") ///
		(rcap hiEst loEst counter), ///
		legend(row(4) order(1 "Main" 2 "within = 0.25, accross = 0" 3 "within = 0.25, accross = 0.5" 4 "within = 0.75, accross = 0" 5 "within = 0.75, accross = 0.5" 6 "F-stat > 20" 7 "No prof. rate" 8 "No capital depreciation" 9 "No SD adjust assumption" 10 "No constructed IV" 11 "90% CI") pos(6)) ///
		xlabel(5 "Test Scores" 14 "Educational Attainment", noticks) ///
		xtitle("") ytitle("Average Effect per $1000 in PPE") ///
		note("Each bar represents a precision-weighted average estimate for each outcome type, comparing our main" "specification to different modelling assumptions.", size(small)) yscale(range(0 0.07)) ylabel(0(.01).07)

cd "`filepath'/Figures and Tables"
graph export corrsensebar.pdf, replace

/*
bar chart of main estimates by approach to accounting for publication bias (Figure 5) // Figure A.20
*/
cd "`filepath'/Created Datasets"
import excel pubbiasbarchart_estimates, firstrow clear

gen hiEst = EstimatedEffect + 1.65*EstimatedEffect_SE
gen loEst = EstimatedEffect - 1.65*EstimatedEffect_SE

replace counter = count + .25 if outtype == "Educational Attainment"

twoway (bar EstimatedEffect counter if approach == "Main") ///
		(bar EstimatedEffect counter if approach == "Andrews Kasy") ///
		(bar EstimatedEffect counter if approach == "Precise Half") ///
		(bar EstimatedEffect counter if approach == "Trim & Fill") ///
		(bar EstimatedEffect counter if approach == "Stanley & Doucouliagos") ///
		(rcap hiEst loEst counter), ///
		legend(row(2) order(1 "Main" 2 "Andrews&Kasy" 3 "Precise Half" 4 "Trim and Fill" 5 "Stanley&Doucouliagos PEESE" 6 "90% CI") pos(6)) ///
		xlabel(2.5 "Test Scores" 8.5 "Educational Attainment", noticks) ///
		xtitle("") ytitle("Average Effect per $1000 in PPE") ///
		yscale(range(0 0.07)) ylabel(0(.01).07)

cd "`filepath'/Figures and Tables"
graph export pubbiasbar.pdf, replace



**
*for modelling assumption bar char
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear


*test score fstat > 20
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)

*test score noprof rate
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores") & nonRauschOverall , variance(EstimatedEffect_overall_Var) study(studyid)

*nontest fstat > 20
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)


/*
equal weighting for comparison (Table 1)
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

eststo clear

*1 RE test score
eststo: robumeta EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall_Var if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight=1/EstimatedEffect_overall_Var]
estadd scalar I2 = (`tau2')/(r(mean)+(`tau2'))
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*2 unweighted test score
sum EstimatedEffect_overall_Var if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

*3 RE single test score
eststo: robumeta EstimatedEffect_overall if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall_Var if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight=1/EstimatedEffect_overall_Var]
estadd scalar I2 = (`tau2')/(r(mean)+(`tau2'))
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*4 unweighted single test score
sum EstimatedEffect_overall_Var if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

*5 RE ed attain
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall_Var if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight=1/EstimatedEffect_overall_Var]
estadd scalar I2 = (`tau2')/(r(mean)+(`tau2'))
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if nonRauschOverall & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*6 unweighted ed attain
sum EstimatedEffect_overall_Var if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

*7 RE single ed attain
eststo: robumeta EstimatedEffect_overall if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall_Var if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight=1/EstimatedEffect_overall_Var]
estadd scalar I2 = (`tau2')/(r(mean)+(`tau2'))
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*4 unweighted single ed attain
sum EstimatedEffect_overall_Var if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

cd "`filepath'/Figures and Tables"
esttab using equalweight_regs.tex, replace se title("Equal Weighting Comparison" "\label{tab:unweight}") varlabels(_cons "Average Effect") stats(N estSD tau, labels("N" "SD of \$\hat{\theta}_j\$}'s" "\$\tau\$" )) mgroups("Test Scores" "Educational Attainment", pattern(1 0 0 0 1 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) mtitles("\shortstack{RE\\(multiple)}" "\shortstack{Equal Weight\\(multiple)}" "\shortstack{RE\\(single)}" "\shortstack{Equal Weight\\(single)}" "\shortstack{RE\\(multiple)}" "\shortstack{Equal Weight\\(multiple)}" "\shortstack{RE\\(single)}" "\shortstack{Equal Weight\\(single)}") substitute(_ _) nonotes addnotes("Standard errors in parentheses. For random effects models, standard errors are adjusted for clustering of related papers.") nostar

/*
tests for whether sampling variability is related to effect sizes (Figure A.18)
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen lnSE = log(EstimatedEffect_overall_SE)

*figure
cd "`filepath'/Figures and Tables"
twoway scatter EstimatedEffect_overall EstimatedEffect_overall_SE if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, title("Test Scores")
graph save "Graph" "scores_sampleeffect.gph", replace

twoway scatter EstimatedEffect_overall EstimatedEffect_overall_SE if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, title("Educational Attainment")
graph save "Graph" "edattain_sampleeffect.gph", replace

graph combine scores_sampleeffect.gph edattain_sampleeffect.gph

graph export "sampleeffect.pdf", replace

*regs actual lnSE (Table A.6)
eststo clear
*1
preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*2
preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 20
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*3
preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*4
preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary & EstimatedEffect_overall_SE < .1
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*5
preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary & FirstStage_Fstat > 20
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*6
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*7
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*8
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*9
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary & EstimatedEffect_overall_SE < .16
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

*10
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary & FirstStage_Fstat > 20
sum lnSE, d
gen demedSE = lnSE - r(p50)
label var demedSE "SE"
eststo: reg EstimatedEffect_overall demedSE
restore

cd "`filepath'/Figures and Tables"
esttab using sampleeffect_regslnSE.tex, replace se title("Relationship between precision and effect size" "\label{tab:sampleeff_regs}") varlabels(_cons "Avg. Effect" demedSE "Centered-SE") stats(N , labels("N")) star(* .1 ** .05 *** .01) mgroups("Test Scores" "Educational Attainment", pattern(1 0 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) mtitle("Multiple" "\shortstack{Multiple\\F$>$20}" "\shortstack{One Per}" "\shortstack{One Per\\Less Two}" "\shortstack{One Per\\F$>$20}" "Multiple" "\shortstack{Multiple\\F$>$20}" "\shortstack{One Per}" "\shortstack{One Per\\Less Two}" "\shortstack{One Per\\F$>$20}") order(_cons demedSE) style(tex) substitute(_ _) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "Reported Centered-SE subtracts the median standard error from the estimate standard error." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")


**
*by power (SE cutoff) AND POLICY CATEGORY (Table A.13)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

eststo clear
*1
robumeta EstimatedEffect_overall if  (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local cutoffTest =  _b[_cons]/1.96
eststo: robumeta EstimatedEffect_overall if  (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & EstimatedEffect_overall_SE < `cutoffTest' & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*2
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local cutoffEd = _b[_cons]/1.96
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & EstimatedEffect_overall_SE < `cutoffEd', variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est2
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

gen NewPolicy = 1 if Sample_PolicyType == "Equalization" | Sample_PolicyType == "Referenda" | Sample_PolicyType == "SFR" | Sample_PolicyType == "SIG" | capital
replace NewPolicy = 0 if missing(NewPolicy)
*3
eststo: robumeta EstimatedEffect_overall NewPolicy if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est3
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*4
eststo: robumeta EstimatedEffect_overall NewPolicy if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est4
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

cd "`filepath'/Figures and Tables"
esttab using PowerPolicyCatRegs.tex, replace se title("Meta-Regression Estimates by Power and Policy Categories" "\label{tab:powerpolcat_regs}") varlabels(_cons "Average Effect" NewPolicy "Voluntary Policy") stats(N tableTau PI90_avg, labels("Observations" "\$\tau\$" "Average 90\% PI")) star(* .1 ** .05 *** .01) mgroups("\shortstack{Power to Detect\\Main Effect}" "\shortstack{By Policy\\Categories}", pattern(1 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) mtitles("\shortstack{Test\\Score}" "\shortstack{Educational\\Attainment}" "\shortstack{Test\\Score}" "\shortstack{Educational\\Attainment}") substitute(_ _) order(_cons NewPolicy) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "Voluntary Policy includes: Equalization, Referenda," "School Finance Reform, New Construction, and School Improvement Grants." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")


**
*edattain over time (Figure A.12)
**
clear frames
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen dur_FX= Years_Expose*EstimatedEffect_overall/4
gen dur_se=Years_Expose*EstimatedEffect_overall_SE/4
frame copy default edattainovertime
frame change edattainovertime
keep if Study_isprimary & (Study_outcome == "High school graduation" | Study_outcome == "College enrollment" | Study_outcome == "High school dropout")
keep dur_FX dur_se Years_Expose
gen scatterInd = 1
tempfile temp1
save "`temp1'"

frame change default
gen Years_Exposeminus4 = Years_Expose - 4

metareg dur_FX Years_Exposeminus4 if Study_isprimary & (Study_outcome == "High school graduation" | Study_outcome == "College enrollment" | Study_outcome == "High school dropout") , wsse(dur_se)
test _cons = Years_Exposeminus4*4

metareg dur_FX Years_Expose if Study_isprimary & (Study_outcome == "High school graduation" | Study_outcome == "College enrollment" | Study_outcome == "High school dropout") , wsse(dur_se)


forvalues i = 1/12{
	lincom _cons + `i'*Years_Expose
	gen coef`i' = r(estimate)
	gen se`i' = r(se)
}

collapse (mean) coef1-se12
gen i = 1
reshape long coef se, i(i) j(Years_Expose)
gen se_upper = coef + (1.96*se)
gen se_lower = coef - (1.96*se)
gen scatterInd = 0
append using "`temp1'"

twoway (connected coef Years_Expose if Years_Expose > 3 & Years_Expose < 13 & !scatterInd) (rarea se_upper se_lower Years_Expose if Years_Expose > 3 & Years_Expose < 13 & !scatterInd, fcolor(white) color(purple%50)) (scatter dur_FX Years_Expose if Years_Expose > 3 & Years_Expose < 13 [w=1/dur_se^2], msymbol(circle_hollow)), legend(order(2 "95% Confidence Interval") pos(5)) xtitle("Time") ytitle("Average Effect (Random Effects Meta-Reg)") yscale(range(0(.2).6)) ylabel(0(.2).6)

cd "`filepath'/Figures and Tables"
graph export AttainmentOverTimeEst.pdf, replace



**
*histogram of tstat jump (Figure A.23)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

keep if Study_isprimary
gen t_stat= EstimatedEffect_overall/EstimatedEffect_overall_SE

cd "`filepath'/Figures and Tables"
cumul t_stat, gen(ct_both)
line ct_both t_stat   , sort xline(1.96 1.65) xtitle("T-stat") ytitle("")
graph save Graph "cum_dens_both.gph" , replace
histogram t_stat , bin(17) kdensity xline(1.96 1.645)  xtitle("T-stat")
graph save Graph "t_hist_both.gph" , replace
graph export "t_hist_both.pdf", replace
graph combine "t_hist_both.gph" "cum_dens_both.gph", xsize(8) ysize(4)
graph export "comb_phack.pdf" , replace


**
*tstat jump regs (Table A.16)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

keep if Study_isprimary
gen t_stat= EstimatedEffect_overall/EstimatedEffect_overall_SE
gen t2=t_stat^2
gen t3=t_stat^3
gen sig=t_stat>=1.96
cumul t_stat if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), gen(ct_test)
cumul t_stat if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), gen(ct_ed)

gen scores= (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen scores_t_stat=scores*t_stat
gen scores_t2_stat=scores*t2
gen scores_t3_stat=scores*t3
gen ct_stacked=ct_test
replace ct_stacked=ct_ed if ct_stacked==.

label var t_stat "T-stat"
label var t2 "T-stat\$^2\$"
label var scores "Test Score Outcome"
label var scores_t_stat "Test Score (ind) x T-stat"
label var scores_t2_stat "Test Score (ind) x T-stat\$^2\$"


eststo clear
* Individually
eststo: reg ct_test t_stat t2 t3 sig if Study_isprimary, r
eststo: reg ct_test t_stat t2 t3 sig if t_stat>1 & t_stat<3 & Study_isprimary, r
eststo: reg ct_ed t_stat t2 t3 sig if Study_isprimary , r
eststo: reg ct_ed t_stat t2 t3 sig if t_stat>1 & t_stat<3 & Study_isprimary , r

* stacked
eststo: reg ct_stacked t_stat t2 t3 scores scores_t_stat scores_t2_stat scores_t3_stat sig if Study_isprimary, r
eststo: reg ct_stacked t_stat t2 t3 scores scores_t_stat scores_t2_stat scores_t3_stat sig if t_stat>1 & t_stat<3 & Study_isprimary, r
test sig


cd "`filepath'/Figures and Tables"
esttab using tstat_regs.tex, replace se title("Regressions to test for jump at 5\% significance, Outcome: Cumulative T-stat density" "\label{tab:ttestjump}") varlabels(_cons "Constant" t_stat "T-stat" t2 "T-stat\$^2\$" sig "Sig, 5\%-level (ind)" scores "Test Score Outcome (ind)" scores_t_stat "Test Score (ind) x T-stat" scores_t2_stat "Test Score (ind) x T-stat\$^2\$") star(* .1 ** .05 *** .01) mtitles("\shortstack{Test\\Scores\\(all tstats)}" "\shortstack{Test\\Scores\\\$1<tstat<3\$}"  "\shortstack{Ed.\\Attain\\(all tstats)}" "\shortstack{Ed.\\Attain\\\$1<tstat<3\$}" "\shortstack{All\\Outcomes\\(all tstats)}" "\shortstack{All\\Outcomes\\\$1<tstat<3\$}" ) keep(sig) addn("All models include controls for the t-stat and the square and cube of the t-stat." "In column 5 pooled models (both outcome types) we include an indicator" "for the outcome and interact  t-stat and t-stat squared with the outcome.")


**
*by publication type indicator (Table A.15)
**
local reps = 400
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

eststo clear
*1
eststo: robumeta EstimatedEffect_overall unpublished if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
testparm unpublished
estadd scalar p_equalunpublish = r(p)

*2
eststo: robumeta EstimatedEffect_overall top_feild feild unpublished if  (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local tau2 = e(tau2)
testparm top_feild feild unpublished
estadd scalar p_equal = r(p)
testparm unpublished
estadd scalar p_equalunpublish = r(p)

*3
eststo: robumeta EstimatedEffect_overall unpublished if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
testparm unpublished
estadd scalar p_equalunpublish = r(p)


*4
eststo: robumeta EstimatedEffect_overall top_feild feild unpublished if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local tau2 = e(tau2)
testparm top_feild feild unpublished
estadd scalar p_equal = r(p)
testparm unpublished
estadd scalar p_equalunpublish = r(p)


cd "`filepath'/Figures and Tables"
esttab using PubTypeRegsFINA.tex, replace se title("Meta-Regressions w/ Publication Type" "\label{tab:pubtyperegFINAL}") varlabels(_cons "Average Effect" unpublished "Unpublished" top_feild "Top Field Journal" feild "Field Journal") star(* .1 ** .05 *** .01) stats(N tableTau p_equal p_equalunpublish, labels("N" "\$\tau\$" "Top Field = Field = Unpublished = 0 (p-val)" "Unpublished = 0 (p-val)")) mtitles("\shortstack{Test\\Score}" "\shortstack{Test\\Score}" "\shortstack{Educational\\Attainment}" "\shortstack{Educational\\Attainment}") nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "Reference category High Impact ommitted." "High Impact: American Economic Journal, Quarterly Journal of Economics, Review of Economics and Statistics," "Sociology of Education." "Top Field: Journal of Econometrics, Journal of Public Economics." "Field: AERA Open, Economics of Education Review, Education Economics, Education Finance and Policy," "Educational Evaluation and Policy Analysis, Public Finance Review, Russell Sage Foundation Journal of the Social" "Sciences, Journal of Public Administration Research and Theory, Journal of Urban Economics" "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")



**
*pubbias regs ONLY RUN ONCE, THEN MANUALLY UPDATE models that don't auto-output (andrews&kasy and trim&fill) (Table A.14)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

keep if Study_isprimary
//test score
eststo clear
*1 PLACEHOLDER for andrews & kasy
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = 99
count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd scalar Obs = r(N)

*2 precise half
sum EstimatedEffect_overall_SE  if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), d
local test_halfcut = round(r(p50), .001)
di `test_halfcut'
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & EstimatedEffect_overall_SE < `test_halfcut', variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = sqrt(e(tau2))
estadd scalar Obs = e(N)

*3 trim&fill
meta set EstimatedEffect_overall EstimatedEffect_overall_SE
meta trimfill if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), random
local trimTau = .
local trimN = r(K_total)
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = sqrt(`trimTau')
estadd scalar Obs = `trimN'

*4 PEESE
gen EstEfffect_Var = EstimatedEffect_overall_Var
eststo: robumeta EstimatedEffect_overall EstEfffect_Var if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstEfffect_Var) study(studyid)
estadd scalar Tabletau = sqrt(e(tau2))
estadd scalar Obs = e(N)

//ed attainment
*5 PLACEHOLDER for andrews & kasy
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = 99
count if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd scalar Obs = r(N)

*6 precise half
sum EstimatedEffect_overall_SE  if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), d
local nontest_halfcut = round(r(p50), .001)
eststo: robumeta EstimatedEffect_overall if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & EstimatedEffect_overall_SE < `nontest_halfcut', variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = sqrt(e(tau2))
estadd scalar Obs = e(N)

*7 trim & fill
meta set EstimatedEffect_overall EstimatedEffect_overall_SE
meta trimfill if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") , random
matrix nonscores = r(table)
local trimTau = .
local trimN = r(K_total)
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar Tabletau = sqrt(`trimTau')
estadd scalar Obs = `trimN'

*8 PEESE
eststo: robumeta EstimatedEffect_overall EstEfffect_Var if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstEfffect_Var) study(studyid)
estadd scalar Tabletau = sqrt(e(tau2))
estadd scalar Obs = e(N)

cd "`filepath'/Figures and Tables"
esttab using PubBiasregs.tex, replace se title("Meta-Regressions w/ Approaches to Potential Biases" "\label{tab:pubbiasregs}") varlabels(_cons "Avg. Effect") stats(k Tabletau Obs, labels("\hline" "\$\tau\$" "Observations")) addn("Test Score: (1) Andrews \& Kasy (2) SE $<$ `test_halfcut' (3) Meta Trim\&Fill (4) PEESE" "Educational Attainment: (5) Andrews \& Kasy (6) SE $<$ `nontest_halfcut' (7) Meta Trim\&Fill (8) PEESE") star(* .1 ** .05 *** .01) mgroups("Test Scores" "Educational Attainment", pattern (1 0 0 0  1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nomtitle drop(EstEfffect_Var) compress


**
*by Estimation Strategy
**
local reps = 400
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

keep if Study_isprimary

gen RD= Study_estimationstrategy=="RD"
gen IV= Study_estimationstrategy=="IV"
gen ES= regexm(Study_estimationstrategy, "ES")
gen notDiD = !regexm(Study_estimationstrategy, "DiD")

eststo clear
*1
eststo: robumeta EstimatedEffect_overall RD IV if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
testparm RD IV
estadd local p_equal = string(round(r(p), .0001), "%9.3f")

*2
eststo: robumeta EstimatedEffect_overall RD IV  if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
testparm RD IV
estadd local p_equal = string(round(r(p), .0001), "%9.3f")

cd "`filepath'/Figures and Tables"
esttab using EstStratRegs.tex, replace se title("Meta-Regressions w/ Estimation Strategy" "\label{eststratreg}") varlabels(_cons "Average Effect") addn("Event Study (strategy) omitted") star(* .1 ** .05 *** .01) stats(N tableTau p_equal, labels("Observations" "\$\tau\$" "RD = IV = 0 (p-val)")) mtitles("\shortstack{Test Scores}" "\shortstack{Educational\\Attainment}")


**
*by geography (Table A.3)
**
local reps = 400
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen South = (Sample_South1North2North == 1)
gen North = (Sample_South1North2North == 2)
gen Northeast = (Sample_South1North2North == 3)
gen West = (Sample_South1North2North == 4)

gen Urban = (Sample_Urban1Rural2None0 == 1)
gen Rural = (Sample_Urban1Rural2None0 == 2)

* for these, drop combined Rauscher (2020b) and only use separate urban and rural
drop if regexm(Article_Title, "Country") & Sample_Urban1Rural2None0 == 0

eststo clear
*1
eststo: robumeta EstimatedEffect_overall Study_ismultistate if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))

*2
eststo: robumeta EstimatedEffect_overall South North Northeast West if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))

*3
eststo: robumeta EstimatedEffect_overall Urban Rural if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var)
estadd scalar tableTau = sqrt(e(tau2))

*4
eststo: robumeta EstimatedEffect_overall Study_ismultistate if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))

*5
eststo: robumeta EstimatedEffect_overall South North Northeast West if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))

cd "`filepath'/Figures and Tables"
esttab using dimensions_metaregs.tex, replace se title("Meta-Analysis Estimates by Geographic Characteristics" "\label{tab:dimensionsreg}") varlabels(_cons "Average Effect" Study_ismultistate "Multistate") stats(N tableTau, labels("N" "\tau")) star(* .1 ** .05 *** .01) mtitles("\shortstack{Test Scores\\by Multistate}" "\shortstack{Test Scores\\by Region}" "\shortstack{Test Scores\\by Urbanicity}" "\shortstack{Educational\\Attainment\\by Multistate}" "\shortstack{Educational\\Attainment\\by Region}" "\shortstack{Educational\\Attainment\\by Urbanicity}") order(_cons) style(tex)  nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")



**
*linear in spend regressions (Table A.12)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen PPEchange_CPI_thous = PPEchange_CPIadjust/1000 if !PPEchange_isthous

// adjust those which make linear assumption within paper
replace PPEchange_CPI_thous = (PPE_policychange_CPIadjust/1000) if PPEchange_isthous
replace RAWEstimatedEffect_overall = RAWEstimatedEffect_overall*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous
replace RAWEstimatedEffect_overall_SE = RAWEstimatedEffect_overall_SE*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous
gen PPEchange_CPI_thousSQ = PPEchange_CPI_thous^2
gen RAWEstimatedEffect_overall_Var = RAWEstimatedEffect_overall_SE^2
label var PPEchange_CPI_thous "Policy on Exp. (\\$1000s)"
eststo clear

*1
robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(RAWEstimatedEffect_overall_Var) study(studyid)
local slopecoef_test = _b[PPEchange_CPI_thous]
local slopese_test = _se[PPEchange_CPI_thous]
count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local DF_test = r(N) - 1
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local metacoef_test = _b[_cons]
local metase_test = _se[_cons]
local tstat_test = (`metacoef_test' - `slopecoef_test')/(sqrt(`metase_test'^2 + `slopese_test'^2))
di `tstat_test'
local pval_equal = round(2*(ttail(`DF_test', abs(`tstat_test'))), .001)
di `pval_equal'
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar pvalequal = `pval_equal'

*2
robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !PPEchange_isthous & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(RAWEstimatedEffect_overall_Var) study(studyid)
local slopecoef_test = _b[PPEchange_CPI_thous]
local slopese_test = _se[PPEchange_CPI_thous]
count if !PPEchange_isthous & Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local DF_test = r(N) - 1
robumeta EstimatedEffect_overall if !PPEchange_isthous & Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local metacoef_test = _b[_cons]
local metase_test = _se[_cons]
local tstat_test = (`metacoef_test' - `slopecoef_test')/(sqrt(`metase_test'^2 + `slopese_test'^2))
di `tstat_test'
local pval_equal = round(2*(ttail(`DF_test', abs(`tstat_test'))), .001)
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !PPEchange_isthous & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar pvalequal = `pval_equal'

*3
robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(RAWEstimatedEffect_overall_Var) study(studyid)
local slopecoef_test = _b[PPEchange_CPI_thous]
local slopese_test = _se[PPEchange_CPI_thous]
count if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local DF_test = r(N) - 1
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local metacoef_test = _b[_cons]
local metase_test = _se[_cons]
local tstat_test = abs((`metacoef_test' - `slopecoef_test')/(sqrt(`metase_test'^2 + `slopese_test'^2)))
local pval_equal = round(2*(ttail(`DF_test', abs(`tstat_test'))), .001)
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar pvalequal = `pval_equal'

*4
robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !PPEchange_isthous & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(RAWEstimatedEffect_overall_Var) study(studyid)
local slopecoef_test = _b[PPEchange_CPI_thous]
local slopese_test = _se[PPEchange_CPI_thous]
count if !PPEchange_isthous & Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local DF_test = r(N) - 1
robumeta EstimatedEffect_overall if !PPEchange_isthous & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local metacoef_test = _b[_cons]
local metase_test = _se[_cons]
local tstat_test = (`metacoef_test' - `slopecoef_test')/(sqrt(`metase_test'^2 + `slopese_test'^2))
local pval_equal = round(2*(ttail(`DF_test', abs(`tstat_test'))), .001)
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !PPEchange_isthous & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar pvalequal = `pval_equal'

*5
xi: ivreg2 RAWEstimatedEffect_overall (PPEchange_CPI_thous = i.studyid) [weight = 1/(RAWEstimatedEffect_overall_Var + 0.0004 )] if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
local overid = e(sarganp)
local Fstat = e(F)
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar overidpval = `overid'
estadd scalar Fstat = `Fstat'

*6
xi: ivreg2 RAWEstimatedEffect_overall (PPEchange_CPI_thous = i.studyid) [weight = 1/(RAWEstimatedEffect_overall_Var + 0.0004 )] if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local overid = e(sarganp)
local Fstat = e(F)
eststo: robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(RAWEstimatedEffect_overall_Var) study(studyid)
estadd scalar overidpval = `overid'
estadd scalar Fstat = `Fstat'
	
cd "`filepath'/Figures and Tables"
esttab using linearinspend_regs.tex, replace se title("Relationship between Size of Policy Effect on Spending and Student Outcomes" "\label{tab:linearinspendreg}") stats(N pvalequal overidpval Fstat, label("N" "Pr(slope = pooled avg.)" "Overidentification p-val" "F-Stat")) scalars("pvalequal Pr(slope = avg.)") star(* .1 ** .05 *** .01) mtitle("\shortstack{Test Scores\\All}" "\shortstack{Test Scores\\w/o assumed}" "\shortstack{Ed Attain\\All}" "\shortstack{Ed Attain\\w/o assumed}" "\shortstack{IV Model\\Test}" "\shortstack{IV Model\\Ed Attain}") style(tex) l substitute(\sym{**} \sym{}) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")



**
*by capital sensitivity (Table A.11)
**
cd "`filepath'/Created Datasets"
*capLOW
use "SchoolSpendingPapers_capLOW", clear
eststo: robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
di `PW_se'
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
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
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"

*capHIGH
use "SchoolSpendingPapers_capHIGH", clear
eststo: robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
esttab est2
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
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
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"

*capNODEP
use "SchoolSpendingPapers_capNODEP", clear
eststo: robumeta EstimatedEffect_overall capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local tau2 = e(tau2)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
esttab est3
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
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
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"

cd "`filepath'/Figures and Tables"
esttab using capdep_sens_regs.tex, replace se title("Meta-Regression Estimates, by Depreciation Sensitivity" "\label{tab:capsens}") varlabels(_cons "Average Effect") stats(capitalEff capitalSE k N tableTau PI90_avg , labels("Capital" "(se)" "\hline"  "Observations" "\$\tau\$" "Average 90\% PI" )) star(* .1 ** .05 *** .01) mtitles("Low Depreciation" "High Depreciation" "No Depreciation") order(_cons capital) style(tex) substitute(_ _)nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)") l


**
*classify Title I as LI (Table A.9)
**
eststo clear
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

rename EstimatedEffect_lowinc EstEffLI
rename EstimatedEffect_nonlowinc EstEffnonLI

//only keep overall est now for Johnson
drop if !Study_isprimary & Article_Authors == "Johnson"
replace EstEffLI = 1 if regexm(Article_Authors, "Weinstein") | regexm(Article_Authors, "Cascio") | Article_Authors == "Johnson"

*test score
eststo: robumeta EstimatedEffect_overall EstEffLI EstEffnonLI capital if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar TableTau = sqrt(e(tau2))
local TableTau = e(tau2)
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
estadd local LInonLISum = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local LInonLISE = "(`SE')"
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `TableTau'^2)), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `TableTau'^2)), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
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
estadd local capitalEff = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local capitalSE = "(`SE')"
unique studyid if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
estadd scalar N_2 = r(unique)

*ed attain
eststo: robumeta EstimatedEffect_overall EstEffLI EstEffnonLI if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar TableTau = sqrt(e(tau2))
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
estadd local LInonLISum = string(round(r(estimate), .0001), "%9.3f") + "`sigstar'"
local SE = string(round(r(se), .0001), "%9.3f")
estadd local LInonLISE = "(`SE')"
esttab est2
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `TableTau')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `TableTau')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
unique studyid if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd scalar N_2 = r(unique)

cd "`filepath'/Figures and Tables"
esttab using TitleI_LIregs.tex, replace se title("Meta-Regression Estimates, Title I Classified as Low-Income" "\label{tab:TitleILIregs}") l varlabels(_cons "Overall" EstEffnonLI "Non-Low-Income") stats(LInonLISum LInonLISE k N N_2 TableTau PI90_avg, labels("LI - Non-LI" "(se)" "\hline" "Observations" "Clusters" "\$\tau\$" "Average 90\% PI"))   star(* .1 ** .05 *** .01) order(_cons EstEffLI EstEffnonLI) mgroups("Test Scores" "Educational Attainment", pattern(1 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nomtitles substitute(_ _) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")


**
*by F-stat > 20 (Table 4)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear


eststo clear

*1 fstat > 10 test
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10
estadd local estSD = string(round(r(sd), .0001), "%9.3f")


*2 fstat > 10 edattain
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 10
estadd local estSD = string(round(r(sd), .0001), "%9.3f")

keep if FirstStage_Fstat > 20

*3 unweighted test score
sum EstimatedEffect_overall_Var if nonRauschOverall
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

*4 RE test score
eststo: robumeta EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall_Var if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20 [weight=1/EstimatedEffect_overall_Var]
estadd scalar I2 = (`tau2')/(r(mean)+(`tau2'))
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*5 RE noncap test score
eststo: robumeta EstimatedEffect_overall if nonRauschOverall & PPE_dollarstype != "capital" & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if nonRauschOverall & PPE_dollarstype != "capital" & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*6 RE cap test score
eststo: robumeta EstimatedEffect_overall if PPE_dollarstype == "capital" & nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var)  study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if nonRauschOverall & PPE_dollarstype == "capital" & nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

*7 edattain unweighted
sum EstimatedEffect_overall_Var if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen equalvar = r(mean)
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(equalvar) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
sum EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop equalvar

*8 RE edattain
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))
local tau2 = e(tau2)
gen weight_re = (1/(EstimatedEffect_overall_Var + e(tau2)))
sum EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") [weight = weight_re]
estadd local estSD = string(round(r(sd), .0001), "%9.3f")
drop weight_re

cd "`filepath'/Figures and Tables"
esttab using Fstat20_regs.tex, replace se title("Meta-Analysis, by Strength of First Stage" "\label{tab:fstat20reg}") varlabels(_cons "Average Effect") stats(N estSD tau, labels("N" "SD of \$\hat{\theta}_j\$}'s" "\$\tau\$" )) mtitles("\shortstack{Overall\\Test Scores}" "\shortstack{Overall\\Ed. Attainment}" "\shortstack{Equal Weight\\Test Scores}" "\shortstack{Overall\\Test Scores}" "\shortstack{Non-Capital\\Test Score}" "\shortstack{Capital\\Test Score}" "\shortstack{Equal Weight\\Ed. Attainment}" "\shortstack{Overall\\Ed. Attainment}") substitute(_ _) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers.") nostar mgroups("F-stat \$>\$ 10" "F-stat \$>\$ 20", pattern(1 0 1 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span}))


/*
//WITHIN AND ACROSS SENSITIVITY (Table A.10)
*/
eststo clear
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_sensA, clear
*1 "(w/in pop. low (0.25) // across pop. low (0))"
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"


*2
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

use SchoolSpendingPapers_sensB, clear
*3 "(w/in pop. low (0.25) // across pop. high (0.5))"
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*4
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

use SchoolSpendingPapers_sensC, clear
*5 "(w/in pop. high (0.75) // across pop. low (0))"
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*6
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

use SchoolSpendingPapers_sensD, clear
*7 "(w/in pop. high (0.75) // across pop. high (0.5))"
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*8
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

cd "`filepath'/Figures and Tables"
esttab using withinAcrossSens.tex, replace se title("Meta-Regression Estimates by Within and Across Correlations" "\label{tab:withinacrosssens_regs}") varlabels(_cons "Average Effect") star(* .1 ** .05 *** .01) stats(N tableTau PI90_avg, labels("Observations" "\$\tau\$" "Average 90\% PI")) mtitles("\shortstack{Test\\Scores}" "\shortstack{Educational\\Attainment}" "\shortstack{Test\\Scores}" "\shortstack{Educational\\Attainment}" "\shortstack{Test\\Scores}" "\shortstack{Educational\\Attainment}" "\shortstack{Test\\Scores}" "\shortstack{Educational\\Attainment}") substitute(\ \) mgroups("\shortstack{(w/in pop. low (0.25)\\across pop. low (0))}" "\shortstack{(w/in pop. low (0.25)\\across pop. high (0.5))}" "\shortstack{(w/in pop. high (0.75)\\across pop. low (0))}" "\shortstack{(w/in pop. high (0.75)\\across pop. high (0.5))}", pattern(1 0 1 0 1 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")



/*
//CORRELATION SENSITIVITY (Table A.8)
*/
eststo clear
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_CovNeg1, clear
*1
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*2
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

use SchoolSpendingPapers_CovPos1, clear
*3
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*4
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

cd "`filepath'/Figures and Tables"
esttab using byCorrSens.tex, replace se title("Meta-Regression Estimates by Correlation Sensitivity" "\label{tab:corrsens_regs}") varlabels(_cons "Average Effect") star(* .1 ** .05 *** .01) stats(N tableTau PI90_avg, labels("Observations" "\$\tau\$" "Average 90\% PI")) mtitles("\shortstack{Test Scores}" "\shortstack{Educational Attainment}" "\shortstack{Test Scores}" "\shortstack{Educational Attainment}") substitute(\ \) mgroups("Corr = -1" "Corr = 1" , pattern(1 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonotes addn("Standard errors in parentheses are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")



**
*By whether IV is constructed
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
local filename constructedIV_regs
cd "`filepath'"
gen constructedIV = EstimatedEffect_SE_underreported
label var constructedIV "Constructed IV"
eststo clear
*1
eststo: robumeta EstimatedEffect_overall if !constructedIV & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)

*2
eststo: robumeta EstimatedEffect_overall if !constructedIV & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)

cd "`filepath'/Figures and Tables"
esttab using `filename'.tex, replace se title("Meta-Analysis Estimates" "Papers without Constructed IV" "\label{tab:constructedIV}") varlabels(_cons "Average Effect") stats(N , labels("N")) star(* .1 ** .05 *** .01) mtitles("\shortstack{Overall\\Test Scores}" "\shortstack{Overall\\Educational\\Attainment}") order(_cons) style(tex) substitute(_ _) 


**
***overall no clustering, robustSDadjust, constructedIV (Table A.7)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
eststo clear

*1
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"


*2
eststo: robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*3
preserve
keep if Article_Authors != "Kogan Lavertu Peskowitz"
keep if !regexm(Article_Authors, "Rauscher")
*1
eststo: robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"
restore

gen constructedIV = EstimatedEffect_SE_underreported
label var constructedIV "Constructed IV"
*4
eststo: robumeta EstimatedEffect_overall if !constructedIV & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

*5
eststo: robumeta EstimatedEffect_overall if !constructedIV & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tableTau = sqrt(e(tau2))
local PW_mean = _b[_cons]
local tau2 = e(tau2)
esttab est1
local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
local lowerPI = string(round(`PW_mean' - 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
local upperPI = string(round(`PW_mean' + 1.65*sqrt((`PW_se'^2 + `tau2')), .0001), "%9.3f")
estadd local PI90_avg = "[`lowerPI',`upperPI']"

cd "`filepath'/Figures and Tables"
esttab using noClustSDIV_sensregs.tex, replace se title("Meta-Regression Estimates" "\label{tab:noclustSDIV_sensregs}") varlabels(_cons "Average Effect") stats(N tableTau PI90_avg, labels("Observations" "\$\tau\$" "Average 90\% PI")) star(* .1 ** .05 *** .01) mtitles("\shortstack{Test Scores}" "\shortstack{Educational Attainment}" "\shortstack{Test Scores}" "\shortstack{Test Scores}" "\shortstack{Educational Attainment}") order(_cons) style(tex) substitute(_ _) mgroups("No Clustering" "No SD Adjustment" "No Constructed IV", pattern(1 0 1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonotes addn("Standard errors in parentheses. Standard errors in models 3-5 are adjusted for clustering of related papers." "\footnotesize \sym{*} \(p<.1\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)")


/*
returns by baseline (Figure A.6)
*/
set scheme plotplainblind
forvalues i = 1/2{
	if `i' == 1{
		local titleadd "ONEPER"
		cd "`filepath'/Created Datasets"
		use SchoolSpendingPapers_overall, clear
		keep if Study_isprimary

		//precision-weight Baron's two test score estimates (from capital and operational)
		count
		forvalues i = 1/`r(N)'{
			if Article_Authors2[`i'] == "Baron" & Study_outcome[`i'] == "Test scores"{
				if PPE_dollarstype[`i'] == "capital"{
					local Effect1 = EstimatedEffect_overall[`i']
					local SE1 = EstimatedEffect_overall_SE[`i']
				}
				else if PPE_dollarstype[`i'] == "operational"{
					local Effect2 = EstimatedEffect_overall[`i']
					local SE2 = EstimatedEffect_overall_SE[`i']
				}
			}
		}
		local BaronTestEffect = (`Effect1' + `Effect2')/2
		local BaronTestSE = (0.25*(`SE1'^2 + `SE2'^2))^(1/2)
		di "`BaronTestEffect'"
		di "`BaronTestSE'"

		replace EstimatedEffect_overall = `BaronTestEffect' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
		replace EstimatedEffect_overall_SE = `BaronTestSE' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
		drop if Article_Authors=="Baron c" //then, Baron has just one test score estimate

	}
	else if `i' == 2{
		local titleadd "MULTPER"
		cd "`filepath'/Created Datasets"
		use SchoolSpendingPapers_overall, clear

		robumeta EstimatedEffect_overall PPEbaseline_CPIadjust if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), study(studyid) variance(EstimatedEffect_overall_Var)
		local testslope_beta = string(round(_b[PPEbaseline_CPIadjust], .000001), "%9.5f")
		robumeta EstimatedEffect_overall PPEbaseline_CPIadjust if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), study(studyid) variance(EstimatedEffect_overall_Var)
		local nontestslope_beta = string(round(_b[PPEbaseline_CPIadjust], .000001), "%9.5f")
		reg EstimatedEffect_overall PPEbaseline_CPIadjust if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), cluster(studyid)
		local testnaive_beta = string(round(_b[PPEbaseline_CPIadjust], .000001), "%9.5f")
		reg EstimatedEffect_overall PPEbaseline_CPIadjust if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates"), cluster(studyid)
		local nontestnaive_beta = string(round(_b[PPEbaseline_CPIadjust], .000001), "%9.5f")
		
	}
	//make figures
	cd "`filepath'/Figures and Tables"
	twoway (lfitci EstimatedEffect_overall PPEbaseline_CPIadjust if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2], estopts(cluster(studyid)) legend(off) title("Test Scores") ytitle("Effect per $1000 in PPE")) (scatter EstimatedEffect_overall PPEbaseline_CPIadjust if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(circle_hollow) ) (scatter EstimatedEffect_overall PPEbaseline_CPIadjust if (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(none) mlabel(Article_Authors)), note("Precision-weighted slope: `testslope_beta'; Naive equal-weighted slope: `testnaive_beta'", size(small))
	graph save Graph baselinePPE_scores`titleadd'.gph, replace

	twoway (lfitci EstimatedEffect_overall PPEbaseline_CPIadjust if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")   [weight=1/EstimatedEffect_overall_SE^2], estopts(cluster(studyid)) legend(off) title("Educational Attainment")) (scatter EstimatedEffect_overall PPEbaseline_CPIadjust if !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & EstimatedEffect_overall<2 [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(circle_hollow) )  (scatter EstimatedEffect_overall PPEbaseline_CPIadjust if  !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & EstimatedEffect_overall<2 [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(none) mlabel(Article_Authors)), note("Precision-weighted slope: `nontestslope_beta'; Naive equal-weighted slope: `nontestnaive_beta'", size(small))
	graph save Graph baselinePPE_nontest`titleadd'.gph, replace

	graph combine baselinePPE_scores`titleadd'.gph baselinePPE_nontest`titleadd'.gph, xsize(8) ysize(4)
	graph export returnsbybaseline`titleadd'.pdf, replace

}

/*
********************************************************************************
are effects linear in spend? (Figure 3) // (Figure A.5)
********************************************************************************
*/
set scheme plotplainblind
clear frames
forvalues i = 1/2{
	if `i' == 1{
		cd "`filepath'/Created Datasets"
		use SchoolSpendingPapers_overall, clear

		//vars set-up
		gen PPEchange_CPI_thous = PPEchange_CPIadjust/1000 if !PPEchange_isthous
		*adjust those which make linear assumption within paper
		replace PPEchange_CPI_thous = (PPE_policychange_CPIadjust/1000) if PPEchange_isthous
		replace RAWEstimatedEffect_overall = RAWEstimatedEffect_overall*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous
		replace RAWEstimatedEffect_overall_SE = RAWEstimatedEffect_overall_SE*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous

		label var PPEchange_CPI_thous "Policy Effect on Per-Pupil Spending, thousands ($2018)"
		gen PPEchange_CPI_thousSQ = PPEchange_CPI_thous^2
		gen RAWEstimatedEffect_overall_Var = RAWEstimatedEffect_overall_SE^2
		keep if Study_isprimary
		local titleadd "ONEPER"
	}
	if `i' == 2{
		cd "`filepath'/Created Datasets"
		use SchoolSpendingPapers_overall, clear

		//vars set-up
		gen PPEchange_CPI_thous = PPEchange_CPIadjust/1000 if !PPEchange_isthous
		*adjust those which make linear assumption within paper
		replace PPEchange_CPI_thous = (PPE_policychange_CPIadjust/1000) if PPEchange_isthous
		replace RAWEstimatedEffect_overall = RAWEstimatedEffect_overall*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous
		replace RAWEstimatedEffect_overall_SE = RAWEstimatedEffect_overall_SE*(PPE_policychange_CPIadjust/PPEchange) if PPEchange_isthous

		label var PPEchange_CPI_thous "Policy Effect on Per-Pupil Spending, thousands ($2018)"
		gen PPEchange_CPI_thousSQ = PPEchange_CPI_thous^2
		gen RAWEstimatedEffect_overall_Var = RAWEstimatedEffect_overall_SE^2
		local titleadd "MULTPER"
	}
	//make figures
	
	*test score
	preserve
	keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
	count
	local counter = r(N)
	frame copy default linearinspend_test`titleadd'
	frame change linearinspend_test`titleadd'
	keep RAWEstimatedEffect_overall RAWEstimatedEffect_overall_SE PPEchange_CPI_thous Article_Authors
	gen scatterInd = 1
	tempfile temp1
	save "`temp1'"

	frame change default
	xi: ivreg2 RAWEstimatedEffect_overall (PPEchange_CPI_thous = i.studyid) [weight = 1/(RAWEstimatedEffect_overall_Var + 0.0004 )] if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
	
	local overidpval = string(round(e(sarganp), .0001), "%9.4f")
	robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous, variance(RAWEstimatedEffect_overall_Var) study(studyid)
	local slope_beta = string(round(_b[PPEchange_CPI_thous], .0001), "%9.4f")
	di `slope_beta'
	local slope_t = _b[PPEchange_CPI_thous]/_se[PPEchange_CPI_thous]
	di `slope_t'
	local slope_pval = string(round(2*ttail(e(dfs)[1,1],abs(`slope_t')), .0001), "%9.3f")
	di `slope_pval'

	local cons_beta = string(round(_b[_cons], .0001), "%9.4f")
	di `cons_beta'
	local cons_t = _b[_cons]/_se[_cons]
	di `cons_t'
	local cons_pval = string(round(2*ttail(e(dfs)[1,2],abs(`cons_t')), .0001), "%9.3f")
	di `cons_pval'

	local cons_df = e(dfs)[1,2]

	forvalues i = 1(1)450{
		capture confirm variable coef`i'
		if !_rc{
		}
		else{
			local multiplier = `i'/100 - 1.5
			lincom _cons + `multiplier'*PPEchange_CPI_thous
			gen coef`i' = r(estimate)
			gen se`i' = r(se)
		}
	}

	collapse (mean) coef1-se450
	gen i = 1
	reshape long coef se, i(i) j(Spend_Effect)

	replace Spend_Effect = Spend_Effect/100 - 1.5
	local crit_t = invttail(`cons_df', .025)
	gen se_upper = coef + (`crit_t'*se)
	gen se_lower = coef - (`crit_t'*se)
	gen scatterInd = 0
	append using "`temp1'"
	twoway (connected coef Spend_Effect if !scatterInd, lpattern(solid) msymbol(none)) (rarea se_upper se_lower Spend_Effect, fcolor(white) color(purple%50)) (scatter RAWEstimatedEffect_overall PPEchange_CPI_thous if Article_Authors != "Roy" & Article_Authors != "Chaudhary" [w = 1/RAWEstimatedEffect_overall_SE^2], msymbol(circle_hollow)) (scatter RAWEstimatedEffect_overall PPEchange_CPI_thous if Article_Authors!= "Roy" & Article_Authors != "Chaudhary", m(none) mlabel(Article_Authors) mlabsize(tiny)), legend(pos(7) order(1 "Linear w/ 95% CI")) note("Precision-weighted linear slope: `slope_beta' (p-value = `slope_pval')," " constant: `cons_beta' (p-value = `cons_pval')" "Instrument overidentification test p-value: `overidpval'" "Roy (2011) and Chaudhary (2009) not plotted for scale.", size(small)) title("Test Scores") ytitle("Policy Effect on Outcomes") xtitle("Policy Effect on Per-Pupil Spending, thousands ($2018)") xlabel(-1(1)3)
	
	cd "`filepath'/Figures and Tables"
	graph save linearinspend_testscore`titleadd'.gph, replace
	graph export linearinspend_testscore`titleadd'.pdf, replace
	restore

	//edattainment
	preserve
	keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
	count
	local counter = r(N)
	frame copy default linearinspend_nontest`titleadd'
	frame change linearinspend_nontest`titleadd'
	keep RAWEstimatedEffect_overall RAWEstimatedEffect_overall_SE PPEchange_CPI_thous Article_Authors
	gen scatterInd = 1
	tempfile temp2
	save "`temp2'"

	frame change default
	xi: ivreg2 RAWEstimatedEffect_overall (PPEchange_CPI_thous = i.studyid) [weight = 1/(RAWEstimatedEffect_overall_Var + 0.00029 )] if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
	local overidpval = string(round(e(sarganp), .0001), "%9.4f")
	robumeta RAWEstimatedEffect_overall PPEchange_CPI_thous, variance(RAWEstimatedEffect_overall_Var) study(studyid)
	local slope_beta = string(round(_b[PPEchange_CPI_thous], .0001), "%9.4f")
	di `slope_beta'
	local slope_t = _b[PPEchange_CPI_thous]/_se[PPEchange_CPI_thous]
	di `slope_t'
	local slope_pval = string(round(2*ttail(e(dfs)[1,1],abs(`slope_t')), .0001), "%9.3f")
	di `slope_pval'

	local cons_beta = string(round(_b[_cons], .0001), "%9.4f")
	di `cons_beta'
	local cons_t = _b[_cons]/_se[_cons]
	di `cons_t'
	local cons_pval = string(round(2*ttail(e(dfs)[1,2],abs(`cons_t')), .0001), "%9.3f")
	di `cons_pval'

	local cons_df = e(dfs)[1,2]

	forvalues i = 1(1)400{
		capture confirm variable coef`i'
		if !_rc{
		}
		else{
			local multiplier = `i'/100 - 1.5
			lincom _cons + `multiplier'*PPEchange_CPI_thous
			gen coef`i' = r(estimate)
			gen se`i' = r(se)
		}
	}


	collapse (mean) coef1-se400
	gen i = 1
	reshape long coef se, i(i) j(Spend_Effect)

	replace Spend_Effect = Spend_Effect/100 - 1.5

	local crit_t = invttail(`cons_df', .025)
	di `counter'
	di `crit_t'
	gen se_upper = coef + (`crit_t'*se)
	gen se_lower = coef - (`crit_t'*se)
	gen scatterInd = 0
	append using "`temp2'"
	twoway (connected coef Spend_Effect if !scatterInd, lpattern(solid) msymbol(none)) (rarea se_upper se_lower Spend_Effect, fcolor(white) color(purple%50)) (scatter RAWEstimatedEffect_overall PPEchange_CPI_thous [w = 1/RAWEstimatedEffect_overall_SE^2], msymbol(circle_hollow)) (scatter RAWEstimatedEffect_overall PPEchange_CPI_thous, m(none) mlabel(Article_Authors) mlabsize(tiny)), legend(pos(7) order(1 "Linear w/ 95% CI")) note("Precision-weighted linear slope: `slope_beta' (p-value = `slope_pval')" " constant: `cons_beta' (p-value = `cons_pval')" "Instrument overidentification test p-value: `overidpval'", size(small)) title("Educational Attainment") ytitle("") xtitle("Policy Effect on Per-Pupil Spending, thousands ($2018)") xlabel(-1(1)2.5)

	cd "`filepath'/Figures and Tables"
	graph save linearinspend_nontestscore`titleadd'.gph, replace
	graph export linearinspend_nontestscore`titleadd'.pdf, replace
	restore
	
	//combine across outcomes into one figure
	cd "`filepath'/Figures and Tables"
	graph combine linearinspend_testscore`titleadd'.gph linearinspend_nontestscore`titleadd'.gph, ycommon
	graph export linearinspend_combined`titleadd'.pdf, replace
}




/*
********************************************************************************
effect size PPE forest plots (Figure 2) // (Figure A.3)
********************************************************************************
*/
clear frames
**** Define the bootstrap parameters ***
local p=99
local reps=400

cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

forvalues i = 1/8{
	preserve
	if `i' == 1{
		//overall test score
		keep if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
		local filename "overall_testscore"
		local title "Test Scores"
		local lowerX = -.8
		local upperX = .8
	}
	else if `i' == 2{
		//capital test score
		keep if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & PPE_dollarstype == "capital"
		local filename "capital_testscore"
		local title "Capital Test Scores"
		local lowerX = -.8
		local upperX = .8
	}
	else if `i' == 3{
		//non-capital test score
		keep if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & PPE_dollarstype != "capital"
		local filename "noncapital_testscore"
		local title "Non-Capital Test Scores"
		local lowerX = -.8
		local upperX = .8
	}
	else if `i' == 4{
		//overall non-test score
		keep if Study_isprimary & Study_outcome != "Test scores" & Study_outcome != "Test proficiency rates"
		local filename "overall_nontestscore"
		local title "Educational Attainment"
		local lowerX = -.2
		local upperX = 1
	}
	else if `i' == 5{
		//overall test score MULTIPLE ests per paper
		keep if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
		local filename "multper_testscore"
		local title "Test Score"
		replace Article_Authors2 = Article_Authors2 + " LI" if EstimatedEffect_lowinc
		replace Article_Authors2 = Article_Authors2 + " Non-LI" if EstimatedEffect_nonlowinc
		local lowerX = -.8
		local upperX = .8
	}
	else if `i' == 6{
		//overall non-test score MULTIPLE ests per paper
		keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
		local filename "multper_nontest"
		local title "Educational Attainment"
		replace Article_Authors2 = Article_Authors2 + " LI" if EstimatedEffect_lowinc
		replace Article_Authors2 = Article_Authors2 + " Non-LI" if EstimatedEffect_nonlowinc
		local lowerX = -.2
		local upperX = 1
	}
	else if `i' == 7{
		//f>20 test
		keep if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20
		local filename "fstat_test"
		local title "First Stage > 20, Test Score"
		
	}
	else if `i' == 8{
		//f>20 edattain
		keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
		keep if FirstStage_Fstat > 20
		local filename "fstat_edattain"
		local title "First Stage > 20, Educational Attainment"
	}

	gen ll = EstimatedEffect_overall - 1.96*EstimatedEffect_overall_SE
	gen ul = EstimatedEffect_overall + 1.96*EstimatedEffect_overall_SE

	sort EstimatedEffect_overall
	gen id = _n
	sort id
	unique id
	local maxID = r(N)
	gen Article_Year_str = Article_Year
	replace Article_Authors2 = Article_Authors2 + ", capital" if Article_Authors == "Baron c" & capital
	replace Article_Authors2 = Article_Authors2 + ", operational" if Article_Authors == "Baron" & Study_outcome == "Test scores"
	replace Article_Authors2 = Article_Authors2 + ", rural" if Article_Authors == "Rauscher b" & Sample_Urban1Rural2None0 == 2
	replace Article_Authors2 = Article_Authors2 + ", nonrural" if Article_Authors == "Rauscher b" & Sample_Urban1Rural2None0 == 1
	replace Article_Year_str = Article_Year_str + "a" if Article_Authors == "Rauscher a"
	replace Article_Year_str = Article_Year_str + "b" if Article_Authors == "Rauscher b"
	if `i' == 7 | `i' == 8{
		replace Article_Authors2 = Article_Authors2 + " LI" if EstimatedEffect_lowinc
		replace Article_Authors2 = Article_Authors2 + " non-LI" if !Study_isprimary & !EstimatedEffect_lowinc
	}
	gen id_label = Article_Authors2 + " (" + Article_Year_str + ")"
	labmask id, values(id_label)
	sum EstimatedEffect_overall, detail
	local median = string(round(r(p50), 0.0001), "%12.4f")
	local mean = string(round(r(mean), .0001), "%9.4f")
	local standdev = round(r(sd), .0001)
	local quart1 = string(round(r(p25), .0001), "%9.4f")
	local quart3 = string(round(r(p75), .0001), "%9.4f")
	local IQR = round(r(p75) - r(p25), .0001)

	local Graph_note1 = "mean: `mean'" + " median: `median'"
	local Graph_note2 = "25th %-ile: `quart1'" +  " 75th %-ile: `quart3'"
	capture: robumeta EstimatedEffect_overall if Study_isprimary, variance(EstimatedEffect_overall_Var)
	capture: local meta_mean = string(round(_b[_cons], .0001), "%9.4f")
	capture: local Graph_note3 = "RE mean: `meta_mean'"
	
	//include robumeta estimate for outcome type:
	if `i' == 1 | `i' == 4 | `i' == 5 | `i' == 6{
		
		eststo clear
		eststo: robumeta EstimatedEffect_overall, variance(EstimatedEffect_overall_Var) study(studyid)
		local PW_mean = _b[_cons]
		local tau = sqrt(e(tau2))
		esttab
		local PW_se = r(coefs)[1,1]/r(coefs)[1,2]
		
		if `i' == 5 | `i' == 6{
			local fontsize "vsmall"
		}
		else{
			local fontsize "small"
		}
				
		frame change default
		count
		local tstat = abs(invt(r(N)-2, .025))
		di "TSTAT = `tstat'"
		local lowerPI = `PW_mean' - `tstat'*sqrt((`PW_se'^2 + `tau'^2))
		local upperPI = `PW_mean' + `tstat'*sqrt((`PW_se'^2 + `tau'^2))
		local lowerCI = `PW_mean' - `tstat'*sqrt((`PW_se'^2))
		local upperCI = `PW_mean' + `tstat'*sqrt((`PW_se'^2))
		capture: frame drop temp_bs
		unique id
		local maxID = `r(N)'
		gen lowID = 0
		gen highID = `maxID'
		count
		gen EstRangePI = `lowerPI' if _n < r(N)/2
		replace EstRangePI = `upperPI' if missing(EstRangePI)
		count
		gen EstRangeCI = `lowerCI' if _n < r(N)/2
		replace EstRangeCI = `upperCI' if missing(EstRangeCI)
		count
		
		if `i' != 6{
			twoway (scatter id EstimatedEffect_overall, msymbol(plus) legend(off) xtitle("Effect per \$1000 in PPE")) ///
			(area lowID highID EstRangePI, color(black) lpattern(solid)) ///
			(area lowID highID EstRangeCI, color(gs6)) ///
			(rcap ll ul id if ll > -1 & ul < 3, horizontal ytitle("")) ///
			(rspike ll ul id if ll > -1 & ul < 3, horizontal) ///
			(scatter id ll, msymbol(pipe)), ///
			ylabel(1(1)`maxID', valuelabel labsize(`fontsize')) title("`title'") ///
			xlab(`lowerX'(.4)`upperX')
		}
		if `i' == 6{
			twoway (scatter id EstimatedEffect_overall, msymbol(plus) legend(off) xtitle("Effect per \$1000 in PPE")) ///
			(area lowID highID EstRangePI, color(black) lpattern(solid)) ///
			(area lowID highID EstRangeCI, color(gs6)) ///
			(rcap ll ul id if ll > -1 & ul < 3, horizontal ytitle("")) ///
			(rspike ll ul id if ll > -1 & ul < 3, horizontal) ///
			(scatter id ll, msymbol(pipe)), ///
			ylabel(1(1)`maxID', valuelabel labsize(`fontsize')) title("`title'") ///
			xlab(-.2 "-.2" 0 "0" .2 ".2" .6 ".6" 1 "1")
		}
		

	}
	
	//just basic forest plot if not enough estimates for robumeta:
	if `i' == 2 | `i' == 3 | `i' == 7 | `i' == 8 {
		unique id
		local maxID = `r(N)'
		twoway (scatter id EstimatedEffect_overall, msymbol(plus) legend(off) xtitle("Effect per \$1000 in PPE")) ///
		(rcap ll ul id if !regexm(Article_Authors, "Matsudaira"), horizontal ytitle("")) ///
		(rspike ll ul id if !regexm(Article_Authors, "Matsudaira"), horizontal lcolor(gs20)) ///
		(scatter id ll if !regexm(Article_Authors, "Matsudaira"), msymbol(pipe) mcolor(gs10)), ///
		ylabel(1(1)`maxID', valuelabel)  title("`title'")	
		//note("`Graph_note1'" "`Graph_note2'")	
	}
	
	cd "`filepath'/Figures and Tables"
	graph save `filename'_forest, replace
	graph export `filename'_forest.pdf, replace
	restore
}



/*
//BS tau density (Figure A.4)
*/
local spec "testOverall"
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen plottau = sqrt(_bs_1)
kdensity plottau if plottau > 0, xtitle("Test Score")
cd "`filepath'/Figures and Tables"
graph save test_bs.gph, replace


local spec "nontestOverall"
use "`filepath'/BS Data/bstest`spec'.dta" , clear
gen plottau = sqrt(_bs_1)
kdensity plottau if plottau > 0, xtitle("Educational Attainment")
cd "`filepath'/Figures and Tables"
graph save nontest_bs.gph, replace

graph combine test_bs.gph nontest_bs.gph
graph export bstau_comb.pdf, replace

/*
********************************************************************************
Histogram of dates (Figure A.2)
********************************************************************************
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
keep if !missing(Article_Authors2)
keep if Study_isprimary
drop if regexm(Study_outcome, "Poverty")
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"
keep if Article_Authors != "Biasi"
keep if Article_Authors != "Card Payne"
keep if Article_Authors != "Deke"
keep if Article_Authors != "Schlaffer Burge"
keep if !regexm(EstimtedEffect1_source, "made up")
bysort Article_Authors2: keep if _n==_N

destring(Article_Year), replace
histogram Article_Year, freq bin(25) ytitle("") xtitle("")

cd "`filepath'/Figures and Tables"
graph export dateHist.pdf, replace

/*
********************************************************************************
Depreciation graphic (Figure A.13)
********************************************************************************
*/
set scheme plotplainblind
clear frames
cd "`filepath'/Input Data"
import excel "CapitalProjectsYrXYr.xlsx", sheet("depreciation_exemplar") firstrow clear

cd "`filepath'/Figures and Tables"
twoway scatter NZ time || scatter MSM time, xtitle("Time") ytitle("Present Value ($2018)") legend(lab(1 "Neilson & Zimmerman (2014)") lab(2 "Martorell et al. (2016)") pos(7))
graph save depexemplar, replace
graph export depexemplar.pdf, replace


/*
********************************************************************************
capital ES over time, graphics and regressions Figure 1
********************************************************************************
*/

set scheme plotplainblind
cd "`filepath'/Created Datasets"
use capitalproj_combined, clear

keep if !regexm(paper, "LI")
encode(paper) if !regexm(paper, "LI"), gen(paperid_noLI)
sort time

gen ll = comb_est_rel0 - 1.96*comb_se
gen ul = comb_est_rel0 + 1.96*comb_se

local graphcommand ""
local legend ""
local counter = 2
tab paperid_noLI
sort time paperid_noLI
local numpapers = `r(r)'
di "`numpapers'"
local counter = `numpapers' - 1
forvalues i = 1/`counter'{
	local graphcommand "`graphcommand' connected comb_est_rel0 time if paperid_noLI == `i' & time < 7, msize(large) || "

}
local graphcommand "`graphcommand' connected comb_est_rel0 time if paperid_noLI == `numpapers' & time < 7, msize(large) "
	
di "GRAPH COMMAND: `graphcommand'"

sort time
twoway `graphcommand', legend(size(vsmall) order(1 "Baron (2022)" 2 "Cellini, Ferriera, Rothstein (2010)" 3 "Conlin & Thompson (2017)" 4 "Goncalves (2015)" 5 "Hong & Zimmer (2016)" 6 "Lafortune & Schonholzer (2022)" 7 "Martorell, Stange, McFarlin (2016)" 8 "Neilson & Zimmerman (2014)" 9 "Rauscher (2020)") pos(7) col(2)) xtitle("Time") ytitle("Test Score Effect") title("Individual Study Impacts")  plotregion(color(white)) legend(region(lstyle(none))) note("Note: Lafortune & Schonholzer (2022) reports linear effects over time.", size(vsmall))

cd "`filepath'/Figures and Tables"
graph save capital_overtime, replace
graph export capital_overtime.pdf, replace

*precision
cd "`filepath'/Created Datasets"
use capitalproj_combined, clear
keep if !regexm(paper, "LI")
gen invVar = 1/(comb_se^2)
reg comb_est_rel0 i.time [weight = invVar] if time < 7 & time > 0, cluster(paperid) robust
gen coef0 = 0
gen se0 = 0
forvalues i = 1/6{
	lincom _cons + _b[`i'.time]
	gen coef`i' = r(estimate)
	gen se`i' = r(se)
}

collapse (mean) coef0-se6
gen i = 1
reshape long coef se, i(i) j(time)
gen se_upper90 = coef + (1.645*se)
gen se_lower90 = coef - (1.645*se)

gen se_upper95 = coef + (1.96*se)
gen se_lower95 = coef - (1.96*se)

twoway (connected coef time) (rarea se_upper90 se_lower90 time, fcolor(grey%80) color(purple%90)) (rarea se_upper95 se_lower95 time, fcolor(grey%50) color(purple%90)), saving(precision, replace) legend(order(1  "Average Effect" 2 "90% CI" 3 "95% CI") pos(7) row(1)) title("Precision-Weighted Average") xtitle("Time") plotregion(color(none)) legend(size(vsmall) region(lstyle(none))) note("For both figures, time is year relative to construction or spending increase." "Effect is the standardized effect, relative to year 0.",size(vsmall)) title("Average Impacts Across Studies") plotregion(color(white)) legend(size(vsmall) region(lstyle(none)))

cd "`filepath'/Figures and Tables"
graph save capovertime_estsPW, replace
graph export CapitalOverTimeEstsPW.pdf, replace


//COMBINE FOR TEX
graph combine capital_overtime.gph capovertime_estsPW.gph, plotregion(color(white))
graph export combined_capovertime.pdf, replace

**
*FUNNEL PLOTS (Figure 4)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
keep if !missing(Article_Authors2)

drop if regexm(Study_outcome, "Poverty")
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"
keep if Article_Authors != "Biasi"
keep if Article_Authors != "Card Payne"
keep if Article_Authors != "Deke"
keep if Article_Authors != "Schlaffer Burge"
keep if !regexm(EstimtedEffect1_source, "made up")

//FUNNELS, MULTIPLE PER
meta set EstimatedEffect_overall EstimatedEffect_overall_SE
meta trimfill if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), funnel(title("") msize(2 large 4 large) legend(rows(2) pos(6)) title("Test scores") )
gr_edit .plotregion1.plot4.style.editstyle marker(size(large))
cd "`filepath'/Figures and Tables"
graph save testtrim_multper, replace
graph export TrimFillTestScore_multper.pdf, replace

meta trimfill if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), funnel(title("") msize(2 large 4 large) ytitle("") legend(rows(2) pos(6)) title("Educational Attainment"))
gr_edit .plotregion1.plot4.style.editstyle marker(size(large))
cd "`filepath'/Figures and Tables"
graph save nontesttrim_multper, replace
graph export TrimFillNonTestScore_multper.pdf, replace

graph combine testtrim_multper.gph nontesttrim_multper.gph
graph export trimcombined_multper.pdf, replace


/*
by-spend change effects figure (Figure A.7)
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
keep if Study_isprimary

keep if !regexm(Article_Authors, "Chaud")
//precision-weight Baron's two test score estimates (from capital and operational)
count
forvalues i = 1/`r(N)'{
	if Article_Authors2[`i'] == "Baron" & Study_outcome[`i'] == "Test scores"{
		if PPE_dollarstype[`i'] == "capital"{
			local Effect1 = EstimatedEffect_overall[`i']
			local SE1 = EstimatedEffect_overall_SE[`i']
		}
		else if PPE_dollarstype[`i'] == "operational"{
			local Effect2 = EstimatedEffect_overall[`i']
			local SE2 = EstimatedEffect_overall_SE[`i']
		}
	}
}

local BaronTestEffect = (`Effect1' + `Effect2')/2
local BaronTestSE = (0.25*(`SE1'^2 + `SE2'^2))^(1/2)
di "`BaronTestEffect'"
di "`BaronTestSE'"

replace EstimatedEffect_overall = `BaronTestEffect' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
replace EstimatedEffect_overall_SE = `BaronTestSE' if Article_Authors2 == "Baron" & Study_outcome == "Test scores"
drop if Article_Authors=="Baron c" //then, Baron has just one test score estimate

reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2]
local coef_test =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")
local pval_test = string(round(r(table)[4,1], .000001), "%9.5f")

reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")
local naivecoef_test =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")

cd "`filepath'/Figures and Tables"
twoway (lfitci EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2], legend(off) title("Test Scores") ytitle("Effect per $1000 in PPE") xtitle("Change in Per Pupil Expenditure (2018$)") note("Precision-weighted slope: `coef_test'; Naive equal-weighted slope: `naivecoef_test'")) (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(circle_hollow) ) (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & (Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(none) mlabel(Article_Authors)) 
graph save Graph changePPE_scores.gph, replace


reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")  [weight=1/EstimatedEffect_overall_SE^2]
local coef_nontest =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")
local pval_nontest = round(r(table)[4,1], .000001)

reg EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")
local naivecoef_nontest =  string(round(_b[PPEchange_CPIadjust ], .000001), "%9.5f")

twoway (lfitci EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates")   [weight=1/EstimatedEffect_overall_SE^2], legend(off) title("Educational Attainment") xtitle("Change in Per Pupil Expenditure (2018$)") note("Precision-weighted slope: `coef_nontest'; Naive equal-weighted slope: `naivecoef_nontest'")) (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & EstimatedEffect_overall<2 [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(circle_hollow) )  (scatter EstimatedEffect_overall PPEchange_CPIadjust if Study_isprimary & !(Study_outcom=="Test scores" | Study_outcom=="Test proficiency rates") & EstimatedEffect_overall<2 [weight=1/EstimatedEffect_overall_SE^2],  mcolor(gray) msymbol(none) mlabel(Article_Authors)) 
graph save Graph changePPE_nontest.gph, replace

graph combine changePPE_scores.gph changePPE_nontest.gph, xsize(8) ysize(4)

graph export returnsbyspendchange.pdf, replace

**
*FUNNEL PLOTS (Figure A.21)
**
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear
keep if !missing(Article_Authors2)
keep if Study_isprimary


meta set EstimatedEffect_overall EstimatedEffect_overall_SE
meta trimfill if nonRauschOverall & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), funnel(title("") msize(2 large 4 large) legend(rows(2) pos(6)) title("Test scores") )
gr_edit .plotregion1.plot4.style.editstyle marker(size(large))
cd "`filepath'/Figures and Tables"
graph save testtrim_multper, replace
graph export TrimFillTestScore_multper.pdf, replace

meta trimfill if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), funnel(title("") msize(2 large 4 large) ytitle("") legend(rows(2) pos(6)) title("Educational Attainment"))
gr_edit .plotregion1.plot4.style.editstyle marker(size(large))
cd "`filepath'/Figures and Tables"
graph save nontesttrim_multper, replace
graph export TrimFillNonTestScore_multper.pdf, replace

graph combine testtrim_multper.gph nontesttrim_multper.gph
graph export trimcombined_multper.pdf, replace
