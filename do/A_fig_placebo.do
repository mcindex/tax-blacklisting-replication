* A_fig_placebo.do  |  APPENDIX f:placebo placebo cutoffs (_091326; reduced form at each placebo cutoff)
* 2026-09-15: trimmed to the placebo panels in the online appendix; dead code (presentation versions, superseded donut section) removed
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/placebo_050322.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* This .do file calculates RD estimates using placebo cutoffs
* 2026-09-10 (R&R): frozen PRI-fixed file, rule-eligible sample (non-LDC + Vanuatu), Euclidean + z-frontier running variables
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs

* Outcomes I am interested
global o = "if_part_now ever_either harm_now"   // 2026-09-15: mil_signed_now dropped (not in the appendix)

* Running variables I am interested in 
global c = "distance z_frontier"   // 2026-09-10: was z_distance distance distance_homi


* Outcomes I am interested
global o_if_part_now = "IF membership" 
global o_ever_either   = "Grey or blacklisted" 
global o_harm_now   = "Reviewed w/ no harmful regimes"
global o_mil_signed_now   = "Signed MIL"


* Now we loop and proceed as follows
foreach cu in $c {								// Looping over running variables
	foreach oc in $o {							// Looping over cutoffs of interest

	mat drop _all
	estimates drop _all
	
	* First we determine the start and end of the running variable, 
	* round to the nearest 10th
	sum `cu', detail
	local minus = round(`r(min)',10) + 10 
	local plus  = round(`r(max)',10) - 10 

	* Then we loop over that entire interval in 10 unit steps
	global l = ""
	local ea = 1																// Startin a counter
		forvalues d = `minus'(10)`plus' {										// Looping over interval
			di "Cutoff `d'"														// Announcing the cutoff
			cap drop `oc'_`ea'
			gen `oc'_`ea' = `oc'												// To trick Coefplot, we create a model-specific filler here

			* How we cut the sample depends on where we are over the interval
			* (note we are capturing all results because for some pseudo 
			
			* If we are below the real cutoff
			if `d' < 0 {
				cap rdrobust `oc'_`ea' `cu' if `cu' < 0 , c(`d') all masspoints(off) 			// then we limit the sample to obs before the real cutoff to avoid "contamination"
				local b = e(tau_cl)   // 2026-09-13 (coherence review fix): conventional coefficient (paper convention), robust CI												// Storing _b estimates as we will use them to trick coefplot
				local v = e(se_tau_rb)^2										// Storing _v estimates as we will use them to trick coefplot
			}
			
			* If we are above the real cutoff 									// then we limit the sample to obs above the real cutoff to avoid "contamination"
			else if `d' > 0 {
				cap rdrobust `oc'_`ea' `cu' if `cu' > 0 , c(`d') all masspoints(off)  			
				local b = e(tau_cl)   // 2026-09-13 (coherence review fix): conventional coefficient (paper convention), robust CI												// Storing _b estimates as we will use them to trick coefplot
				local v = e(se_tau_rb)^2										// Storing _v estimates as we will use them to trick coefplot
			}
			
			* If we are at the real cutoff
			else if `d' == 0 {
				cap rdrobust `oc'_`ea' `cu', c(`d') all masspoints(off) 						// We proceed as normal		
				local b = e(tau_cl)   // 2026-09-13 (coherence review fix): conventional coefficient (paper convention), robust CI												// Storing _b estimates as we will use them to trick coefplot
				local v = e(se_tau_rb)^2										// Storing _v estimates as we will use them to trick coefplot
			}
			
			* If RDRobust manages to run, we proceed and run a regular OLS regression, 
			* then swap out the results with those from RDRobust
			* we do this as it allows us to easily rename the coefficient of interest, 
			* which is another way to trick coefplot
			if _rc == 0 {														// If statement only allowed through if there is no error
				capture drop `cu'_`ea'											
				capture gen `cu'_`ea' = `cu'
				qui reg `oc'_`ea' `cu'_`ea'
				qui matrix list e(V)
				mat bn	      = e(b)
				mat bn[1,1]   = `b'
				mat Vn	      = e(V) 
				mat Vn[1,1]   = `v'
				capture erepost b     = bn, rename
				capture erepost V     = Vn, rename
				est sto d`ea'
				cap estadd matrix at = (`ea',`ea') 								// We add a matrix with elements = to the number of the running counter. This is used to correctly space coefficients in coefplot
				global l = `"$l `ea' "`d'" "'									// This global is used to correctly label coefficients in cofplot
			}
				* Saving for labels
				if `d' == 0 {
					local s = `ea'
				}
				
				
				local ea = `ea' +1												// Moving the coutner forward
		}	


		* Running coefplot
		coefplot  d*, 						   ///
			  keep(`cu'*) 					   ///
			  ci(95)            			   ///
			  vertical          			   ///
			  at   							   ///
			  yline(0, lpattern(solid))		   ///
			  xlabel($l)  					   ///
			  legend(off)					   ///
			  mcolor(blue) 					   ///
			  ciopts(lcolor(blue)) 			   ///
			  ytitle(RD estimate)  			   ///
			  scheme(Modern) 				   ///
			  xsize(8)		                   ///
			    subtitle(${o_`oc'}) ///
			  xtitle(Cutoff)  scale(3) ///
			  mlabels(`cu'_`s' = 1 "*")  ///
			  mlabcolor(black)	
			  graph export "$ographs\placebo_`cu'_`oc'_091326.png", replace width(2000)
		graph export "$graphs\placebo_`cu'_`oc'_091326.png", replace width(2000)
			  
			  graph set window fontface "LM Roman 10"


	}

}
 
