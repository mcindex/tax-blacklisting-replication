* A_fig_deficiency_letters.do  |  APPENDIX f:deficiency, f:deficiency2 + builds cocg_letters_091026.dta (needed by T03) - runs first [effort_outcome_* panels now _091326]
* 2026-09-15: BUG FIX, figure loop wrapped in preserve/restore (binned rows appended for one outcome became fake zero observations for the next); panels c_2 c_4 c_7 dropped (not in the appendix); dead code removed
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/deficiencies_011921.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* Deficiency analysis 
* URL: https://www.consilium.europa.eu/media/33087/compilation-of-letters-seeking-commitment.pdf


import excel "$input\committment_data.xlsx", sheet("Sheet1") firstrow clear


* Bar graph of deficiencies
replace Criteria = "Automatic Exchange of Information" if Criteria == "AEOI"
replace Criteria = "Offshore Structures" if Criteria == "Offshore Strucutres"
replace Criteria = "Global Forum Membership" if Criteria == "Join Global Forum"
replace Criteria = "Inclusive Framework Membership" if Criteria == "Inclusive Framework"
replace Criteria = "Multilateral Convention (MCAA) Commitment" if Criteria == "MCMAA"

tostring Code, replace
gen name = Code + " - " + Criteria
gen num = 1
bys Criteria: gen size = _N

* Paper
graph hbar (sum) num, over(name, sort(size) descending) ytitle(Number of deficiencies found)
* [off 2026-09-12] graph export "$ographs\deficiencies.png", replace width(3000) 

* Presentation
graph set window fontface "Fira Sans Light"			
graph hbar (sum) num, over(name, sort(size) descending) ytitle(Number of deficiencies found, color("0 40 40")) ///
		graphregion(fcolor("250 250 250") lcolor("250 250 250")) 										  ///
		plotregion(fcolor("250 250 250") lcolor(%0))    						  ///
		scheme(modern)	///
		title(Deficiencies raised by EU in communication with selected jurisdictions, color("0 40 40")) ///
		xsize(8)
* [off 2026-09-13 (coherence review fix)] graph export "$ographs\deficiencies_pres.png", replace width(3000) 
graph set window fontface default
*/


* Are identified deficiencies common near cutoffs? 

* Formatting iso codes
kountry Jurisdiction, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3

replace        iso3 = "CUW" if Jurisdiction == "Curacao"
replace        iso3 = "GGY" if Jurisdiction == "Guernsey"
replace        iso3 = "HKG" if Jurisdiction == "Hong Kong SAR"
replace        iso3 = "IMN" if Jurisdiction == "Isle of Man"
replace        iso3 = "JEY" if Jurisdiction == "Jersey"
replace        iso3 = "MAC" if Jurisdiction == "Macao SAR"
replace        iso3 = "NIU" if Jurisdiction == "Nieu"
replace        iso3 = "CPV" if Jurisdiction == "Cabo Verde"   // 2026-09-10

* 2026-09-10: jurisdictions whose name did not resolve to an ISO code (listed, then dropped)
list Jurisdiction Criteria if iso3 == ""
drop if iso3 == ""


keep iso3 Criteria
duplicates drop

encode Criteria, gen(cname)
tab cname
tab cname, nolabel
drop Criteria
gen c_ = 1
reshape wide c_, i(iso3) j(cname) 

label var c_1 "aeoi"
label var c_2 "beps"
label var c_3 "global forum"
label var c_4 "harmful"
label var c_5 "inclusive framework"
label var c_6 "mcaa"
label var c_7 "offshore"


* 2026-09-10 (R&R): save the COCG deficiency-letter indicators for Table 3 (rr_table3_sharp_euc_090926.do)
save "$output/cocg_letters_091026.dta", replace
* 2026-09-10 (R&R): frozen PRI-fixed file, rule-eligible sample, Euclidean distance, outputs under new names
mmerge iso3 using "$output/regready_042822_gdp2026_frozen20260820.dta", type(1:1) unmatched(using)
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
foreach var of varlist c_* {
    replace `var' = 0 if `var' == . 	
}
egen c_8 = rmax(c_4 c_7)
egen any_letter = rmax(c_*)


* Panels in the online appendix: any letter and categories 1, 3, 5, 6, 8 (2, 4 and 7 are not shown)
foreach o in any_letter c_1 c_3 c_5 c_6 c_8 {
	* preserve / restore: every outcome starts from the same data. (Until 2026-09-15 the binned rows appended
	* below stayed in memory, and the next outcome's "replace = 0 if missing" turned them into fake observations.)
	preserve
	
	* RD effect
	replace `o' = 0 if `o' == . 
	cap drop w
	rdrobust `o' distance, p(1) kernel(triangular) masspoints(off)   // 2026-09-10: masspoints(off) added
	
	di "Bandwidths are `e(h_l)' and `e(b_l)' "
		assert e(h_l) < 72
		assert  e(b_l)  < 72

	
	local bandwidth = e(h_l)
	gen w = . 
	replace w = (1-abs(distance / `bandwidth')) if distance < 0 & distance >= -`bandwidth'
	replace w = (1-abs(distance / `bandwidth')) if distance >= 0 & distance <= `bandwidth'
	cap drop rdplot*
	rdplot `o' distance if abs(distance)<=`bandwidth', hide genvars p(1) masspoints(off)
	
	
	twoway (lfitci `o' distance if distance < 0  & abs(distance)<=`bandwidth' , level(95) estopts(robust))						   ///
		   (lfitci `o' distance if distance >= 0 & abs(distance)<=`bandwidth' , level(95) estopts(robust) lcolor(navy) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth'), xline(0)													   ///
			 ytitle(Pr(letter sent))      																					   ///
		   xtitle(Distance to cutoff)					   																						   ///
		   legend(off)																															   ///
		   name(s1, replace) 																													   ///
		   scale(1.3) 
		   graph export "$ographs\effort_outcome_`o'_091326.png", replace width(2000)
		 graph export "$graphs\effort_outcome_`o'_091326.png", replace width(2000)  
		   
	
	graph set window fontface "LM Roman 10"
		   

	* Binscatter/lpoly	   
	cd "$output"
	binscatter `o' distance, rd(0) savedata(d) replace
	* binned means from binscatter, appended as extra rows for the scatter layer only
	tempfile cur d
	save `cur', replace
	import delimited "$output/d.csv", encoding(ISO-8859-2) clear
	rename `o' b_`o'
	save `d', replace
	use `cur', clear
	append using `d'
	twoway (lpolyci `o'   distance if distance >=0) 												  ///
		   (lpolyci `o'   distance if distance < 0 & distance > -75, lcolor(navy) alcolor(%0)) ///
		   (scatter b_`o' distance, mcolor(blue%50) mlcolor(blue%0)) 									  ///
		   , ytitle(Probability(flagged)) 										///
		     yline(0, lpattern(solid) lcolor(black))						    ///
			 xtitle(Distance to cutoff) xline(0) legend(off) 					///
		     xline(0, lwidth(23.3) lc(navy%15) lpattern(solid))  		        ///
			 scale(1.3)
	gr_edit .xaxis1.plotregion.xscale.curmin = -74.2
	graph export "$ographs\effort_outcome_`o'2_091326.png", replace width(2000)
	graph export "$graphs\effort_outcome_`o'2_091326.png", replace width(2000)

	restore
}
