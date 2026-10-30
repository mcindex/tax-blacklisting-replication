* A_tab_global_poly.do  |  APPENDIX t:rob global polynomial fuzzy RD (rd_robu_091326); l.135 also writes regready_042822.dta checkpoint
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; global-polynomial columns are 2SLS (ivreg2, review
* instrumented by the above-cutoff indicator); the legacy 2022 Table 3 block and the presentation bar chart are disabled (if 0)
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/rd_regressions_042722.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************
* This file conducts the main RD analysis in the paper *
********************************************************

* Loading sample
use "$output/rd_sample_032522.dta", clear

**************************************************
* Some notes on date of outcomes being measured: *
**************************************************
* Inclusive Framework participation: 12/30/2019
* CbCR participation: 				 12/22/2019
* AEOI committments: 				 Jan/2020
* AEOI coverage: 					 Feb/2020
* MLI signatories: 					 02/28/20
* MAP publishing:  				     04/06/2020
* MAA convention: 					 02/15/20
* EOIR			: 06/April/20
* Harmful tax practices: July, 2019


* Formatting outcomes
gen     aeoi_2020  =         AEOI_exchange != .
gen     if_part    =         if_participation_121519
rename  map_040620             map
rename  map_committed_040620   map_committed
replace map            = 0 if map == . 
replace map_committed  = 0 if map_committed == . 
gen     mil_signed     =     d_Date_Signature != .
drop    maa
gen     maa            =     maa_signed != . 
rename  cbcr_signed_122219      cbcr_s
rename  per_EU_relationships    per_EU
rename  gf_participation_111919 gf
egen    identified_either = rowmax(identified_oecd identified_cocg)
gen     harm = identified_either == 1 & anynet_harmful == 0 
gen     eoi            = eoir == "Compliant" | eoir == "Largely Compliant"
gen global_deal = global_deal_now

* New outcomes: 
gen     aeoi_2020_now  =      aeoi_committed_date == 1
gen     if_part_now    =      inclusive_now
gen     map_now        =     map_020922
gen     map_committed_now =  map_committed_020922 
gen     mil_signed_now = mli_now
gen     maa_now            =   maac_now 
gen     cbcr_s_now = cbcr_signed
gen     per_EU_now =  per_EU_relationships_now
* GF now already defined
egen    identified_either_now = rowmax(identified_oecd_now identified_cocg_now)
gen     harm_now = identified_either_now == 1 & anynet_harmful_now == 0 
gen     eoi_now            = eoir_compliance


* Formatting covariates
gen     ldc = status == "LDC"
lab var ldc           "LDC"
lab var lngdppcn_2015 "Log(GDP per capita) (2015)"
global  covariates    "lngdppcn_2015 ldc"

* Creating avg composite outcomes
egen tax_transparency = rmean(aeoi_2020 per_EU eoi maa)					
 gen fair_taxation    = harm					
egen anti_beps        = rmean(cbcr_s mil_signed map)

egen tax_transparency_now = rmean(aeoi_2020_now per_EU_now eoi_now maa_now)					
 gen fair_taxation_now    = harm_now					
egen anti_beps_now        = rmean(cbcr_s_now mil_signed_now map_now)

