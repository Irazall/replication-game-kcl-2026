local filepath "" //Table A.17 //Table A.18
clear frames


cd "`filepath'/Created Datasets"
use SchoolSpendingPapers_overall, clear


//test score one per
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)
local REOneTauTest = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REOneThetaTest = string(round(_b[_cons], .0001), "%9.3f")
local REOneSETest = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep  if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesOneThetaTest = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesOneSETest = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesOneTauTest = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
local colsSD = colsof(e(cri))
local rowsSD = rowsof(e(cri))
local rowsminone = `rowsSD' - 1
local taulower = string(round(sqrt(e(cri)[`rowsminone', `colsSD']), .0001), "%9.3f")
local tauupper = string(round(sqrt(e(cri)[`rowsSD', `colsSD']), .0001), "%9.3f")
local BayesOneTauTestCI = "(`taulower', `tauupper')" 
restore

//ed attain one per
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary, variance(EstimatedEffect_overall_Var) study(studyid)
local REOneTauEd = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REOneThetaEd = string(round(_b[_cons], .0001), "%9.3f")
local REOneSEEd = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep if Study_isprimary
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesOneThetaEd = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesOneSEEd = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesOneTauEd = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
local colsSD = colsof(e(cri))
local rowsSD = rowsof(e(cri))
local rowsminone = `rowsSD' - 1
local taulower = string(round(sqrt(e(cri)[`rowsminone', `colsSD']), .0001), "%9.3f")
local tauupper = string(round(sqrt(e(cri)[`rowsSD', `colsSD']), .0001), "%9.3f")
local BayesOneTauEdCI = "(`taulower', `tauupper')" 
restore

//test score mult per
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall, variance(EstimatedEffect_overall_Var) study(studyid)
local REMultTauTest = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REMultThetaTest = string(round(_b[_cons], .0001), "%9.3f")
local REMultSETest = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep  if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesMultThetaTest = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesMultSETest = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesMultTauTest = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
local colsSD = colsof(e(cri))
local rowsSD = rowsof(e(cri))
local rowsminone = `rowsSD' - 1
local taulower = string(round(sqrt(e(cri)[`rowsminone', `colsSD']), .0001), "%9.3f")
local tauupper = string(round(sqrt(e(cri)[`rowsSD', `colsSD']), .0001), "%9.3f")
local BayesMultTauTestCI = "(`taulower', `tauupper')" 
restore

//ed attain mult per
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates"), variance(EstimatedEffect_overall_Var) study(studyid)
local REMultTauEd = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REMultThetaEd = string(round(_b[_cons], .0001), "%9.3f")
local REMultSEEd = string(round(_se[_cons], .0001), "%9.3f")
preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesMultThetaEd = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesMultSEEd = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesMultTauEd = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
local colsSD = colsof(e(cri))
local rowsSD = rowsof(e(cri))
local rowsminone = `rowsSD' - 1
local taulower = string(round(sqrt(e(cri)[`rowsminone', `colsSD']), .0001), "%9.3f")
local tauupper = string(round(sqrt(e(cri)[`rowsSD', `colsSD']), .0001), "%9.3f")
local BayesMultTauEdCI = "(`taulower', `tauupper')" 
restore

//test score f > 10
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)
local REFtenTauTest = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REFtenThetaTest = string(round(_b[_cons], .0001), "%9.3f")
local REFtenSETest = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep  if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesFtenThetaTest = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesFtenSETest = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesFtenTauTest = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
restore

//ed attain f > 10
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 10, variance(EstimatedEffect_overall_Var) study(studyid)
local REFtenTauEd = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REFtenThetaEd = string(round(_b[_cons], .0001), "%9.3f")
local REFtenSEEd = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep if FirstStage_Fstat > 10
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesFtenThetaEd = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesFtenSEEd = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesFtenTauEd = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
restore

//test score f > 20
robumeta EstimatedEffect_overall if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var) study(studyid)
local REFtwenTauTest = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REFtwenThetaTest = string(round(_b[_cons], .0001), "%9.3f")
local REFtwenSETest = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep  if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 20
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesFtwenThetaTest = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesFtwenSETest = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesFtwenTauTest = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
restore

//ed attain f > 20
robumeta EstimatedEffect_overall if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20, variance(EstimatedEffect_overall_Var) study(studyid)
local REFtwenTauEd = string(round(sqrt(e(tau2)), .0001), "%9.3f")
local REFtwenThetaEd = string(round(_b[_cons], .0001), "%9.3f")
local REFtwenSEEd = string(round(_se[_cons], .0001), "%9.3f")

preserve
keep if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
keep if FirstStage_Fstat > 20
bayesmh EstimatedEffect_overall i.studyid , nocons likelihood(normal(EstimatedEffect_overall_Var))  prior({EstimatedEffect_overall:i.studyid}, normal({theta} , {tau2} ))  prior({theta}, normal(0 , 100))  prior({tau2}, igamma(0.0001,0.0001))  block({EstimatedEffect_overall:i.studyid}, split) block({theta}, gibbs) block({tau2}, gibbs) dots
local cols = colsof(e(mean))
local colsminone = `cols' - 1
local BayesFtwenThetaEd = string(round(e(mean)[1,`colsminone'], .0001), "%9.3f")
local BayesFtwenSEEd = string(round(e(sd)[1,`colsminone'], .0001), "%9.3f")
local BayesFtwenTauEd = string(round(sqrt(e(mean)[1,`cols']), .0001), "%9.3f")
restore

count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall
local Nmultpertest = r(N)
count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
local Nonepertest = r(N)
count if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates")
local Nmultperedattain = r(N)
count if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & Study_isprimary
local Noneperedattain = r(N)
count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 10
local NtestF10 = r(N)
count if (Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & nonRauschOverall & FirstStage_Fstat > 20
local NtestF20 = r(N)
count if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 10
local NedF10 = r(N)
count if !(Study_outcome == "Test scores" | Study_outcome == "Test proficiency rates") & FirstStage_Fstat > 20
local NedF20 = r(N)

forvalues i = 1/2{
	cd "`filepath'/Figures and Tables"
	tempname table
		if `i' == 1{
			local filename "bayescomp"
			local titlemod ""
		}
		else if `i' == 2{
			local filename "baesbyfirststage"
			local titlemod ", by First Stage Strength"
		}
		file open `table' using "`filename'.tex", write replace
		file write `table' "\begin{table} \centering" _n
		file write `table' "\caption{Bayes Estimates, `titlemod'}\label{tab:bayesests`i'}" _n
		file write `table' "\begin{tabular}{c|c|c|c|c|c|c|c|c}" _n
		if `i' == 1{
			file write `table' "& \multicolumn{4}{c}{One Estimate Per Study} & \multicolumn{4}{c}{Multiple Estimates Per Study} \\ " _n
		}
		else if `i' == 2{
			file write `table' "& \multicolumn{4}{c}{F-stat \$>\$ 10} & \multicolumn{4}{c}{F-stat \$>\$ 20} \\ " _n
		}
		file write `table' "\multicolumn{1}{l|}{} & \multicolumn{2}{c|}{Test Scores} & \multicolumn{2}{l|}{Educational Attainment} & \multicolumn{2}{c|}{Test Scores} & \multicolumn{2}{l|}{Educational Attainment} \\ " _n
		file write `table' " \hline \hline" _n
		file write `table' "& RE & Bayes & RE & Bayes & RE & Bayes & RE & Bayes \\" _n
		file write `table' "\hline" _n
		if `i' == 1{ //bayescomp
			file write `table' "$\theta$ & `REOneThetaTest' & `BayesOneThetaTest' & `REOneThetaEd' & `BayesOneThetaEd' & `REMultThetaTest' & `BayesMultThetaTest' & `REMultThetaEd' & `BayesMultThetaEd' \\" _n
			file write `table' "		& (`REOneSETest')& (`BayesOneSETest')& (`REOneSEEd')& (`BayesOneSEEd') & (`REMultSETest')& (`BayesMultSETest')& (`REMultSEEd')& (`BayesMultSEEd')\\" _n
			file write `table' "\hline" _n
			file write `table' "$\tau$& `REOneTauTest' & `BayesOneTauTest' & `REOneTauEd' & `BayesOneTauEd' & `REMultTauTest' & `BayesMultTauTest' & `REMultTauEd' & `BayesMultTauEd'\\  " _n
			file write `table' "$\tau$ 95\% CI& `REOneTauTestCI' & `BayesOneTauTestCI' & `REOneTauEdCI' & `BayesOneTauEdCI' & `REMultTauTestCI' & `BayesMultTauTestCI' & `REMultTauEdCI' & `BayesMultTauEdCI'\\  " _n
			file write `table' "N & `Nonepertest' & `Nonepertest' & `Noneperedattain' & `Noneperedattain' & `Nmultpertest' & `Nmultpertest' & `Nmultperedattain' & `Nmultperedattain'  \\" _n
		}
		else if `i' == 2{ //fstat
			file write `table' "$\theta$ & `REFtenThetaTest' & `BayesFtenThetaTest' & `REFtenThetaEd' & `BayesFtenThetaEd' & `REFtwenThetaTest' & `BayesFtwenThetaTest' & `REFtwenThetaEd' & `BayesFtwenThetaEd' \\" _n
			file write `table' "		& (`REFtenSETest')& (`BayesFtenSETest')& (`REFtenSEEd')& (`BayesFtenSEEd') & (`REFtwenSETest')& (`BayesFtwenSETest')& (`REFtwenSEEd')& (`BayesFtwenSEEd')\\" _n
			file write `table' "\hline" _n
			file write `table' "$\tau$& `REFtenTauTest' & `BayesFtenTauTest' & `REFtenTauEd' & `BayesFtenTauEd' & `REFtwenTauTest' & `BayesFtwenTauTest' & `REFtwenTauEd' & `BayesFtwenTauEd' \\  " _n
			file write `table' "N & `NtestF10' & `NtestF10' & `NedF10' & `NedF10' & `NtestF20' & `NtestF20' & `NedF20' & `NedF20'  \\" _n
		}
		file write `table' "\hline \hline" _n
		file write `table' "\end{tabular}" _n
		file write `table' "\end{table}" _n

}

	
