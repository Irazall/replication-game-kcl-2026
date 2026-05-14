*******************************************************
* Extra robustness check 1:
* Table 3 leave-one-study-cluster-out
*******************************************************

global filepath "G:\Uni\Promotion\replication-game-kcl-2026\replication_approach"

cd "$filepath/Created Datasets"
use SchoolSpendingPapers_overall, clear

capture confirm variable EstEffLI
if _rc {
    rename EstimatedEffect_lowinc EstEffLI
    rename EstimatedEffect_nonlowinc EstEffnonLI
}

gen byte testout = inlist(Study_outcome, "Test scores", "Test proficiency rates")

tempfile loco
tempname H
postfile `H' str12 spec str16 estimand int dropped_id str80 dropped_label ///
    double b se tau N clusters using `loco', replace

local c1_sample "testout & nonRauschOverall"
local c1_x ""
local c1_label "T3_col1_test"

local c2_sample "testout & nonRauschOverall"
local c2_x "capital"
local c2_label "T3_col2_capital"

local c3_sample "testout & nonRauschOverall"
local c3_x "EstEffLI EstEffnonLI capital"
local c3_label "T3_col3_LI_cap"

local c4_sample "testout & Study_isprimary"
local c4_x ""
local c4_label "T3_col4_test_1per"

local c5_sample "!testout"
local c5_x ""
local c5_label "T3_col5_attain"

local c6_sample "!testout"
local c6_x "EstEffLI EstEffnonLI"
local c6_label "T3_col6_LI"

local c7_sample "!testout & Study_isprimary"
local c7_x ""
local c7_label "T3_col7_attain_1per"

foreach s in c1 c2 c3 c4 c5 c6 c7 {
    local sample "``s'_sample'"
    local xvars  "``s'_x'"
    local label  "``s'_label'"

    quietly levelsof studyid if `sample', local(ids)

    foreach dropid in 0 `ids' {
        local dropcond ""
        local droplab "full sample"

        if `dropid' > 0 {
            local dropcond "& studyid != `dropid'"
            quietly levelsof studyLab if studyid == `dropid', local(droplab) clean
            local droplab = substr("`droplab'", 1, 80)
        }

        quietly count if `sample' `dropcond'
        local nobs = r(N)
        quietly levelsof studyid if `sample' `dropcond', local(cidlist)
        local nclust : word count `cidlist'

        capture quietly robumeta EstimatedEffect_overall `xvars' ///
            if `sample' `dropcond', ///
            variance(EstimatedEffect_overall_Var) study(studyid)

        if !_rc {
            local tau = sqrt(e(tau2))
            post `H' ("`label'") ("Overall") (`dropid') ("`droplab'") ///
                (_b[_cons]) (_se[_cons]) (`tau') (`nobs') (`nclust')

            if strpos(" `xvars' ", " capital ") {
                quietly lincom _cons + capital
                post `H' ("`label'") ("Capital") (`dropid') ("`droplab'") ///
                    (r(estimate)) (r(se)) (`tau') (`nobs') (`nclust')
            }

            if strpos(" `xvars' ", " EstEffLI ") {
                quietly lincom EstEffLI - EstEffnonLI
                post `H' ("`label'") ("LI_minus_nonLI") (`dropid') ("`droplab'") ///
                    (r(estimate)) (r(se)) (`tau') (`nobs') (`nclust')
            }
        }
    }
}

postclose `H'
use `loco', clear

gen full_b_tmp = b if dropped_id == 0
bysort spec estimand: egen full_b = max(full_b_tmp)
gen delta = b - full_b if dropped_id != 0
gen abs_delta = abs(delta)

format b se tau full_b delta abs_delta %9.4f

save "$filepath/Created Datasets/table3_leave_one_cluster_out.dta", replace
export delimited using "$filepath/Figures and Tables/table3_leave_one_cluster_out.csv", replace

* Compact summary for reporting
preserve
keep if dropped_id != 0
bysort spec estimand: egen min_b = min(b)
bysort spec estimand: egen max_b = max(b)
bysort spec estimand: egen max_abs_delta = max(abs_delta)
egen tag = tag(spec estimand)
list spec estimand full_b min_b max_b max_abs_delta if tag, noobs
restore

* Which omitted cluster matters most?
gsort spec estimand -abs_delta
by spec estimand: list spec estimand dropped_label b delta if _n == 1, noobs
