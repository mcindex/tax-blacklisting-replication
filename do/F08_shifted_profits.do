* F08_shifted_profits.do  |  FIGURE 8 (f:zucmanblack) profits booked in havens
* 2026-09-13 (author): every jurisdiction in the TWZ Atlas file is kept (the Atlas reports shifted profits only for
* the Wier-Zucman haven list: Hines-Rice plus NLD, BEL, PRI); the Johannesen-Zucman restriction dropped CUW, SXM and BES
* Copied unchanged from do/weir_inport_090425.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* EU States
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
assert iso3 != ""
tempfile e
save    `e', replace


* Preparing data for those ever blacklist/greylisted
use "$output\EU_BL_full_list.dta", clear
gen BL = List == "BL"
gen GL = List == "GL"

* Keeping only those BL/GListed before the middle of 2018
keep if Date <= date("06/01/2018","MDY")

collapse (max) BL GL, by(iso3)
count
tab BL
replace GL = 0 if BL == 1


tempfile bb
save    `bb', replace 


import excel "$input\zm_updated.xlsx", sheet("Sheet1") firstrow clear
drop in 1


	kountry A, from(other) stuck
	rename _ISO3N_ numcode
	kountry numcode, from(iso3n) to(iso3c) m
	drop NAMES_STD MARKER numcode
	rename _ISO3C_ iso3


	replace iso3 = "GGY" if A == "Guernsey"
	replace iso3 = "JEY" if A == "Jersey"
	replace iso3 = "IMN" if A == "Isle of Man"
		replace iso3 = "IMN" if A == "Isle of man"
			replace iso3 = "BES" if A == "Bonaire"
				replace iso3 = "SXM" if A == "Sint Maarten"
	replace iso3 = "CUW" if A == "Curacao"
	replace iso3 = "MAC" if A == "Macau China"
	replace iso3 = "VGB" if A == "BVI"
drop if iso3 == ""
	
	assert  iso3 != ""
	
	rename E year
	
save "$output\shifted_profits.dta", replace 


import excel "$input\Profit shifting - Nov 2024.xlsx", sheet("Sheet1") firstrow clear
keep if counterpart =="World"
reshape wide value, i(iso3 year) j(indicator) string
keep iso3 year valueshifted_profits valuetax_gain_share_of_CITrev
mmerge iso3 using `bb', type(n:1) unmatched(master)
gen status = "Ever blacklisted" if BL == 1
replace status = "Ever greylisted" if GL == 1
replace status = "Neither" if  BL == . & GL == .

* Bringing in selected status 
	
	mmerge iso3 using "$output\rd_sample_020922.dta", type(n:1) unmatched(master) ukeep(blacklisted greylisted distance* selected reviewed)
	mmerge iso3 using "$input\zucman_haven.dta", type(n:1) unmatched(master)
	gen haven = _merge == 3
	mmerge iso3 using `e', type(n:1) unmatched(master)
	gen eu = _merge == 3
	*keep if haven == 1
	
	
* keep if haven == 1   // 2026-09-13: dropped (author) -- Atlas jurisdictions = Wier-Zucman havens; `haven' (J&Z) kept for the log only
qui levelsof iso3, local(LA) clean
di as txt "Atlas jurisdictions in the figure: `: word count `LA'' -- `LA'"
list iso3 status haven if year == 2019 & haven == 0, noobs clean
* Original line below dropped status/haven variables before the next collapse needed them
* collapse (sum) valueshifted_profits (mean) valuetax_gain_share_of_CITrev, by(eu year)

collapse (sum) valueshifted_profits (mean) valuetax_gain_share_of_CITrev, by(status year)   // 2026-09-13: was by(status year haven) + drop if haven == 0

twoway (connected  valueshifted_profits year if status == "Ever blacklisted",     mcolor(black) mfcolor(black) mlcolor(%0) lcolor(black)) ///
	   (connected  valueshifted_profits year if status == "Ever greylisted" == 1, mfcolor(black%50) mlcolor(%0) lcolor(black%50))         ///
	   (connected  valueshifted_profits year if status == "Neither", mcolor(blue%80) mlcolor(%0) lcolor(blue%80))						   ///
	   , ytitle("Profits, billions USD") yline(0)			///
	     xtitle(" ") 															///
		 legend(order(1 "Ever-blacklisted" 2 "Ever-greylisted (but never blacklisted)" 3 "Neither") ///
		 position(6) rows(3)) xsize(10) ysize(8) name(g1, replace)				///
		 scale(1.2) xline(2017)	///
		   ttext(550 2016.3 "Listing begins", size(vsmall))
		   
		   
graph export "$ographs\haven_profits_090925.png", replace width(3000) 
