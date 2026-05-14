local filepath "" //Table A.1

cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

preserve
local filename "PerPaperSteps"
keep if Study_isprimary
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"
keep if !regexm(EstimtedEffect1_source, "made up")
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

sort Article_Authors2
encode Article_Authors2, gen(studyID)

sort Article_Authors2 Study_outcome
gen tempforid = Article_Authors2 + year_str + Study_outcome + PPE_dollarstype
encode tempforid, gen(tableid)
drop tempforid

cd "`filepath'/Figures and Tables"

tempname table
file open `table' using "`filename'.tex", write replace
file write `table' "\begin{ThreePartTable}" _n
file write `table' "\scriptsize" _n
file write `table' "\begin{TableNotes}" _n
file write `table' "\item This describes the steps per \emph{overall} study-outcome (and by spending type, relevant for Baron (2020))." _n
file write `table' "\end{TableNotes}" _n
file write `table' "\begin{longtable}{p{2.5cm}|p{1.5cm}|p{1.5cm}|p{6.5cm}|p{6.5cm}}" _n

//file write `table' "\begin{longtable}{p{4cm}|p{4cm}|p{3cm}|p{4.5cm}|p{4.5cm}}" _n

file write `table' "\caption{Summary of per-study steps} \\" _n
file write `table' "\label{tab:perpapersteps}" _n
file write `table' "study & outcome & effect per \\$1000 & \\$ $\Delta$: source & outcome $\Delta$: source \\" _n
file write `table' "\hline\noalign{\smallskip}" _n
file write `table' "\hline" _n

levelsof tableid
local studylist = r(levels)
foreach study in `studylist'{
	di "`study'"
	count
	local maxN = r(N)
	forvalues i = 1/`maxN'{
		if tableid[`i'] == `study'{
			local authors = Article_Authors2[`i'] + " (" + year_str[`i'] + ")"
			local outcome = Study_outcome[`i'] 
			local effect = string(round(EstimatedEffect_overall[`i'], .001), "%9.4f")
			local SEMax = string(round(EstimatedEffect_overall_SE[`i'], .001), "%9.4f")

			//local prose_dollarschange = "\\$" + string(PPEchange_CPIadjust[`i']) + ": " + Prose_policyondollars[`i']
			local prose_dollarschange = Prose_policyondollars[`i']
			local prose_outcomechange = Prose_outcome[`i']
		}
		else{
			//do nothing
		}
	}
	file write `table' "`authors' & `outcome' & `effect' & `prose_dollarschange' & `prose_outcomechange' \\" _n
	file write `table' "\hline" _n
}

file write `table' "\insertTableNotes" _n
file write `table' "\end{longtable}" _n
file write `table' "\end{ThreePartTable}" _n
file close `table'

restore
