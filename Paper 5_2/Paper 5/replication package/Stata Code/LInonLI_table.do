clear frames //Table A.2

local filepath ""
cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear

local filename "LInonLICompare"
*keep if Study_isprimary
keep if Article_Authors != "Downes, Dye, McGuire"
keep if Article_Authors != "Figlio"
keep if Article_Authors != "Hoxby"
keep if Article_Authors != "Van der Klaauw"
keep if Article_Authors != "Matsudaira Hosek Walsh"
keep if Article_Authors != "Holden"

tostring EstimatedEffect_lowinc, gen(LIind_str)
sort Article_Authors2 Study_outcome
gen tempforid = Article_Authors + year_str + Study_outcome + PPE_dollarstype
encode tempforid, gen(tableid)
drop tempforid

frame copy default nonLIests
frame nonLIests{
	keep if EstimatedEffect_nonlowinc
	keep EstimatedEffect_overall EstimatedEffect_overall_SE PPEchange_CPIadjust tableid
	rename EstimatedEffect_overall NONLOWINCEstimatedEffect_overall
	rename EstimatedEffect_overall_SE NONLOWINCEstEffect_overall_SE
	rename PPEchange_CPIadjust NONLOWINCPPEchange_CPIadjust
}
keep if EstimatedEffect_lowinc
rename EstimatedEffect_overall LOWINCEstimatedEffect_overall
rename EstimatedEffect_overall_SE LOWINCEstimatedEffect_overall_SE
rename PPEchange_CPIadjust LOWINCPPEchange_CPIadjust

frlink 1:1 tableid, frame(nonLIests)
frget *, from(nonLIests)

drop tableid
sort Article_Authors2 Study_outcome
gen tempforid = Article_Authors + year_str + Study_outcome + PPE_dollarstype
encode tempforid, gen(tableid)
drop tempforid


cd "`filepath'/Figures and Tables"
tempname table
file open `table' using "`filename'.tex", write replace
file write `table' "\begin{ThreePartTable}" _n
file write `table' "\scriptsize" _n
file write `table' "\begin{TableNotes}" _n
file write `table' "\item This represents all studies included in our meta-analyses which report separate effects for LI and non-LI populations (Except Baron (2021) operational and Goncalves (2015), which report for LI but not non-LI). The studies not included in our analyses, but relevant for identifying whether effects of spending are generally larger for LI populations include: Biasi (2019) on income mobility, Card \& Payne (2002) on test score gaps, JJP (2015) on wages and poverty, Johnson (2015) on wages and poverty. These papers all find either a decrease in outcome gaps between LI and non-LI groups, or specifically more pronounced effects for LI individuals exposed to increased spending." _n
file write `table' "This assumes the \emph{same} dollar change for LI and non-LI districts in \cite{hyman_does_2017}. Without additional information about within- and across-district demographic heterogeneity, we are unable to capture (potentially) different spending changes for LI and non-LI students despite evidence in the paper which suggests money was distributed disproportionately to non-LI schools within districts." _n
file write `table' "Analogous to our inclusion criteria for studies, we include only low-income estimates from Baron (2021) and not non-low-income estimates because (estimates provided by author) indicated no detectable spending change associated with operational referendum change for that population." _n
file write `table' "\end{TableNotes}" _n
file write `table' "\begin{longtable}{p{3cm}|p{1.2cm}|p{1.2cm}|p{1.2cm}|p{1.2cm}|p{1.2cm}|p{8cm}}"
file write `table' "\caption{Studies with LI and non-LI estimates} \\" _n
file write `table' "\label{tab:LInonLIcompare}" _n
file write `table' "Study & Outcome & non-LI \\$ & LI \\$ & non-LI effect & LI effect & LI definition \\" _n
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
			local nonLIdollars = string(round(NONLOWINCPPEchange_CPIadjust[`i'], .01), "%9.2f")
			local LIdollars = string(round(LOWINCPPEchange_CPIadjust[`i'], .01), "%9.2f")
			local nonLIeffect = string(round(NONLOWINCEstimatedEffect_overall[`i'], .0001), "%9.4f")
			local LIeffect = string(round(LOWINCEstimatedEffect_overall[`i'], .0001), "%9.4f")
			local LIdef = prose_deflowinc[`i']
		}
	}
	file write `table' "`authors' & `outcome' & `nonLIdollars' & `LIdollars' & `nonLIeffect' & `LIeffect' & `LIdef' \\" _n
	file write `table' "\hline" _n
}


file write `table' "\insertTableNotes" _n
file write `table' "\end{longtable}" _n
file write `table' "\end{ThreePartTable}" _n
file close `table'

