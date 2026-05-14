
drop if regexm(Study_outcome, "Poverty")
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"`'
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"
keep if Article_Authors != "Biasi"
keep if Article_Authors != "Card Payne"
keep if Article_Authors != "Deke"
keep if Article_Authors != "Schlaffer Burge"

/*
Reverse sign for estimates that were decrease spending per decrease in outcome
*/
forvalues i = 1/2{
	replace EstimatedEffect`i' = abs(EstimatedEffect`i') if EstimatedEffect_reversesign
	replace PPEchange = abs(PPEchange) if EstimatedEffect_reversesign
}

gen EstimatedEffect1_SE_unadjust = EstimatedEffect1_SE
gen EstimatedEffect2_SE_unadjust = EstimatedEffect2_SE

replace PPEchange_se = PPEchange/5.05233703 if Article_Authors == "Rauscher a" //to adjust given estiamte of bond amount
/*
Adjust if SE underreported (e.g., only reported reduced form IV results)
R, S are estimates, standard deviation of R/S using method here:
https://www.stat.cmu.edu/~hseltman/files/ratio.pdf
*/
local N = _N
forvalues j = 1/`N' {
	forvalues i = 1/2{
		if EstimatedEffect_SE_underreported[`j'] == 0 {
			//not underestimated, do nothing
		}
		else {
			di Article_Authors[`j']
			di "unadjust t-stat = " EstimatedEffect`i'[`j']/EstimatedEffect`i'_SE[`j']
			local R_mu = abs(EstimatedEffect`i'[`j'])
			local R_sd = EstimatedEffect`i'_SE[`j']
			local S_mu = abs(PPEchange[`j'])
			local S_sd = PPEchange_se[`j']
		
			di "R_mu = "`R_mu'
			di "R_sd = "`R_sd'
			di "S_mu = "`S_mu'
			di "S_sd = "`S_sd'
		
			local adjust_SE = `S_mu'*sqrt(((`R_mu'^2)/(`S_mu'^2))*((`R_sd'^2/`R_mu'^2)-(2*(`corr_SEunderest'*`S_sd'*`R_sd')/(`R_mu'*`S_mu'))+(`S_sd'^2/`S_mu'^2)))
		
			replace EstimatedEffect`i'_SE = `adjust_SE' if _n == `j'
			di "adjust_SE = "`adjust_SE'
			
			di "adjust t-stat = " (EstimatedEffect`i'[`j'])/EstimatedEffect`i'_SE[`j']/`S_mu'
		}
	
	}
}

/*
Adjust effect estimates to standard deviation units
*/
gen EstimatedEffect1_stand = .
gen EstimatedEffect1_stand_SE = .
gen EstEffect1unadjust_stand_SE = .
gen EstimatedEffect2_stand = .
gen EstimatedEffect2_stand_SE = .
gen EstEffect2unadjust_stand_SE = .

forvalues i = 1/2{
	replace EstimatedEffect`i'_stand = EstimatedEffect`i' if EstimatedEffect_unitsstand
	replace EstimatedEffect`i'_stand_SE = EstimatedEffect`i'_SE if EstimatedEffect_unitsstand
	replace EstEffect`i'unadjust_stand_SE = EstimatedEffect`i'_SE_unadjust if EstimatedEffect_unitsstand
	
	replace EstimatedEffect`i'_stand = EstimatedEffect`i'/Outcome_baseline_SE if EstimatedEffect_unitsstand == 0
	replace EstimatedEffect`i'_stand_SE = EstimatedEffect`i'_SE/Outcome_baseline_SE if EstimatedEffect_unitsstand == 0
	replace EstEffect`i'unadjust_stand_SE = EstimatedEffect`i'_SE_unadjust/Outcome_baseline_SE if EstimatedEffect_unitsstand == 0
}


/*
Adjust dollars to 2018 using CPI (downloaded from Federal Reserve)
*/
//change in spend
*benchmark year 2018
sort PPE_dollarsyear
merge m:1 PPE_dollarsyear using "`filepath'/Input Data/CPIData"

