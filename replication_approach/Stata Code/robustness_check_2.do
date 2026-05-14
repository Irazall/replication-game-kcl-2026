*******************************************************
* Extra robustness check 2:
* Drop spending-change outliers, then rerun pooled means
*******************************************************

global filepath "G:\Uni\Promotion\replication-game-kcl-2026\replication_approach"

cd "$filepath/Created Datasets"
use SchoolSpendingPapers_overall, clear

gen byte testout = inlist(Study_outcome, "Test scores", "Test proficiency rates")

eststo clear

* Test scores: drop bottom/top 5% of spending changes
summ PPEchange_CPIadjust if testout & nonRauschOverall, detail
local test_p5  = r(p5)
local test_p95 = r(p95)

eststo trim_test: robumeta EstimatedEffect_overall ///
    if testout & nonRauschOverall ///
    & inrange(PPEchange_CPIadjust, `test_p5', `test_p95'), ///
    variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))

* Educational attainment: drop bottom/top 5% of spending changes
summ PPEchange_CPIadjust if !testout, detail
local attain_p5  = r(p5)
local attain_p95 = r(p95)

eststo trim_attain: robumeta EstimatedEffect_overall ///
    if !testout ///
    & inrange(PPEchange_CPIadjust, `attain_p5', `attain_p95'), ///
    variance(EstimatedEffect_overall_Var) study(studyid)
estadd scalar tau = sqrt(e(tau2))

cd "$filepath/Figures and Tables"
esttab trim_test trim_attain using spend_trimmed_regs.tex, replace se ///
    title("Robustness: Dropping Spending-Change Outliers") ///
    varlabels(_cons "Average Effect") ///
    stats(N tau, labels("Observations" "\tau")) ///
    mtitles("Test Scores" "Educational Attainment") ///
    nonotes addnotes("Drops observations outside the 5th-95th percentile of PPEchange_CPIadjust within outcome family." ///
    "Standard errors are adjusted for clustering of related papers.")
