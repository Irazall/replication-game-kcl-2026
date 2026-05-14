*******************************************************
* Robustness check: Table 3, column 1
* Original coefficient: average test-score effect (0.0316)
* Check: leave out the Rauscher (2020) study cluster
*******************************************************

clear all
set more off

global filepath "G:\Uni\Promotion\replication-game-kcl-2026\replication_approach"

cd "$filepath/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen byte table3_col1_sample = ///
    inlist(Study_outcome, "Test scores", "Test proficiency rates") ///
    & nonRauschOverall

* Identify the Rauscher (2020) cluster in the Table 3 column 1 sample.
capture confirm variable studyLab
if _rc {
    tostring Article_Year, gen(Article_Year_str)
    gen studyLab = Article_Authors2 + "(" + Article_Year_str + ")"
}

levelsof studyid if table3_col1_sample & regexm(studyLab, "Rauscher"), ///
    local(rauscher_ids)

if "`rauscher_ids'" == "" {
    display as error "No Rauscher study cluster found in the Table 3 column 1 sample."
    exit 459
}

gen byte omit_rauscher2020 = 0
foreach id of local rauscher_ids {
    replace omit_rauscher2020 = 1 if studyid == `id'
}

tempname results
tempfile results_dta
postfile `results' str24 model double coefficient se p_value N clusters ///
    using `results_dta', replace

*******************************************************
* Original Table 3 column 1 estimate
*******************************************************

quietly robumeta EstimatedEffect_overall ///
    if table3_col1_sample, ///
    variance(EstimatedEffect_overall_Var) study(studyid)

quietly lincom _cons
scalar b_original = r(estimate)
scalar se_original = r(se)
capture scalar p_original = r(p)
if _rc {
    scalar p_original = 2 * normal(-abs(b_original / se_original))
}
else if missing(p_original) {
    scalar p_original = 2 * normal(-abs(b_original / se_original))
}

levelsof studyid if table3_col1_sample, local(original_clusters)
local original_cluster_n : word count `original_clusters'

post `results' ("Original") (b_original) (se_original) (p_original) ///
    (e(N)) (`original_cluster_n')

*******************************************************
* Robustness check: omit Rauscher (2020)
*******************************************************

quietly robumeta EstimatedEffect_overall ///
    if table3_col1_sample & omit_rauscher2020 == 0, ///
    variance(EstimatedEffect_overall_Var) study(studyid)

quietly lincom _cons
scalar b_check = r(estimate)
scalar se_check = r(se)
capture scalar p_check = r(p)
if _rc {
    scalar p_check = 2 * normal(-abs(b_check / se_check))
}
else if missing(p_check) {
    scalar p_check = 2 * normal(-abs(b_check / se_check))
}

levelsof studyid if table3_col1_sample & omit_rauscher2020 == 0, local(check_clusters)
local check_cluster_n : word count `check_clusters'

post `results' ("Drop Rauscher 2020") (b_check) (se_check) (p_check) ///
    (e(N)) (`check_cluster_n')

postclose `results'

use `results_dta', clear
format coefficient se p_value %9.4f

display as text "Table 3 column 1 robustness check"
display as text "Original coefficient:       " as result %9.8f b_original
display as text "Original p-value:           " as result %9.8f p_original
display as text "Drop Rauscher coefficient:  " as result %9.8f b_check
display as text "Drop Rauscher p-value:      " as result %9.8f p_check

list, noobs

cd "$filepath/Figures and Tables"
export delimited using "robustness_table3_rauscher.csv", replace
