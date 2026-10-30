* A_fig_effort_havens_hrm.do  |  APPENDIX f:risky, f:haventest, f:effort (hrm1-3) [effort_outcome_* panels now _091326]
* 2026-09-15: BUG FIX, figure loops wrapped in preserve/restore (binned rows appended for one outcome became fake zero observations for the next outcome's RD panel); dead code removed
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/effort_011921.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* This .do file invesitgates two things: 

* (1) Levels of EU-identified problems 

* (2) 3rd party measures of `tax havenness'


*************************
* Loading external data *
*************************

* Conduit and sink OFCs from (https://www.nature.com/articles/s41598-017-06322-9)
import   excel "$input\sink_ofcs.xlsx", sheet("Sheet1") firstrow clear
kountry  ISO2, from(iso2c) to(iso3c) m
drop     NAMES_STD MARKER 
replace  _ISO3C_ = "JEY" if ISO2 == "JE"
replace  _ISO3C_ = "CUW" if ISO2 == "CW"
assert   _ISO3C != ""
tempfile sink
save    `sink', replace


* The 2015 EU blacklist
import excel "$input\EU_2015_blacklist.xlsx", sheet("Sheet1") firstrow clear

kountry Country, from(other) stuck
rename  _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop     NAMES_STD MARKER numcode
rename  _ISO3C_ iso3
replace iso3 = "SXM"  if Country == "Sint Maarten"
replace iso3 = "CUW"  if Country == "Curacao"
replace iso3 = "GGY"  if Country == "Guernsey"
replace iso3 = "JEY"  if Country == "Jersey"
replace iso3 = "IMN"  if Country == "Isle of Man"
replace iso3 = "MAC"  if Country == "Macau China"
replace iso3 = "CUW"  if Country == "Curaao"
replace iso3 = "SPM" if Country == "Saint-Pierre and Miquelon"
replace iso3 = "SHN" if Country == "St Helena and Dependencies"
replace iso3 = "MYS" if substr(Country,1,5) == "Malay"
replace iso3 = "VGB" if Country == "British Virgin"
replace iso3 = "VGB" if Country == "Islands"
replace iso3 = "CZE" if substr(Country,1,5) == "CZECH"
replace iso3 = "TTO" if substr(Country,1,5) == "Trini"
replace iso3 = "WLF" if substr(Country,1,5) == "Walli"
replace iso3 = "MKD" if substr(Country,1,17) == "Republic of North"
replace iso3 = "MHL" if Country == "Marshall Isladns"
replace iso3 = "NRU" if Country == "Naurau"
replace iso3 = "SYC" if Country == "Secyhelles"
replace iso3 = "VUT" if Country == "Vaunuatu"
assert iso3 != ""
tempfile oldlist
save    `oldlist'


* Zucman's list of tax havens
import delimited "$input\zucman_havens.csv", varnames(1) clear   // 2026-09-10: was a hardcoded D:\ path
replace iso3 = "VGB" if iso3 == "BVI"   // 2026-09-13: the csv codes the British Virgin Islands BVI
tempfile taxhaven
save    `taxhaven', replace


* Loading RD sample
* 2026-09-10 (R&R): frozen PRI-fixed file (full sample here; Part 1 restricts
* to the rule-eligible sample); Euclidean distance throughout; outputs under new names
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
* (identified_cocg, identified_oecd, any_harmful are carried under those names in the frozen file)

* Merging in other data
mmerge iso3 using `taxhaven', type(1:1) 
gen haven = _merge != 1
mmerge iso3 using `oldlist', type(1:1) 
gen oldlist = _merge != 1
mmerge iso3 using `sink', type(1:1) unmatched(master) umatch(_ISO3C_)
gen sink = _merge != 1

save "$output\haveninfo_091026.dta", replace   // 2026-09-10: new name; rank.do still reads the 2021 haveninfo.dta
**********
* Part 1 *
**********

* Drawing RD graphs of liklihood of being designated as * risk of transparency, preferencial regime or no_cit, and showing probabilities across the distribution


gen distance_e = distance if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; 2026-09-10: rule-eligible sample for the RD-style panels (missing = excluded)
foreach o in risk_transparency preferential_regime no_cit {   // 2026-09-10: greylist/blacklist dropped (not in the data; not in the appendix)
	* preserve / restore: every outcome starts from the same data. (Until 2026-09-15 the binned rows appended
	* below stayed in memory, and the next outcome's "replace = 0 if missing" turned them into fake observations.)
	preserve
	
	* RD effect
	replace `o' = 0 if `o' == . 
	cap drop w
	rdrobust `o' distance_e, p(1) kernel(triangular) masspoints(off)
		assert e(h_l) < 72
				assert  e(b_l)  < 72

	
	local bandwidth = e(h_l)
	gen w = . 
	replace w = (1-abs(distance_e / `bandwidth')) if distance_e < 0 & distance_e >= -`bandwidth'
	replace w = (1-abs(distance_e / `bandwidth')) if distance_e >= 0 & distance_e <= `bandwidth'
	cap drop rdplot*
	rdplot `o' distance_e if abs(distance_e)<=`bandwidth', hide genvars p(1)

	twoway (lfitci `o' distance_e if distance_e < 0  & abs(distance_e)<=`bandwidth' , level(95) estopts(robust))						   ///
		   (lfitci `o' distance_e if distance_e >= 0 & abs(distance_e)<=`bandwidth' , level(95) estopts(robust) lcolor(navy) alcolor(%0)) ///
		   (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <=`bandwidth'), xline(0)													   ///
			 ytitle(Pr(flagged))      																					   ///
		   xtitle(Distance to cutoff)					   																						   ///
		   legend(off)																															   ///
		   name(s1, replace) 																													   ///
		   scale(1.3) 
		   graph export "$ographs\effort_outcome_`o'_091326.png", replace width(2000)
		 graph export "$graphs\effort_outcome_`o'_091326.png", replace width(2000)  
		   
		   
	* Binscatter/lpoly	   
	cd "$output"
	binscatter `o' distance_e, rd(0) savedata(d) replace
	* binned means from binscatter, appended as extra rows for the scatter layer only
	tempfile cur d
	save `cur', replace
	import delimited "$output/d.csv", encoding(ISO-8859-2) clear
	rename `o' b_`o'
	save `d', replace
	use `cur', clear
	append using `d'
	twoway (lpolyci `o'   distance_e if distance_e >=0) 												  ///
		   (lpolyci `o'   distance_e if distance_e < 0 & distance_e > -75, lcolor(navy) alcolor(%0)) ///
		   (scatter b_`o' distance_e, mcolor(blue%50) mlcolor(blue%0)) 									  ///
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


**********
* Part 2 *
**********

* Drawing local polynomial estimates of pre-existing tax haven indicators

foreach o in oldlist haven sink {
	* preserve / restore: every outcome starts from the same data. (Until 2026-09-15 the binned rows appended
	* below stayed in memory, and the next outcome's "replace = 0 if missing" turned them into fake observations.)
	preserve
	
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
	graph export "$ographs\haven_outcome_`o'_091026.png", replace width(2000)
	graph export "$graphs\haven_outcome_`o'_091026.png", replace width(2000)

	restore
}


*******************************
* Part 3  - EU review effort  *
*******************************
gen harmful_cocg    = (any_harmful  == 1 & identified_cocg ==1 )
cap gen harmful_oecd  = (any_harmful  == 1 & identified_oecd ==1 ) | (harmful == 1 & reviewed == 1) 

twoway (lpolyci identified_cocg distance if distance < 0, lcolor(cranberry) fcolor(red%50) alcolor(%0)) ///
       (lpolyci identified_oecd distance if distance >=0,  lcolor(navy) alcolor(%0))                                               ///
	   (lpolyci identified_oecd distance if distance < 0, lcolor(navy) alcolor(%0))                     ///
	   (lpolyci identified_cocg distance if distance >=0, lcolor(cranberry) fcolor(red%30) alcolor(%0)) ///
	   if abs(distance) < 75              																	  ///
	   , ytitle(Pr(Regime is reviewed))											///
	     yline(0, lpattern(solid) lcolor(black)) 								///
		 xtitle(Distance to cutoff) 											///
		 xscale(range(-75 53)) xline(0) 									///
		 xline(14 -14, lpattern(solid) lcolor(black%20)) ///
		 legend(order(6 "OECD FHTP" 2 "EU COCG") rows(1) position(6))	///
			 scale(1.3) ///
			 text(1.1 0  "RD bandwidth range", place(c) lcolor(black%30) size(vsmall))
gr_edit .xaxis1.plotregion.xscale.curmin = -74.2
graph export "$ographs\hrm1_091026.png", replace width(2000)
graph export "$graphs\hrm1_091026.png", replace width(2000)

twoway (lpolyci identified_cocg z_distance if z_distance < 0, lcolor(cranberry) fcolor(red%50) alcolor(%0)) ///
       (lpolyci identified_oecd z_distance if z_distance >=0,  lcolor(navy) alcolor(%0))                                               ///
	   (lpolyci identified_oecd z_distance if z_distance < 0, lcolor(navy) alcolor(%0))                     ///
	   (lpolyci identified_cocg z_distance if z_distance >=0, lcolor(cranberry) fcolor(red%30) alcolor(%0)) ///
	   if abs(z_distance) < 69              																	  ///
	   , ytitle(Pr(Regime is reviewed))											///
	     yline(0, lpattern(solid) lcolor(black)) 								///
		 xtitle(Distance to cutoff) 											///
		 xscale(range(-29.5 69)) xline(0) 									///
		 xline(10 -10, lpattern(solid) lcolor(black%20)) ///
		 legend(order(6 "OECD FHTP" 2 "EU COCG") rows(1) position(6))	///
			 scale(1.3) ///
			 text(1.1 0  "RD bandwidth range", place(c) lcolor(black%30) size(vsmall))
gr_edit .xaxis1.plotregion.xscale.curmin = -30
graph export "$ographs\hrm2_091026.png", replace width(2000)
graph export "$graphs\hrm2_091026.png", replace width(2000)

twoway (lpolyci identified_cocg x_distance if selected ==1, lcolor(cranberry) fcolor(red%50) alcolor(%0)) ///
       (lpolyci identified_oecd x_distance if selected ==1,  lcolor(navy) alcolor(%0))                                               ///
	    , ytitle(Pr(Regime is reviewed))											///
	     yline(0, lpattern(solid) lcolor(black)) 								///
		 xtitle(Strength of ties with the EU (distance from cutoff)) 											///
		 xscale(range(0 69)) xline(0) 									///
		 legend(order(4 "OECD FHTP" 2 "EU COCG") rows(1) position(6))	///
			 scale(1.3) 
graph export "$ographs\hrm3_091026.png", replace width(2000)
graph export "$graphs\hrm3_091026.png", replace width(2000)
gr_edit .xaxis1.plotregion.xscale.curmax = 60
