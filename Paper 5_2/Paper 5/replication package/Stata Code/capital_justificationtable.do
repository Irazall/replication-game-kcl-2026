local filepath "" //Table A.4

cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

preserve
local filename "CapitalDepJustification"
keep if Study_isprimary
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"
keep if !regexm(EstimtedEffect1_source, "made up")
keep if PPE_dollarstype == "capital"


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

file write `table' "\begin{longtable}{p{5cm}|p{4cm}|p{8cm}}" _n
file write `table' "\caption{Summary of capital depreciation decision} \\" _n
file write `table' "\label{tab:capdep_justification}" _n
file write `table' "Study & Depreciate over (years) & Life of project description \\" _n
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
			local prose_reason = prosecapital_ambiguous[`i']
			local prose_yearsdep = prosecapital_currentdep[`i']
		}
		else{
			//do nothing
		}
	}
	file write `table' "`authors' & `prose_yearsdep' & `prose_reason' \\" _n
	file write `table' "\hline" _n
}

file write `table' "\end{longtable}" _n
file write `table' "\end{ThreePartTable}" _n
file close `table'

restore
