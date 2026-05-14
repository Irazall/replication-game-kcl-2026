clear all
set more off

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "estout robumeta metareg ivreg2 ranktest unique blindschemes"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }
	
	/* labutil via ssc does not work somehow, hence we need to install it manually */
	copy "http://fmwww.bc.edu/repec/bocode/l/labmask.ado" "`c(sysdir_plus)'l/labmask.ado", replace
	copy "http://fmwww.bc.edu/repec/bocode/l/labmask.hlp" "`c(sysdir_plus)'l/labmask.hlp", replace



end

main