* Mean effects outcomes
foreach d in distance distance_homi z_distance {
	foreach var of varlist aeoi_2020 per_EU if_part cbcr_s mil_signed map	{
		sum `var' if `d' < 0 
		gen me`var'_`d' = (`var' - r(mean)) / r(sd) 
	}
	egen metax_transparency_`d' = rmean(meaeoi_2020_`d' meper_EU_`d')					// Missing: EOIR relationships
	gen  mefair_taxation_`d'    = meif_part_`d'						
	egen meanti_beps_`d'        = rmean(mecbcr_s_`d' memil_signed_`d' memap_`d' meif_part_`d')
	
	lab var metax_transparency_`d' "Tax transparency (mean effects)"
	lab var mefair_taxation_`d'    "Fair taxation (mean effects)"
	lab var meanti_beps_`d'        "Anti-BEPS (mean effects)"
}


* At least one BEPS minimum standard
gen harmoecd = identified_oecd == 1 & anyoecd == 0 
gen harmoecd_now = identified_oecd_now == 1 & anyoecd_now == 0 
egen minstandard = rowmax(harmoecd cbcr_s mil_signed map)
egen numstandard  = rowtotal(harmoecd cbcr_s mil_signed map)

egen numstandard_now  = rowtotal(harmoecd_now cbcr_s_now mil_signed_now map_now)


egen ever_either = rowmax(ever_bl ever_gl)


* List outcoems of interest here
global outcomes_rf = "tax_transparency aeoi_2020 per_EU eoi maa fair_taxation harm anti_beps cbcr_s mil_signed map if_part global_deal gf greylisted blacklisted both numstandard"
global outcomes_iv = "tax_transparency aeoi_2020 per_EU eoi maa fair_taxation harm anti_beps cbcr_s mil_signed map if_part global_deal gf greylisted blacklisted both numstandard"
global outcomes_rf_now = "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either numstandard_now"
global outcomes_iv_now = "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either numstandard_now"


* Graph for presentation

* Other business
foreach d in z_distance distance distance_homi {
	gen     `d'_above = `d' >=0 
	replace `d'_above = . if `d' == . 
}

* Dropping these so we can generate them below
capture drop *above distance2 distance3 distance4

replace selected = reviewed


save "$output\regready_042822.dta", replace


***************
* Regressions *
***************

**************
* Robustness *
**************
* 2026-09-10 (R&R): frozen PRI-fixed file, rule-eligible sample (non-LDC + Vanuatu), z-frontier running variable
use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
gen z_frontier_above = z_frontier >= 0 if z_frontier < .
lab var z_frontier "Stability factors cutoff (frontier)"
gen selected_fill = .
global outcomes_rf_now = "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack fair_taxation_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now numstandard_now"   // 2026-09-13 (coherence review fix): eoi before maa, as T03
* 2026-09-13 (coherence review, H1): the frozen file carries no variable labels, so esttab printed
* "selected" on every row; labels and (i)-(iv) numbering as in T03_main_rd.do / F05
lab var tax_transparency_now "\hspace{.3cm} \emph{Mean outcome}"
lab var aeoi_2020_now        "\hspace{.4cm} (i) CRS commitment by 2023"
lab var per_EU_now           "\hspace{.4cm} (ii) \% of EU countries covered by AEOI"
lab var eoi_now              "\hspace{.4cm} (iii) Largely compliant on EOIR"
lab var maa_now              "\hspace{.4cm} (iv) Signed up to MAA"
lab var aeoi_ontrack         "\hspace{.4cm} (v) AEOI rated On Track"   // 2026-09-15: + AEOI On Track outcome (v), transparency mean of (i)-(v) (D11_aeoi_ontrack.do)
lab var fair_taxation_now    "\hspace{.3cm} \emph{Mean outcome}"
lab var anti_beps_now        "\hspace{.3cm} \emph{Mean outcome}"
lab var cbcr_s_now           "\hspace{.4cm} (i) Signed up to CbCR"
lab var mil_signed_now       "\hspace{.4cm} (ii) Signed up to MLI"
lab var map_now              "\hspace{.4cm} (iii) Published MAP profile"
lab var if_part_now          "\hspace{.4cm} Participation in IF"
lab var numstandard_now      "\hspace{.4cm} Number of minimum standards"
est drop _all
capture drop *above
capture drop *_2 *_3
foreach d in z_distance distance distance_homi y_distance x_distance z_frontier {   // 2026-09-10: z_frontier added
	gen `d'_2 = `d'^2
	gen `d'_3 = `d'^3
	
	gen     `d'_above = `d' >=0
	replace `d'_above = . if `d' == .
	
	gen     `d'_above_d = `d'_above *`d' 
	gen     `d'_above_d_2 = `d'_above *`d'_2
	gen     `d'_above_d_3 = `d'_above *`d'_3
}

