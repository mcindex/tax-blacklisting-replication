* D08_harmful_regimes_2022.do  |  COCG/OECD harmful-regime reviews (2022 vintage) -> harm_043022.dta (read by F09_T06)
* Copied unchanged from do/input_eu_harmful_updated_042922.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* 2026-10-28: three -graph play boom.grec- lines removed (styling of the effort_* graphs, which are not
* paper exhibits); they left the graphs edited, so Stata asked to save each one.
 import excel "$input\ST-7915-2021-INIT.xlsx", sheet("Sheet1") firstrow clear


dropmiss, obs force trim
* First format standstill dates, as those identify specific regimes (range is F-H)
gen identified_oecd = .
replace identified_oecd = 1 if strrpos(STAND,"OECD FHTP") != 0 
gen identified_cocg = .
replace identified_cocg = 1 if strrpos(STAND,"COCG") != 0 

*
foreach var of varlist STAND {
	replace `var' = substr(`var',1,4)
}
destring STAND , ignore(()+-./ACDEFGHILNOPSTacdefghilmnorstuwxy -./cdo) replace
replace STAND = 2017 if STAND == 201
gen identified_date = STAND

gen index = identified_date != . 
replace identified_oecd = identified_oecd[_n+1] if identified_oecd == . & index == 1 & identified_oecd[_n+1] != . & index[_n+1] == 0		// Aligning OECD results with index case
replace identified_cocg = identified_cocg[_n+1] if identified_cocg == . & index == 1 & identified_cocg[_n+1] != . & index[_n+1] ==0 			// Aligning EU results with index case