count
forvalues i = 1/`r(N)'{
	if PPE_dollarsyear[`i'] == 2018{
		local CPIadjust = CPIAUCNS[`i']
	}
}
di "`CPIadjust'"

gen PPEchange_CPIadjust = (PPEchange*`CPIadjust')/CPIAUCNS
replace PPEchange_CPIadjust = PPEchange if missing(PPEchange_CPIadjust)
gen PPE_policychange_CPIadjust = (PPE_policychange*`CPIadjust')/CPIAUCNS
replace PPE_policychange_CPIadjust = PPEchange_CPIadjust if missing(PPE_policychange_CPIadjust)
keep if (_merge == 3 | _merge == 1)
drop _merge
drop CPIAUCNS

//baseline spend
sort PPE_baselinedollarsyear
merge m:1 PPE_baselinedollarsyear using "`filepath'/Input Data/CPIData"
count
forvalues i = 1/`r(N)'{
	if PPE_baselinedollarsyear[`i'] == 2018{
		local CPIadjust = CPIAUCNS[`i']
	}
}
di "`CPIadjust'"
gen PPEbaseline_CPIadjust = (PPE_baseline*`CPIadjust')/CPIAUCNS
replace PPEbaseline_CPIadjust = PPE_baseline if missing(PPEbaseline_CPIadjust)
keep if (_merge == 3 | _merge == 1)
drop _merge
drop CPIAUCNS
label var PPEbaseline_CPIadjust "Baseline Per Pupil Expenditure (2018$)"


/*
Calculate effect (and SE) per $1000
*/
forvalues i = 1/2{
	gen Effect`i'per1k = (EstimatedEffect`i'_stand*1000)/PPEchange_CPIadjust
	label var Effect`i'per1k "Effect per \\$1k"
	gen Effect`i'per1k_SE = (EstimatedEffect`i'_stand_SE*1000/PPEchange_CPIadjust)
	label var Effect`i'per1k_SE "SE per \\$1k"
	
	gen Effect`i'unadjustper1k_SE = (EstEffect`i'unadjust_stand_SE*1000/PPEchange_CPIadjust)

}


/*
Generate paper id (one per paper) and study id (multiple per paper)
*/
sort Article_Authors
tostring Article_Year, gen(year_str)
gen tempforid = Article_Authors + year_str
encode tempforid, gen(paperid)
drop tempforid

tostring EstimatedEffect_lowinc, gen(lowinc_str)
gen tempforid = Article_Title + lowinc_str
encode tempforid, gen(LInonLIid)

drop tempforid lowinc_str

gen tempforid = Article_Authors
encode tempforid, gen(studyid)
drop tempforid

/*
Compute one effect per study if study does not have overall reported effect
*/
//If multobs_single_pop, calculate a combined estimate assuming rho = 0.5
frame copy default multobs_single_pop
frame copy default data_for_analysis
frame copy default papers_for_table

frame change data_for_analysis
keep if Study_hasoverallest == 1

frame change multobs_single_pop
keep if Study_multobs_single_pop == 1 //we're left with only papers that have Effects 1 & 2 for single population
gen comb_est = (Effect1per1k + Effect2per1k)/2

gen RAWcomb_est = (EstimatedEffect1_stand + EstimatedEffect2_stand)/2