* * Flexible 
local c = 1
foreach var of varlist $outcomes_rf_now {

	* Linear
	reg `var' selected x_distance y_distance z_distance                , robust
	est sto f_`c'_ncv1
	estadd local POLY = "Linear", replace 
	
	reg `var' selected x_distance y_distance z_distance lngdppcn_2015, robust
	est sto f_`c'_cv1
	estadd local BASE = "X", replace 
	estadd local POLY = "Linear", replace 
	
	* Quadratic
	reg `var' selected x_distance    y_distance    z_distance    ///
						 x_distance_2  y_distance_2  z_distance_2  ///
										, robust
	est sto f_`c'_ncv2
	estadd local POLY = "Quadratic", replace 
										
	reg `var' selected x_distance    y_distance    z_distance    ///
						 x_distance_2  y_distance_2  z_distance_2  ///
						 lngdppcn_2015 , robust
	est sto f_`c'_cv2
	estadd local BASE = "X", replace 
	estadd local POLY = "Quadratic", replace 
	
	* Cubic
	reg `var' selected x_distance    y_distance    z_distance    ///
						 x_distance_2  y_distance_2  z_distance_2  ///
						 x_distance_3  y_distance_3  z_distance_3  ///
										, robust
	est sto f_`c'_ncv3
	estadd local POLY = "Cubic", replace 
	
	reg `var' selected x_distance    y_distance    z_distance    ///
						 x_distance_2  y_distance_2  z_distance_2  ///
						 x_distance_3  y_distance_3  z_distance_3  ///
						 lngdppcn_2015 , robust
	est sto f_`c'_cv3
	estadd local BASE = "X", replace 
	estadd local POLY = "Cubic", replace 
	
	local c = `c' + 1
}


* * Global quadratic 
local c = 1
foreach var of varlist $outcomes_rf_now {
	foreach d in distance z_frontier {   // 2026-09-13: fuzzy 2SLS, review instrumented by `d'_above (was sharp reduced form 2026-09-10; fuzzy on z_distance distance distance_homi in 2022)
		qui replace selected_fill = reviewed
		
		
		* * * IV	
		
		* Linear
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d, robust
		est sto ivq_`d'_`c'_ncv1
		estadd local POLY = "Linear", replace 
		
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d lngdppcn_2015, robust
		est sto ivq_`d'_`c'_cv1
		estadd local BASE = "X", replace 
		estadd local POLY = "Linear", replace 
		
		* Quadratic
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d ///
							`d'_2 `d'_above_d_2 ///
							, robust
		est sto ivq_`d'_`c'_ncv2
		estadd local POLY = "Quadratic", replace
		
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d ///
							`d'_2 `d'_above_d_2 ///
							lngdppcn_2015 ///
							, robust
		est sto ivq_`d'_`c'_cv2
		estadd local BASE = "X", replace 
		estadd local POLY = "Quadratic", replace
		
		*Cubic 
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d ///
							`d'_2 `d'_above_d_2 ///
							`d'_3 `d'_above_d_3 ///
							, robust
		est sto ivq_`d'_`c'_ncv3
		estadd local POLY = "Cubic", replace 
		
		ivreg2 `var' (selected_fill = `d'_above) `d' `d'_above_d ///
							`d'_2 `d'_above_d_2 ///
							`d'_3 `d'_above_d_3 ///
							lngdppcn_2015, robust
		est sto ivq_`d'_`c'_cv3
		estadd local BASE = "X", replace 
		estadd local POLY = "Cubic", replace 
		
	}
	
		local c = `c' + 1	

}


* Writing three part table of "selected" results


local c = 1
foreach var in $outcomes_rf_now {
	local label : variable label `var'
	lab var selected "`label'"

	if "`var'" == "tax_transparency_now" {
	
	*** FIRST ROW
	di "First row"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///	
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								///
			keep(selected) rename(selected_fill selected)																	 ///
			replace f booktabs eqlabels(none) se nogaps label b(a2) compress 				 ///	
			nodep noobs nonotes nolines numbers 	 										 ///
			mgroups("Distance to selection boundary (2SLS)" "Stability factors cutoff, frontier (2SLS)" "Flexible controls (OLS)", pattern(1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
			nomtitles ///
			starlevels(* 0.10 ** 0.05 *** 0.01)		refcat(selected "\emph{{\bf (A) Tax transparency: }}", nolabel)
	}
	
	** * VERY LAST ROW
	else if "`var'" == "numstandard_now" {
	di "Last row"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///	
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								    		 ///
			keep(selected) rename(selected_fill selected)																	 ///									///
			append f booktabs eqlabels(none) se nogaps label b(a2) compress ///	
			nodep noobs nonotes nolines nonumbers nomtitles 	 						///
			starlevels(* 0.10 ** 0.05 *** 0.01)						///
			stats(POLY BASE N, fmt(0 0 %9.0gc) labels("\midrule Polynomial" "Controls" "Observations")) 
	}
	
	* Fair taxation
	else if "`var'" == "fair_taxation_now" {
	di "Fair Tax"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///	
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								    		 ///
			keep(selected) rename(selected_fill selected)																	 ///
			append f booktabs eqlabels(none) se nogaps label b(a2) compress ///	
			nodep noobs nonotes nolines nonumbers nomtitles 	 						///
			starlevels(* 0.10 ** 0.05 *** 0.01)		///
			refcat(selected "\midrule \emph{{\bf (B) Fair taxation: }}", nolabel) 

	}

	* Anti Beps
	else if "`var'" == "anti_beps_now" {
	di "Anti-BEPS"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///	
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								    		 ///
			keep(selected) rename(selected_fill selected)																	 ///											///
			append f booktabs eqlabels(none) se nogaps label b(a2) compress ///	
			nodep noobs nonotes nolines nonumbers nomtitles 	 						///
			starlevels(* 0.10 ** 0.05 *** 0.01)		///
			refcat(selected "\midrule \emph{{\bf (C) Anti-BEPS: }}", nolabel) 

	}

	
	* Other/intermediate
	else if "`var'" == "if_part_now" {
	di "Anti-BEPS"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///	
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								    		 ///
			keep(selected) rename(selected_fill selected)																	 ///											///
			append f booktabs eqlabels(none) se nogaps label b(a2) compress ///	
			nodep noobs nonotes nolines nonumbers nomtitles 	 						///
			starlevels(* 0.10 ** 0.05 *** 0.01)		///
			refcat(selected "\midrule \emph{{\bf Intermediate and other outcomes: }}", nolabel) 

	}


	*** MIDDLE ROWS WITHOUT TITLES
	else {
	di "Middle-rows"
	esttab  ///
			ivq_distance_`c'_ncv1      ivq_distance_`c'_cv1 					///
			ivq_distance_`c'_ncv2      ivq_distance_`c'_cv2						///
    		ivq_distance_`c'_ncv3	   ivq_distance_`c'_cv3     				///	
			ivq_z_frontier_`c'_ncv1    ivq_z_frontier_`c'_cv1 					///
			ivq_z_frontier_`c'_ncv2    ivq_z_frontier_`c'_cv2					///
    		ivq_z_frontier_`c'_ncv3	   ivq_z_frontier_`c'_cv3     				///		
			f_`c'_ncv1 				   f_`c'_cv1 				   			  	///
			f_`c'_ncv2 	 			   f_`c'_cv2 								///
			f_`c'_ncv3     			   f_`c'_cv3					 			///
			using "$otables/rd_robu_091326.tex", 								    		 ///
			keep(selected) rename(selected_fill selected)																	 ///								    
							append f booktabs eqlabels(none) se nogaps label b(a2) compress ///	
							nodep noobs nonotes nolines nonumbers nomtitles 	 						///
							starlevels(* 0.10 ** 0.05 *** 0.01)		

	}

	local c = `c' + 1

}	


if "$otables" != "" copy "$otables/rd_robu_091326.tex" "$tables/rd_robu_091326.tex", replace   // 2026-09-13: project copy
