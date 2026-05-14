
local filepath ""
clear frames

/*
********************************************************************************
Combine multiple estimates per paper into one estimate per paper
********************************************************************************
*/
//read in data
cd "`filepath'/Input Data"
import excel "CapitalProjectsYrXYr.xlsx", sheet("Over Time") firstrow clear
local corr_multobs_onepop = 0.5
local corr_multobs_multpop = 0
local dep_ratebuild = .07
local dep_ratenonbuild = .07
local years_build = 50
local year_nonbuild = 15

/*
**FOR SENSITIVITY
*/
//replace years_build = XX
//replace years_nonbuild = XX
//local corr_multobs_onepop = 0.75 //.25 to .75
//local corr_multobs_multpop = 0.5
local dep_ratebuild = .047
local dep_ratenonbuild = .165

gen years_dep = (share_building*`years_build') + (1-share_building)*`year_nonbuild'

gen dep_rate = (share_building*`dep_ratebuild') + (1-share_building)*`dep_ratenonbuild'

/*
Adjust dollars to 2018 using CPI (downloaded from Federal Reserve)
*/
sort PPE_dollarsyear
merge m:1 PPE_dollarsyear using "`filepath'/Input Data/CPIData"

*benchmark year 2018
count
forvalues i = 1/`r(N)'{
	if PPE_dollarsyear[`i'] == 2018{
		local CPIadjust = CPIAUCNS[`i']
	}
}
di "`CPIadjust'"

gen PPE_reported_CPIadjust = (PPE_reported*CPIAUCNS)/`CPIadjust'
replace PPE_reported_CPIadjust = PPE_reported if missing(PPE_reported_CPIadjust)
keep if (_merge == 3 | _merge == 1)
drop _merge
drop CPIAUCNS

sort paper time

//generate variables
encode paper, gen(paperid)

//if multobs_single_pop == 1, calculate a combined estimate assuming 0.5 correlation
frame copy default multobs_single_pop
frame change multobs_single_pop
keep if multobs_single_pop
gen comb_est = (effect1_est + effect2_est)/2
gen comb_se = sqrt((0.25)*((effect1_se)^2 + (effect2_se)^2 + 2*(`corr_multobs_onepop')*(effect1_se)*(effect2_se)))
frame put paper time comb_est comb_se multobs_single_pop paperid PPE_reported years_dep max_year mathread effect1_est effect1_se effect2_est effect2_se PPE_reported_CPIadjust dep_rate, into(combined_est)

//if multobs_mult_pop == 0, simply take precision-weighted average
frame copy default multobs_mult_pop
frame change multobs_mult_pop
keep if multobs_single_pop == 0 & !missing(effect2_est)
gen comb_est = ((effect1_est/(effect1_se^2)) + (effect2_est/(effect2_se^2)))/((1/effect1_se^2)+(1/effect2_se^2))
gen weight1 = (1/effect1_se^2)/((1/effect1_se^2)+(1/effect2_se^2))
gen weight2 = (1/effect2_se^2)/((1/effect1_se^2)+(1/effect2_se^2))
gen comb_se = sqrt((weight1^2)*(effect1_se^2) + (weight2^2)*(effect2_se^2) + 2*`corr_multobs_multpop'*weight1*effect1_se*weight2*effect2_se)

replace comb_est = 0 if missing(comb_est)
replace comb_se = 0 if missing(comb_se)
tempfile temp1
save "`temp1'"

//if multobs_mult_pop == 0 and there is only one estimate (Baron 2020)
frame copy default sing_est
frame change sing_est
keep if multobs_single_pop == 0 & missing(effect2_est)
gen comb_est = effect1_est
gen comb_se = effect1_se
tempfile temp2
save "`temp2'"

frame change combined_est
append using "`temp1'"
append using "`temp2'"
keep paper paperid time comb_est comb_se multobs_single_pop PPE_reported years_dep max_year mathread effect1_est effect1_se effect2_est effect2_se PPE_reported_CPIadjust dep_rate

//create variable that is relative to zero estimate at t = 0
tab paperid
local numpapers = r(r)
sum time
local mintime = r(min) + 1
local maxtime = r(max)
gen comb_est_rel0 = 0 if time == 0
gen time0comp = 0

forvalues i = 1/`numpapers'{
	preserve
	keep if paperid == `i'
	local time0comp = comb_est[1]
	restore
	di "TIME0COMP: `time0comp'"
	forvalues t = `mintime'/`maxtime'{
	
		replace comb_est_rel0 = comb_est - `time0comp' if time == `t' & paperid == `i'
	}
	//local time0comp
	di "TIME0COMP: `time0comp'"
}
order comb_est comb_est_rel0

//generate depreciated $ amount, now different for each capital spending type
gen xYr0 = PPE_reported_CPIadjust/((1-(1/(1+dep_rate)^(years_dep+1)))/(1-(1/(1+dep_rate))))
forvalues i = 1/7{
	gen xYr`i' = xYr0/(1+dep_rate)^`i'
}
	
gen avgPPEtoYr0 = xYr0
gen avgPPEtoYr1 = xYr1
gen avgPPEtoYr2 = (xYr1 + xYr2)/2
gen avgPPEtoYr3 = (xYr1 + xYr2 + xYr3)/3
gen avgPPEtoYr4 = (xYr1 + xYr2 + xYr3 + xYr4)/4
gen avgPPEtoYr5 = (xYr1 + xYr2 + xYr3 + xYr4 + xYr5)/5
gen avgPPEtoYr6 = (xYr1 + xYr2 + xYr3 + xYr4 + xYr5 + xYr6)/6
gen avgPPEtoYr7 = (xYr1 + xYr2 + xYr3 + xYr4 + xYr5 + xYr6 + xYr7)/7

gen avgPPEnoDEP = PPE_reported_CPIadjust/years_dep

set trace on
gen avgPPEtoYrMax = 0
gen comb_est_rel0Max = 0
gen comb_seMax = 0
unique paper
forvalues i = 1/`r(unique)'{
	replace max_year = 6 if max_year > 6
	sum max_year if paperid == `i'
	local max_yr = r(mean)
	replace avgPPEtoYrMax = avgPPEtoYr`max_yr' if paperid == `i'
	
	sum comb_est_rel0 if paperid == `i' & time == `max_yr'
	replace comb_est_rel0Max = r(mean) if paperid == `i'
	sum comb_se if paperid == `i' & time == `max_yr'
	replace comb_seMax = r(mean) if paperid == `i'
}

//save dataset with one combined estiamte per paper
cd "`filepath'/Created Datasets"
keep if !regexm(lower(paper), "burge")
save capitalproj_combined, replace

order avgPPEnoDEP paper avgPPEtoYrMax comb_est_rel0 comb_se time max_year
sort paper
br if time == max_year

gen tstat_combest = abs(comb_est_rel0/comb_se)
sort time tstat_combest
br paper tstat_combest time comb_se