gen comb_seunadjust = sqrt((0.25)*((Effect1unadjustper1k_SE)^2 + (Effect2unadjustper1k_SE)^2 + 2*(0.5)*(Effect1unadjustper1k_SE)*(Effect2unadjustper1k_SE)))
gen comb_se = sqrt((0.25)*((Effect1per1k_SE)^2 + (Effect2per1k_SE)^2 + 2*(`corr_multobs_onepop')*(Effect1per1k_SE)*(Effect2per1k_SE)))
replace comb_se = sqrt(((Effect1per1k_SE)^2 + (Effect2per1k_SE)^2 + 2*(`corr_multobs_multpop')*(Effect1per1k_SE)*(Effect2per1k_SE))) if Study_isprimary & Article_Authors == "Lafortune Rothstein Schanzenbach"
replace comb_se = sqrt(((Effect1per1k_SE)^2 + (Effect2per1k_SE)^2 + 2*(`corr_multobs_multpop')*(Effect1per1k_SE)*(Effect2per1k_SE))) if Study_isprimary & Article_Authors == "Rauscher b"

gen RAWcomb_se = sqrt((0.25)*((EstimatedEffect1_stand_SE)^2 + (EstimatedEffect2_stand_SE)^2 + 2*(`corr_multobs_onepop')*(EstimatedEffect1_stand_SE)*(EstimatedEffect2_stand_SE)))
frame put *, into(combined_est)
tempfile temp2
save "`temp2'"

//if multobs_mult_pop == 0, simply take precision-weighted average
frame copy default multobs_mult_pop
frame change multobs_mult_pop
keep if Study_multobs_single_pop == 0 & Study_hasoverallest == 0 // we're left with only papers that have Effects 1 & 2 for separate populations
gen comb_est = ((Effect1per1k/(Effect1per1k_SE^2)) + (Effect2per1k/(Effect2per1k_SE^2)))/((1/Effect1per1k_SE^2)+(1/Effect2per1k_SE^2))

gen RAWcomb_est = ((EstimatedEffect1_stand/(EstimatedEffect1_stand_SE^2)) + (EstimatedEffect2_stand/(EstimatedEffect2_stand_SE^2)))/((1/EstimatedEffect1_stand_SE^2)+(1/EstimatedEffect2_stand_SE^2))

gen comb_seunadjust = 1/sqrt(1/Effect1unadjustper1k_SE^2 + 1/Effect2unadjustper1k_SE^2)
gen weight1 = (1/Effect1per1k_SE^2)/((1/Effect1per1k_SE^2)+(1/Effect2per1k_SE^2))
gen weight2 = (1/Effect2per1k_SE^2)/((1/Effect1per1k_SE^2)+(1/Effect2per1k_SE^2))
gen comb_se = sqrt((weight1^2)*(Effect1per1k_SE^2) + (weight2^2)*(Effect2per1k_SE^2) + 2*`corr_multobs_multpop'*weight1*Effect1per1k_SE*weight2*Effect2per1k_SE)

gen RAWweight1 = (1/EstimatedEffect1_stand_SE^2)/((1/EstimatedEffect1_stand_SE^2)+(1/EstimatedEffect2_stand_SE^2))
gen RAWweight2 = (1/EstimatedEffect2_stand_SE^2)/((1/EstimatedEffect1_stand_SE^2)+(1/EstimatedEffect2_stand_SE^2))
gen RAWcomb_se = sqrt((RAWweight1^2)*(EstimatedEffect1_stand_SE^2) + (RAWweight2^2)*(EstimatedEffect2_stand_SE^2) + 2*`corr_multobs_multpop'*RAWweight1*EstimatedEffect1_stand_SE*RAWweight2*EstimatedEffect2_stand_SE)

tempfile temp1
save "`temp1'"

frame change data_for_analysis
append using "`temp1'"
append using "`temp2'"


gen EstimatedEffect_overall = Effect1per1k if Study_hasoverallest & Study_multobs_single_pop == 0
gen EstimatedEffect_overall_SE = Effect1per1k_SE if Study_hasoverallest & Study_multobs_single_pop == 0
gen EstEffectunadjust_SE = Effect1unadjustper1k_SE if Study_hasoverallest & Study_multobs_single_pop == 0 & EstimatedEffect_SE_underreported
replace EstEffectunadjust_SE = Effect1per1k_SE if Study_hasoverallest & Study_multobs_single_pop == 0 & EstimatedEffect_SE_underreported == 0

gen RAWEstimatedEffect_overall = EstimatedEffect1_stand if Study_hasoverallest & Study_multobs_single_pop == 0
gen RAWEstimatedEffect_overall_SE = EstimatedEffect1_stand_SE if Study_hasoverallest & Study_multobs_single_pop == 0

gen capital = 1 if PPE_dollarstype == "capital"
replace capital = 0 if capital != 1
label var capital "Capital"

gen attainment = !(Study_outcome == "test scores" | Study_outcome == "test proficiency rates")
label var attainment "Ed. Attainment"

replace EstimatedEffect_overall = comb_est if missing(EstimatedEffect_overall)
replace EstimatedEffect_overall_SE = comb_se if missing(EstimatedEffect_overall_SE)
replace EstEffectunadjust_SE = comb_seunadjust if missing(EstEffectunadjust_SE)

replace RAWEstimatedEffect_overall = RAWcomb_est if missing(RAWEstimatedEffect_overall)
replace RAWEstimatedEffect_overall_SE = RAWcomb_se if missing(RAWEstimatedEffect_overall_SE)



sort Article_Authors
order FirstStage_Fstat Article_Authors Study_isprimary EstimatedEffect_lowinc EstimatedEffect1 EstimatedEffect1_SE EstimatedEffect2 EstimatedEffect2_SE comb_est comb_se EstimatedEffect_overall EstimatedEffect_overall_SE PPEchange_CPIadjust

label var EstimatedEffect_lowinc "Low-Income"
label var capital "Capital"
label var Study_ismultistate "Multi-State"

replace EstimatedEffect_overall = . if regexm(Study_outcome, "poverty") | regexm(Study_outcome, "inequality") | regexm(Study_outcome, "mobility")

replace EstimatedEffect_overall_SE = . if regexm(Study_outcome, "poverty") | regexm(Study_outcome, "inequality") | regexm(Study_outcome, "mobility")

//adjust long-term estimates to be 4-year
replace EstimatedEffect_overall = (EstimatedEffect_overall/Years_Expose)*4
replace EstimatedEffect_overall_SE = (EstimatedEffect_overall_SE/Years_Expose)*4
replace RAWEstimatedEffect_overall = (RAWEstimatedEffect_overall/Years_Expose)*4
replace RAWEstimatedEffect_overall_SE = (RAWEstimatedEffect_overall_SE/Years_Expose)*4

gen EstimatedEffect_overall_Var=EstimatedEffect_overall_SE^2

gen PublicationInd = 1 if regexm(Article_Journal, "Quarterly") | regexm(Article_Journal, "QJE")
replace PublicationInd = 2 if regexm(Article_Journal, "AEJ") | regexm(Article_Journal, "American Economic Journal") | regexm(Article_Journal, "Education") | regexm(Article_Journal, "Sage") | regexm(Article_Journal, "Publica Finance") | regexm(Article_Journal, "Journal of Public") | regexm(Article_Journal, "Review of Economics and Statistics") | regexm(Article_Journal, "Public Finance Review") | regexm(Article_Journal, "Econometrics") | regexm(Article_Journal, "Urban Econ") | regexm(Article_Journal, "AERA")
replace PublicationInd = 3 if missing(PublicationInd)
order PublicationInd Article_Journal Article_Authors  Study_outcome
br PublicationInd Article_Journal Article_Authors  Study_outcome EstimatedEffect_overall
label define PublicationInd 1 "Flagship" 2 "Field Journal" 3 "Unpublished"
label values PublicationInd PublicationInd

gen high_impact=0
replace high_impact=1 if Article_Journal=="AEJ: Applied"
replace high_impact=1 if Article_Journal=="AEJ: Economic Policy"
replace high_impact=1 if Article_Journal=="AEJ: Policy"
replace high_impact=1 if Article_Journal=="Review of Economics and Statistics"
replace high_impact=1 if Article_Journal=="AEJ: Economic Policy"
replace high_impact=1 if Article_Journal=="QJE"
replace high_impact=1 if Article_Journal=="The Quarterly Journal of Economics"
replace high_impact=1 if Article_Journal=="AEJ: Economic Policy"
replace high_impact=1 if Article_Journal=="QJE, AEJ"
replace high_impact=1 if Article_Journal=="AEJ: Applied"
replace high_impact=1 if Article_Journal=="American Economic Journal: Applied Economics"
replace high_impact=1 if Article_Journal=="Sociology of Education"

gen top_feild=0
replace top_feild=1 if Article_Journal=="Journal of Public Economics"
replace top_feild=1 if Article_Journal=="Journal of Econometrics"


gen feild=0
replace feild=1 if  Article_Journal=="Education Finance and Policy"
replace feild=1 if  Article_Journal=="Educational Evaluation and Policy Analysis"
replace feild=1 if  Article_Journal=="Economics of Education Review"
replace feild=1 if  Article_Journal=="Russel Sage Foundation Journal of the Social Sciences"
replace feild=1 if  Article_Journal=="Journal of Public Administration Research And Theory"
replace feild=1 if  Article_Journal=="Education Economics"
replace feild=1 if  Article_Journal=="Public Finance Review"
replace feild=1 if  Article_Journal=="Journal of Urban Economics"
replace feild=1 if Article_Journal=="AERA Open"

gen unpublished=1- high_impact - top_feild - feild

tostring Article_Year, replace
gen studyLab = Article_Authors2	+ "(" + Article_Year + ")"

//to handle Rauscher (2020b) 
replace EstimatedEffect_overall_SE = abs(EstimatedEffect_overall_SE)

gen studyid2 = studyid
replace studyid = 98 if Program_studied  == "OH capital subsidy program"
replace studyid = 99 if Program_studied == "MI Proposal A"
replace studyid = 100 if Article_Authors == "Lafortune Rothstein Schanzenbach" | Article_Authors == "Brunner Hyman Ju"
replace studyid = 101 if regexm(Article_Authors, "Cascio") | Article_Authors == "Johnson"
replace studyid = 102 if Article_Authors == "Schlaffer Burge" | Article_Authors == "Martorell Stange McFarlin"

*for cases when Rauscher b should only have rural and nonrural and Rauscher a should only have LI and non-LI
gen nonRauschOverall = 1
replace nonRauschOverall = 0 if Article_Authors == "Rauscher b" & Study_isprimary
replace nonRauschOverall = 0 if Article_Authors == "Rauscher a" & Study_isprimary

//Note: THIS DATASET INCLUDES ONE OVERALL ESTIMATE PER PAPER
cd "`filepath'/Created Datasets"
save `filename', replace
