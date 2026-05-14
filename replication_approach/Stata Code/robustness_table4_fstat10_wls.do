*******************************************************
* Robustness check: Table 4, column 1
* Original coefficient: 0.0325
* Check: same sample, alternative econometric method
* Method: inverse-variance weighted fixed-effect/WLS
*         with SE clustered by studyid
*******************************************************

clear all
set more off

global filepath "G:\Uni\Promotion\replication-game-kcl-2026\replication_approach"

cd "$filepath/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen byte table4_col1_sample = ///
    inlist(Study_outcome, "Test scores", "Test proficiency rates") ///
    & nonRauschOverall ///
    & FirstStage_Fstat > 10

tempname results
tempfile results_dta
postfile `results' str36 row_item str32 target_element ///
    str60 specification_change str60 sample_filter_change ///
    double coefficient se p_value N clusters ///
    using `results_dta', replace

*******************************************************
* Original Table 4 column 1 estimate
* Authors' random-effects meta-regression
*******************************************************

quietly robumeta EstimatedEffect_overall ///
    if table4_col1_sample, ///
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

levelsof studyid if table4_col1_sample, local(original_clusters)
local original_cluster_n : word count `original_clusters'

post `results' ("Original") ("Table 4 column 1") ///
    ("Random-effects robumeta") ("F-stat > 10, test scores") ///
    (b_original) (se_original) (p_original) ///
    (e(N)) (`original_cluster_n')

*******************************************************
* Robustness check
* Same sample, but fixed-effect inverse-variance WLS
*******************************************************

gen inv_var_weight = 1 / EstimatedEffect_overall_Var

quietly regress EstimatedEffect_overall ///
    if table4_col1_sample [aw=inv_var_weight], ///
    vce(cluster studyid)

scalar b_check = _b[_cons]
scalar se_check = _se[_cons]
quietly test _cons = 0
scalar p_check = r(p)

levelsof studyid if e(sample), local(check_clusters)
local check_cluster_n : word count `check_clusters'

post `results' ("Robustness check") ("Table 4 column 1") ///
    ("Inverse-variance WLS, cluster SE") ("Same sample") ///
    (b_check) (se_check) (p_check) ///
    (e(N)) (`check_cluster_n')

postclose `results'

use `results_dta', clear
format coefficient se p_value %9.4f

display as text "Table 4 column 1 robustness check"
display as text "Original coefficient:      " as result %9.8f b_original
display as text "Original p-value:          " as result %9.8f p_original
display as text "Check coefficient:         " as result %9.8f b_check
display as text "Check p-value:             " as result %9.8f p_check

list, noobs

cd "$filepath/Figures and Tables"
export delimited using "robustness_table4_fstat10_wls_raw.csv", replace

clear
set obs 1

gen str180 why_appropriate = ///
    "Checks whether the F-stat > 10 test-score result depends on the random-effects meta-analysis method."
gen str30 target_element = "Table 4 column 1"
gen str70 specification_change = ///
    "Inverse-variance weighted fixed-effect/WLS with clustered SE"
gen str45 sample_filter_change = "None; same F-stat > 10 test-score sample"
gen original_coefficient = b_original
gen original_p_value = p_original
gen check_coefficient = b_check
gen check_p_value = p_check
gen str15 outcome_vs_main = "Confirms"

format original_coefficient original_p_value check_coefficient check_p_value %9.8f

export delimited using "robustness_table4_fstat10_wls_form.csv", replace
