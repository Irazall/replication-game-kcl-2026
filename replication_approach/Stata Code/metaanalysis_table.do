local filepath "" //(Table 2)

cd "`filepath'/Created Datasets"
import excel ests_forbayes, firstrow sheet("Primary") clear
save ests_forbayes, replace

use SchoolSpendingPapers_overall, clear


local filename "AnalysisPapersTable"
keep if Study_isprimary

merge 1:1 Article_Authors Study_outcome using ests_forbayes

keep if !regexm(Study_outcome, "Wages") & !regexm(Study_outcome, "mobility") & !regexm(Study_outcome, "gaps")

replace Article_Authors2 = "Baronb" if Article_Authors2 == "Baron" & PPE_dollarstype == "capital"
replace Article_Authors2 = "Rauscherb" if Article_Authors2 == "Rauscher" & regexm(lower(Article_Title), "country")
sort Article_Authors2
encode Article_Authors2, gen(studyID)

sort Article_Authors2 Study_outcome
gen tempforid = Article_Authors2 + year_str + Study_outcome
encode tempforid, gen(tableid)
drop tempforid


sort Article_Authors2 Study_outcome
gen tempforid = Article_Authors2 + year_str + Study_outcome if !regexm(EstimtedEffect1_source, "made up")
encode tempforid, gen(obsID)
drop tempforid

replace Article_Authors2 = "Baron" if Article_Authors2 == "Baronb" & PPE_dollarstype == "capital"
replace Article_Authors2 = "Rauscher" if Article_Authors2 == "Rauscherb" 

replace EstimatedEffect_overall = . if regexm(EstimtedEffect1_source, "made up")
replace EstimatedEffect_overall_SE = . if regexm(EstimtedEffect1_source, "made up")

cd "`filepath'/Figures and Tables"
tempname table
file open `table' using "`filename'.tex", write replace
file write `table' "\begin{table}" _n
file write `table' "\footnotesize" _n
file write `table' "\caption{Summary of Studies}" _n
file write `table' "\label{tab:summary}" _n
file write `table' "\begin{tabular}{l|l|l|l|l|l|l|l}" _n
file write `table' "\hline\noalign{\smallskip}" _n
file write `table' "Study & Study ID & Outcome & Spending Type & \shortstack{Estimation \\ Strategy} & \shortstack{Raw Estimate \\ (\$\hat{\theta}_j\$)} & \shortstack{SE of \$\hat{\theta}_j\$ \\(\$se_j\$)} & \shortstack{Bayes Estimate \\ ($\tilde{\theta}_j$)} \\" _n
file write `table' "\hline\noalign{\smallskip}" _n
file write `table' "\hline" _n
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
			local studyID = studyID[`i']
			local obsID = obsID[`i']
			local outcome = Study_outcome[`i'] 
			local effect = string(round(EstimatedEffect_overall[`i'], .0001), "%9.4f")
			local SEMax = string(round(EstimatedEffect_overall_SE[`i'], .0001), "%9.4f")
			local bayes = string(round(bayes_bayesest[`i'], .0001), "%9.4f")
			local EstStrat = Study_estimationstrategy[`i']
			if PPE_dollarstype[`i'] == "capital"{
				local SpendType "Capital"
			}
			else if PPE_dollarstype[`i'] == "operational"{
				local SpendType "Operational"
			}
			else if PPE_dollarstype[`i'] == "Any" | PPE_dollarstype[`i'] == "SFR"{
				local SpendType "Any"
			}
		}
		
		else{
			//do nothing
		}	
		
	}
	file write `table' "`authors' & `studyID' & `outcome' & `SpendType' & `EstStrat' & `effect'`SigStar'`SigStar10' & `SEMax' & `bayes' \\" _n
}

file write `table' "\hline\noalign{\smallskip}" _n
file write `table' "\end{tabular}" _n
file write `table' "\begin{tablenotes}" _n
file write `table' "\item RD = Regression Discontinuity; ES = Event Study; DiD = Difference in Differences; IV = Instrumental Variable"
file write `table' "\item Clustering by study-outcome, as well as studies of same policies, including OH capital subsidy program (\cite{conlin_impacts_2017} and \cite{goncalves_effects_2015})," "MI Proposal A (\cite{chaudhary_education_2009}, \cite{hyman_does_2017}, \cite{papke_effects_2008}, and \cite{roy_impact_2011}), Same-years SFRs (\cite{lafortune_school_2018} and \cite{brunner_school_2020}), " "and Title I (\cite{johnson_follow_2015} and \cite{cascio_local_2013}). \cite{jackson_effects_2016} and \cite{johnson_reducing_2019} are combined and study older school finance reforms. " _n
file write `table' "\item \cite{johnson_reducing_2019} omitted for duplication reasons with \cite{jackson_effects_2016}."
file write `table' "\end{tablenotes}" _n
file write `table' "\end{table}" _n
file close `table'