* Now we turn to assessment results 
gen result = ""
foreach var of varlist COCGASSESSMENT {
	replace result = "HARMFUL"     if strrpos(`var',"HARMFUL") != 0 			///
									| strrpos(`var',"Harmful") != 0 			///
									| strrpos(`var',"harmful") != 0
	replace result = "NOT HARMFUL" if strrpos(`var',"NOT HARMFUL") != 0 ///
								    | strrpos(`var',"Not harmful") != 0 ///
									| strrpos(`var',"not harmful") != 0 ///
									| strrpos(`var',"Not Harmful") != 0 ///
									| strrpos(`var',"Not currently harmful") !=0 ///
									| strrpos(`var',"Potentially harmful but not actually harmful") !=0 ///
									| strrpos(`var',"Potentially harmful") !=0 ///
									| strrpos(`var',"but not actually harmful") !=0 
	replace result = "OUT OF SCOPE" if strrpos(`var',"Out of scope") !=0 
	replace result = "NOT ASSESSED" if strrpos(`var',"Not assessed") !=0 
}
replace result = result[_n+1] if result == "" & index == 1 & result[_n+1] != "" & index[_n+1] == 0		// Aligning OECD results with index case


* Rollbacks
gen rollback_date = . 
foreach var of varlist ROLLBACKDATE {
	gen `var'_s = substr(`var',1,4)
	destring `var'_s, force replace 
	replace rollback_date = `var'_s if `var'_s != . 
}
replace rollback_date = rollback_date[_n+1] if rollback_date == . & index == 1 & rollback_date[_n+1] != .	 & index[_n+1] == 0 & result == "HARMFUL"	// Aligning OECD results with index case


* Filling out country data
drop if substr(NAMEOFTHEJURISDICTION,1,4)== "II. " ///
	 |  substr(NAMEOFTHEJURISDICTION,1,4)== "III." ///
	 |  substr(NAMEOFTHEJURISDICTION,1,4)== "(cha" ///
	 |  substr(NAMEOFTHEJURISDICTION,1,4)== "NAME" ///
	 |  substr(NAMEOFTHEJURISDICTION,1,3)== "4  "  ///
	 |  substr(NAMEOFTHEJURISDICTION,1,3)== "6  "  ///
	 |  substr(NAMEOFTHEJURISDICTION,1,3)== "7  "  
forvalues i = 10/22 {
	drop if substr(NAMEOFTHEJURISDICTION,1,4)== "`i'  "
}

replace NAMEOFTHEJURISDICTION = NAMEOFTHEJURISDICTION[_n-1] if NAMEOFTHEJURISDICTION == "" & NAMEOFTHEJURISDICTION[_n-1] != ""

replace NAMEOFTHEJURISDICTION = trim(NAMEOFTHEJURISDICTION)
replace NAME = "Anguilla" if NAME == "Anguilla4"
replace NAME = "Macao" in 186/187

kountry NAMEOFTHEJURISDICTION, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "SXM"  if NAMEOFTHEJURISDICTION == "Sint Maarten"
replace iso3 = "CUW"  if NAMEOFTHEJURISDICTION == "Curacao"
replace iso3 = "GGY"  if NAMEOFTHEJURISDICTION == "Guernsey"
replace iso3 = "JEY"  if NAMEOFTHEJURISDICTION == "Jersey"
replace iso3 = "IMN"  if NAMEOFTHEJURISDICTION == "Isle of Man"
replace iso3 = "MAC"  if NAMEOFTHEJURISDICTION == "Macau China"
replace  iso3 = "CUW"  if NAMEOFTHEJURISDICTION == "Curaao"
replace iso3 = "SPM" if NAMEOFTHEJURISDICTION == "Saint-Pierre and Miquelon"
replace iso3 = "SHN" if NAMEOFTHEJURISDICTION == "St Helena and Dependencies"
replace iso3 = "MYS" if substr(NAMEOFTHEJURISDICTION,1,5) == "Malay"
replace iso3 = "VGB" if NAMEOFTHEJURISDICTION == "British Virgin"
replace iso3 = "VGB" if NAMEOFTHEJURISDICTION == "Islands"
replace iso3 = "CZE" if substr(NAMEOFTHEJURISDICTION,1,5) == "CZECH"
replace iso3 = "TTO" if substr(NAMEOFTHEJURISDICTION,1,5) == "Trini"
replace iso3 = "WLF" if substr(NAMEOFTHEJURISDICTION,1,5) == "Walli"
replace iso3 = "MKD" if substr(NAMEOFTHEJURISDICTION,1,17) == "Republic of North"
assert iso3 != ""


keep if index == 1

replace identified_cocg = 0 if identified_cocg == . 
replace identified_oecd = 0 if identified_oecd == . 
gen identified_cocg_eu = identified_cocg == 0 & identified_oecd == 0 

keep iso3 identified* rollback* result

save "$output/regimes_updated.dta", replace 

* Producing graph of identified regimes
preserve
	drop if result == "NOT ASSESSED"
	gen harmful = result == "HARMFUL" 
	collapse (sum) harmful identified_c* identified_o, by(identified_date)
	twoway (line identified_cocg_eu identified_date, lcolor(%75) lwidth(medthick))  ///
		   (line identified_oecd identified_date, lcolor(%75) lwidth(medthick))     ///
		   (line identified_cocg identified_date, lcolor(%75) lwidth(medthick))     ///
		   , ytitle(Number of regimes reviewed) 									///
			 xtitle(" ") 															///
			 legend(order(1 "EU regimes reviewed by COCG"						    ///
						  2 "Non-EU regimes reviewed by COCG"						///
						  3 "Non-EU regimes reveiwed by OECD") cols(1) position(6))
	graph export "$ographs\review_over_time_updated.png", replace width(2000)
restore

* What is the probability of being reviewed by the EU versus the OECD? 
keep if identified_date >=2015
gen harmful = result == "HARMFUL"
gen rollback = rollback_date != .

forvalues y = 2015/2019 {
	gen cocg_id_`y' = identified_cocg == 1 & identified_date == `y'
	gen cocg_rb_`y' = identified_cocg == 1 & rollback_date == `y'
}

collapse (max) identified_oecd identified_cocg any_harmful = harmful any_rollback = rollback cocg_*_* (sum) num_oecd = identified_oecd num_cocg = identified_cocg num_harmful = harmful num_rollback = rollback , by(iso3)
mmerge iso3 using "$output/regready_042822.dta", type(1:1) ukeep(*distance* *ldc* lngdppcn_2015* selected)
foreach var of varlist identified_oecd identified_cocg any_harmful any_rollback num_oecd num_cocg num_harmful num_rollback {
	replace `var' = 0 if `var' == . 
}

mmerge iso3 using "$output/oecd_review_043022.dta", type(1:1) 
replace identified_oecd = 1 if reviewed == 1 
replace any_rollback = 1 if changed == 1

* Calculating net remaining harmful regimes
foreach var of varlist onum* {
	replace `var' = 0 if `var' == . 
}
gen     net_harmful    = (onum_harmful - onum_changed) + (num_harmful - num_rollback)
replace net_harmful    = max(net_harmful, 0)
gen     anynet_harmful = min(net_harmful,1)

gen oecd_net = (onum_harmful - onum_changed)
replace oecd_net   = max(oecd_net, 0)
gen anyoecd = min(oecd_net,1)

preserve
keep iso3 identified* any_rollback any_harmful net_harmful anynet_harmful anyoecd num_rollback onum_changed onum_harmful num_harmful cocg_*_*
foreach var of varlist identified_oecd-anyoecd {
    rename `var' `var'_now
}
save "$output/harm_043022.dta", replace
restore


******************************************************************************
* Generating RD plots of probability of being reviewed and a harmful regime  *
* being detected by: COCG and the FHTP  									 *
******************************************************************************

* OECD review
gen harmful_oecd  = (any_harmful  == 1 & identified_oecd ==1 ) | (harmful == 1 & reviewed == 1) 
gen rollback_oecd = (any_rollback == 1 & identified_oecd ==1 ) | (changed == 1 & reviewed == 1) 

global l_identified_oecd = "Pr(Regime reviewed)"
global l_harmful_oecd = "Pr(Regime found harmful)"
global l_rollback_oecd = "Pr(regime rolled back)"
global t_identified_oecd = "Review"
global t_harmful_oecd = "Review + Detection"
global t_rollback_oecd = "Review + Detection + Rollback"

foreach var of varlist identified_oecd harmful_oecd rollback_oecd {
	cap drop w
	rdrobust `var' distance_homi, p(1) kernel(triangular)
	local bandwidth = e(h_l)
	gen w = . 
	replace w = (1-abs(distance_homi / `bandwidth')) if distance_homi < 0 & distance_homi >= -`bandwidth'
	replace w = (1-abs(distance_homi / `bandwidth')) if distance_homi >= 0 & distance_homi <= `bandwidth'
	cap drop rdplot*
	rdplot `var' distance_homi if abs(distance_homi)<=`bandwidth', hide genvars p(1) masspoints(off)
	twoway (lfitci `var' distance_homi if distance_homi < 0 & abs(distance_homi)<=`bandwidth' , level(90) estopts(robust)) ///
		   (lfitci `var' distance_homi if distance_homi >= 0 & abs(distance_homi)<=`bandwidth', level(90) estopts(robust) lcolor(navy) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth'), xline(0)	///
			 ytitle(${l_`var'})       ///
		   xtitle(Distance to cutoff*)					   ///
		   legend(off)			///
		   subtitle(${t_`var'}) ///
		   yscale(range(-0.2 0.8)) /// 
		   yline(0, lpattern(solid)) ///
		   name(s1, replace) ///
		   scale(2) 
		   graph export "$ographs/`var'_043022.png", replace width(2000) 
		   
	* For presentation
		graph set window fontface "Fira Sans Light"	
	twoway (lfitci `var' distance_homi if distance_homi < 0 & abs(distance_homi)<=`bandwidth' , level(90) estopts(robust)) ///
		   (lfitci `var' distance_homi if distance_homi >= 0 & abs(distance_homi)<=`bandwidth', level(90) estopts(robust) lcolor(navy) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth'), xline(0)	///
			 ytitle(${l_`var'})       ///
		   xtitle(Distance to cutoff*)					   ///
		   legend(off)			///
		   subtitle(${t_`var'}) ///
		   yscale(range(-0.2 0.8)) /// 
		   yline(0, lpattern(solid)) ///
		   scale(1.7)  ///
	   	   plotregion(fcolor("250 250 250") lcolor("250 250 250"))  ///
		   graphregion(fcolor("250 250 250") lcolor("250 250 250"))  											  ///
		   scheme(modern)	
		   graph export "$ographs/`var'_pres_043022.png", replace width(2000)
		   graph set window fontface "LM Roman 10"
}


* EU review
gen harmful_cocg    = (any_harmful  == 1 & identified_cocg ==1 )
gen rollback_cocg   = (any_rollback == 1 & identified_cocg ==1 ) 

global l_identified_cocg = "Pr(Regime reviewed)"
global l_harmful_cocg = "Pr(Regime found harmful)"
global l_rollback_cocg = "Pr(Regime rolled back)"
global t_identified_cocg = "Review"
global t_harmful_cocg = "Review + Detection"
global t_rollback_cocg = "Review + Detection + Rollback"


foreach var of varlist identified_cocg harmful_cocg rollback_cocg {
	cap drop w
	rdrobust `var' distance_homi, p(1) kernel(triangular)
	local bandwidth = e(h_l)
	gen w = . 
	replace w = (1-abs(distance_homi / `bandwidth')) if distance_homi < 0 & distance_homi >= -`bandwidth'
	replace w = (1-abs(distance_homi / `bandwidth')) if distance_homi >= 0 & distance_homi <= `bandwidth'
	cap drop rdplot*
	rdplot `var' distance_homi if abs(distance_homi)<=`bandwidth', hide genvars p(1) masspoints(off)
	twoway (lfitci `var' distance_homi if distance_homi < 0 & abs(distance_homi)<=`bandwidth' , level(90) estopts(robust) fcolor(cranberry%30) lcolor(cranberry) alcolor(%0)) ///
		   (lfitci `var' distance_homi if distance_homi >= 0 & abs(distance_homi)<=`bandwidth', level(90) estopts(robust) fcolor(cranberry%30) lcolor(cranberry) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth', mcolor(cranberry)), xline(0)	///
			 ytitle(${l_`var'})       ///
		   xtitle(Distance to cutoff*)					   ///
		   legend(off)			/// 
		   yscale(range(-0.2 0.8)) ///
		   yline(0, lpattern(solid)) ///
		   subtitle(${t_`var'}) //////
		   name(s1, replace)  ///
		   scale(2) 
		   graph export "$ographs/`var'_043022.png", replace width(2000) 
		   
	* For presentation
	graph set window fontface "Fira Sans Light"	
   	twoway (lfitci `var' distance_homi if distance_homi < 0 & abs(distance_homi)<=`bandwidth' , level(90) estopts(robust) fcolor(cranberry%30) lcolor(cranberry) alcolor(%0)) ///
		   (lfitci `var' distance_homi if distance_homi >= 0 & abs(distance_homi)<=`bandwidth', level(90) estopts(robust) fcolor(cranberry%30) lcolor(cranberry) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth', mcolor(cranberry)), xline(0)	///
			 ytitle(${l_`var'})       ///
		   xtitle(Distance to cutoff*)					   ///
		   legend(off)			/// 
		   yscale(range(-0.2 0.8)) ///
		   yline(0, lpattern(solid)) ///
		   subtitle(${t_`var'}) //////
		   name(s1, replace)  ///
		   scale(1.7)  ///
	   	   plotregion(fcolor("250 250 250") lcolor("250 250 250"))  ///
		   graphregion(fcolor("250 250 250") lcolor("250 250 250"))  											  ///
		   scheme(modern)	
		   graph export "$ographs/`var'_pres_043022.png", replace width(2000)
		   graph set window fontface "LM Roman 10"
}
		   


* Generating table

global cv   "covs(ldc lngdppcn_2015)" 
global ncv  ""
est drop _all
foreach c in distance_homi  z_distance  {
	local n = 1 
	foreach var of varlist identified_cocg identified_oecd harmful_cocg harmful_oecd rollback_oecd rollback_cocg {
		foreach k in ncv cv {
			rdrobust `var' `c', c(0) all ${`k'} fuzzy(selected)
			if "`k'" == "cv" {
				estadd local BASE = "X", replace 
			}
			est sto `c'_m`n'
			local n = `n' + 1
		}
	}
}


* Writing to latex

esttab distance_homi* 																///*
	   using "$otables/nharmful_043022.tex", replace 								///
	   title("Impact of EU selection on probability of detection and rollback of harmful regimes\label{t:rev}") ///
	   booktabs 																///
	   label																    ///
	   keep(Robust) 															///
	   se 																		///
	   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
	   stats(BASE N, fmt(0 %9.0gc) labels("\midrule Controls" "Observations")) ///
	   nonotes  																/// 
	   coeflabels(Robust "Selected by EU") 									///
	   mgroups("{\bf \shortstack{Jurisdiction\\reviewed}}"  									///
	           "{\bf \shortstack{Harmful regime\\detected}}" 				///
			   "{\bf \shortstack{Harmful regime\\rolled back}}" 				///
			   , pattern(1 0 0 0 1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(})   ///
			    span erepeat(\cmidrule(lr){@span})) 							///
	   mtitles("EU" 								///
	           "EU" 								///
			   "OECD"  								///
			   "OECD"  								///
			   "EU" 								///
			   "EU" 								///
			   "OECD"  								///
			   "OECD"  								///
			   "EU" 								///
			   "EU" 								///
			   "OECD"  								///
			   "OECD"  								///
			   ) 									///
			   	   prehead(  \begin{table}[t]\centering	///
		   	   \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}	///
			   \caption{Impact of EU selection on probability of detection and rollback of harmful regimes\label{t:rev}}	///
			   \begin{adjustbox}{max width=\textwidth}	///
			   \begin{tabular}{l*{12}{c}}		///
			   \toprule )	///
       postfoot(																///
	             \bottomrule \end{tabular}	\end{adjustbox}									///
				 \begin{minipage}{1\textwidth} \scriptsize					///
				{\bf Notes:} Outcome is $ = 1 $ if jurisdiction has had at      ///
							 least one regime reviewed by an entity, whether    /// 
							 it had at least one regime reviewed and at least   ///
							 one harmful regime was detected, and whether it    /// 
							 had at least one regime reviewed and at least one  /// 
							 regime was rolled back. Results are divided by     /// 
							 whether the reviewing entity was the EU Code of    ///
							 Conduct Group (COCG) or the OECD Forum on     		///
							 Harmful Tax Practices (FHTP).						///
				             Results use the multidimensional running variable. /// 
							 Coefficient is estimated impact of selection into  ///
							 the EU review process on a different outcome,		///
							 using bandwidth-selection, bias-corrected, robust  ///
							 methods outlined in \citeN{calonico2014robust},    ///
							 \citeN{calonico2018effect} and                     ///
							 \citeN{calonico2019regression}.					///
							 \\ $ ^{*} p<0.10,  ^{**} p<0.05,  ^{***} p<0.01 $  /// 
				 \end{minipage} \end{table}) 
















* Effort away from the cutoff


twoway (lowess identified_oecd distance_homi if distance_homi < 0 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess identified_oecd distance_homi if distance_homi >= 0, lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess identified_cocg distance_homi if distance_homi < 0 , lcolor(cranberry)  lwidth(medthick))   ///
	   (lowess identified_cocg distance_homi if distance_homi >= 0, lcolor(cranberry)  lwidth(medthick))	///
	   , xline(0) ///
		 legend(off) ///
		 ytitle("Pr(Regime is reviewed)") ///
		 xtitle("Distance to multidimensional cutoff") ///
		 subtitle("Probability of review") ///
		 name(n1, replace) scale(1.2)

twoway (lowess harmful_oecd distance_homi if distance_homi < 0 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess harmful_oecd distance_homi if distance_homi >= 0, lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess harmful_cocg distance_homi if distance_homi < 0 , lcolor(cranberry)  lwidth(medthick))   ///
	   (lowess harmful_cocg distance_homi if distance_homi >= 0, lcolor(cranberry)  lwidth(medthick))	///
	   , xline(0) ///
	     legend(off) ///
		 ytitle("Pr(Harmful regime detected)") ///
		 xtitle("Distance to multidimensional cutoff") ///
		 subtitle("Probability that harmful regime is found") ///
		 name(n2, replace) scale(1.2)

		 

		 
graph combine n1 n2, ycommon 		 
	 graph export "$ographs\effort_multi_043022.png", replace width(2000) 
	 
		 

twoway (lowess identified_oecd z_distance if z_distance < 0 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess identified_oecd z_distance if z_distance >= 0, lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess identified_cocg z_distance if z_distance < 0 , lcolor(cranberry)  lwidth(medthick))   ///
	   (lowess identified_cocg z_distance if z_distance >= 0, lcolor(cranberry)  lwidth(medthick))	///
	   , xline(0) ///
	     legend(off) ///
		 ytitle("Pr(Regime is reviewed)") ///
		 xtitle("Distance to stability factors cutoff") ///
		 subtitle("Probability of review") ///
		 name(n1, replace) scale(1.2)

twoway (lowess harmful_oecd z_distance if z_distance < 0 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess harmful_oecd z_distance if z_distance >= 0, lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess harmful_cocg z_distance if z_distance < 0 , lcolor(cranberry)  lwidth(medthick))   ///
	   (lowess harmful_cocg z_distance if z_distance >= 0, lcolor(cranberry)  lwidth(medthick))	///
	   , xline(0) ///
	     legend(off) ///
		 ytitle("Pr(Harmful regime detected)") ///
		 xtitle("Distance to stability factors cutoff") ///
		 subtitle("Probability that harmful regime is found") ///
		 name(n2, replace) scale(1.2)
	
graph combine n1 n2, ycommon 		 
	 graph export "$ographs\effort_z_043022.png", replace width(2000) 
	 		 
		 
		 
twoway (lowess harmful_oecd x_distance   if selected ==1 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess harmful_cocg x_distance    if selected ==1, lcolor(cranberry)  lwidth(medthick))   ///
	   ,  legend(order(1 "OECD FHTP" 2 " EU COCG") cols(2) position(6) subtitle("Reviewing entity:")) ///
		 ytitle("Pr(Regime is reviewed)") ///
		 xtitle("Strength of Ties with the EU (distance from cutoff)") ///
		 yscale(range(0 0.8)) ///
		 name(n3, replace) scale(1.2)



twoway (lowess identified_oecd x_distance   if selected ==1 , lcolor(navy) 		lwidth(medthick)) 	///
	   (lowess identified_cocg x_distance    if selected ==1, lcolor(cranberry)  lwidth(medthick))   ///
	   ,  legend(order(1 "OECD FHTP" 2 "EU COCG") cols(2) position(6) subtitle("Reviewing entity:")) ///
		 ytitle("Pr(Harmful regime detected)") ///
		 xtitle("Strength of Ties with the EU (distance from cutoff)") ///
		 yscale(range(0 0.8)) ///
		 name(n4, replace) scale(1.2)


		 
grc1leg n3 n4, ycommon 		 
	 graph export "$ographs\effort_x_043022.png", replace width(2000) 
	 
		 
		 
		 
		 
		 
	exit



binscatter identified_oecd distance_homi, ///
		   rd(0) 						  ///
		   linetype(none)				  ///
		   ytitle(Proportion reviewed by OECD FHTP) ///
		   xtitle(Distance from cutoff) 
graph export "$ographs\review_over_time.png", replace width(2000)
binscatter identified_cocg distance_homi, ///
		   rd(0) 						  ///
		   linetype(none)				  ///
		   ytitle(Proportion reviewed by EU COCG) ///
		   xtitle(Distance from cutoff)

