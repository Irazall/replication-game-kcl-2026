local filepath ""
clear frames

/*
********************************************************************************
DATA SET UP
********************************************************************************
*/
forvalues i = 1/10{
	if `i' == 1{
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		local corr_multobs_onepop = 0.5
		local corr_multobs_onepopRaush = 0 
		local corr_multobs_multpop = 0
		local corr_SEunderest = 0
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		local filename "SchoolSpendingPapers_overall"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 2{
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		//A: w/in low (.25), across low (0)
		local corr_multobs_onepop = .25
		local corr_multobs_multpop = 0
		replace EstimatedEffect1_SE = EstimatedEffect1_SEwinpoplow if !missing(EstimatedEffect1_SEwinpoplow)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEwinpoplow if !missing(EstimatedEffect2_SEwinpoplow)
		replace EstimatedEffect1_SE = EstimatedEffect1_SEacrosspoplow if !missing(EstimatedEffect1_SEacrosspoplow)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEacrosspoplow if !missing(EstimatedEffect2_SEacrosspoplow)
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_sensA"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 3{
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		//B: w/in low (.25), across high (.5)
		local corr_multobs_onepop = .25
		local corr_multobs_multpop = .5
		replace EstimatedEffect1_SE = EstimatedEffect1_SEwinpoplow if !missing(EstimatedEffect1_SEwinpoplow)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEwinpoplow if !missing(EstimatedEffect2_SEwinpoplow)
		replace EstimatedEffect1_SE = EstimatedEffect1_SEacrosspophigh if !missing(EstimatedEffect1_SEacrosspophigh)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEacrosspophigh if !missing(EstimatedEffect2_SEacrosspophigh)
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_sensB"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 4{
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		//C: w/in high (.75), across low (0)
		local corr_multobs_onepop = .75
		local corr_multobs_multpop = 0
		replace EstimatedEffect1_SE = EstimatedEffect1_SEwinpophigh if !missing(EstimatedEffect1_SEwinpophigh)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEwinpophigh if !missing(EstimatedEffect2_SEwinpophigh)
		replace EstimatedEffect1_SE = EstimatedEffect1_SEacrosspoplow if !missing(EstimatedEffect1_SEacrosspoplow)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEacrosspoplow if !missing(EstimatedEffect2_SEacrosspoplow)
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_sensC"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 5{
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		//D: w/in high (.75), across high (.5)
		local corr_multobs_onepop = .75
		local corr_multobs_multpop = .5
		replace EstimatedEffect1_SE = EstimatedEffect1_SEwinpophigh if !missing(EstimatedEffect1_SEwinpophigh)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEwinpophigh if !missing(EstimatedEffect2_SEwinpophigh)
		replace EstimatedEffect1_SE = EstimatedEffect1_SEacrosspophigh if !missing(EstimatedEffect1_SEacrosspophigh)
		replace EstimatedEffect2_SE = EstimatedEffect2_SEacrosspophigh if !missing(EstimatedEffect2_SEacrosspophigh)
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_sensD"
		include "`filepath'/Stata Code/DatasetCreator"
	}	
	else if `i' == 6{
		//capLOW: low estimates of years depreciated (capital projects)
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		local corr_multobs_onepop = 0.5
		local corr_multobs_multpop = 0
		replace PPEchange = PPEchange_senslow if PPE_dollarstype == "capital"
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_capLOW"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 7{
		//capHIGH: high estimates of years depreciated (capital projects)
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		local corr_multobs_onepop = 0.5
		local corr_multobs_multpop = 0
		replace PPEchange = PPEchange_senshigh if PPE_dollarstype == "capital"
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_capHIGH"
		include "`filepath'/Stata Code/DatasetCreator"		
	}
	else if `i' == 8{
		//capNODEP: assume flat value of capital over time (no depreciation)
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		local corr_multobs_onepop = 0.5
		local corr_multobs_multpop = 0
		replace PPEchange = PPEchange_nodep if PPE_dollarstype == "capital"
		local corr_SEunderest = 0
		local filename "SchoolSpendingPapers_capNODEP"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 9{
		//assume cov = -1 for underestimated SEs
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		local corr_multobs_onepop = 0.5
		local corr_multobs_multpop = 0
		local corr_SEunderest = -1
		local filename "SchoolSpendingPapers_CovNeg1"
		include "`filepath'/Stata Code/DatasetCreator"
	}
	else if `i' == 10{
		//assume cov = 1 for underestimated SEs
		clear frames
		import excel "`filepath'/Input Data/SchoolSpendingPapers.xlsx", sheet("OverallPopulation") firstrow clear
		replace PPEchange = PPEchange_bytype if PPE_dollarstype == "capital"
		local corr_multobs_onepop = 0.5
		local corr_multobs_multpop = 0
		local corr_SEunderest = 1
		local filename "SchoolSpendingPapers_CovPos1"
		include "`filepath'/Stata Code/DatasetCreator"
	}
}

order Study_isprimary Article_Authors EstimatedEffect*_stand

/*
********************************************************************************
//generate .dta files for normality assumption tests
********************************************************************************
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

preserve
keep if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen new_mean = EstimatedEffect_overall
gen sd = EstimatedEffect_overall_SE
gen z_score = new_mean/sd
gen effect_est = EstimatedEffect_overall
gen effect_se = EstimatedEffect_overall_SE
keep new_mean sd z_score effect_est effect_se Study_isprimary EstimatedEffect_overall EstimatedEffect_overall_SE
saveold "scores_data", replace version(12)

restore

preserve
keep if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
gen new_mean = EstimatedEffect_overall
gen sd = EstimatedEffect_overall_SE
gen z_score = new_mean/sd
gen effect_est = EstimatedEffect_overall
gen effect_se = EstimatedEffect_overall_SE
keep new_mean sd z_score effect_est effect_se Study_isprimary EstimatedEffect_overall EstimatedEffect_overall_SE
saveold "edattain_data", replace  version(12)
restore


/*
********************************************************************************
//generate csv files for kasy site
********************************************************************************
*/
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

preserve
keep if Study_isprimary & (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep EstimatedEffect_overall EstimatedEffect_overall_SE
order EstimatedEffect_overall EstimatedEffect_overall_SE
keep if !missing(EstimatedEffect_overall)
export delimited using "TestScoresforKasyONEPER.csv", replace novarnames
restore

preserve
keep if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep EstimatedEffect_overall EstimatedEffect_overall_SE
order EstimatedEffect_overall EstimatedEffect_overall_SE
keep if !missing(EstimatedEffect_overall)
export delimited using "TestScoresforKasyMULTPER.csv", replace novarnames
restore

preserve
keep if Study_isprimary & !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep EstimatedEffect_overall EstimatedEffect_overall_SE
order EstimatedEffect_overall EstimatedEffect_overall_SE
keep if !missing(EstimatedEffect_overall)
export delimited using "NonTestScoresforKasyONEPER.csv", replace novarnames
restore

preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep EstimatedEffect_overall EstimatedEffect_overall_SE
order EstimatedEffect_overall EstimatedEffect_overall_SE
keep if !missing(EstimatedEffect_overall)
export delimited using "NonTestScoresforKasyMULTPER.csv", replace novarnames
restore
