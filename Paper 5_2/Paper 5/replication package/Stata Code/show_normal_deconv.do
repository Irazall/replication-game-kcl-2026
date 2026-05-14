local filepath "" //Figure A.17

/*
generate figures to show normality assumption isn't off-base
*/

local categories "edattain scores"

foreach cat in `categories'{
	cd "`filepath'/Created Datasets"
	
	import delimited "`cat'_deconv" , clear
	gen deconv=1
	save "a_data_`cat'", replace

	use `cat'_data, clear
	append using a_data_`cat'

	gen theta_2= theta
	replace theta_2= z_score if z_score!=.

	sum z_score, d
	local center=r(p50)


	gen upper= g+1.96*seg
	gen lower= g-1.96*seg

	sum z_score, d
	local center=r(p50)

	cd "`filepath'/Figures and Tables"
	twoway (histogram z_score, bin(10))  (line g theta_2 if decon==1 , yaxis(2)) (function y=normalden(x,`center',1), range(theta_2)) (rcap upper lower theta_2, sort  yaxis(2))  (function y = ntden(4,`center', x), range(theta_2)), legend(pos(7) col(4) order(2 "Normal" 3 "t-distribution" 4 "Deconvolved" 5 "Deconvolved CI")) xtitle("Standardized Effect (theta)")
	graph export "normalityplotALL_`cat'.pdf", replace
	
	twoway (rcap upper lower theta_2, sort), legend(pos(7) col(1) order(2 "Deconvolved CI")) xtitle("Standardized Effect (theta)")
	graph export "normalityplotCI_`cat'.pdf", replace

}
