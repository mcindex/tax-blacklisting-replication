* D03_eu_lists_F03.do  |  EU scoreboard + grey/blacklist panel to Feb 2022 (BLp, EU_BL*, BL_firstyear) + FIGURE 3 time_blgl_032522.png
* Copied unchanged from do/blacklist_data_032522.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* This .do file assembles all tax-specific policy and blacklisting outcomes for the IJ analysis

* Paths set by setup.do / master.do
* global input  "$project\input"
* global output "$project\output"
* global do     "$project\do"



* Kountry add
*kountryadd "China, Hong Kong SAR" to "Hong Kong" add
*kountryadd "Lao People's Dem. Rep." to "Laos" add
*kountryadd "China, Macao SAR" to "Macao" add
*kountryadd "Dem. Rep. of the Congo" to "Democratic Republic of Congo" add
*kountryadd "Cabo Verde" to "Cape Verde" add
*kountryadd "CuraÃ§ao" to "Curacao" add
*kountryadd "occupied Palestinian territory" to "Palestine" add
*kountryadd "Korea, Dem. People's Rep. of" to "North Korea" add
*kountryadd "Vatican City State" to "Vatican" add
*kountryadd "Bonaire, Sint Eustatius and Saba" to "Bonaire" add
*kountryadd "Saint Helena, Ascension and Tristan da Cunha" to "Saint Helena" add
*kountryadd "Macao SAR" to "Macao" add 
*kountryadd "Eswatini"  to "Swaziland" add
*kountryadd "Turks and Turks and Caicos Islands" to "Turks and Caicos Islands" add
*kountryadd "Granada" to "Grenada" add 
*kountryadd "North Macedonia" to "Macedonia" add 



**************
* Blacklists *
**************

* 1. 2015 EU blacklsit - released 17th of June

* Loading list of those on tax haven list
import excel "$input\EU_2015_blacklist.xlsx", sheet("Sheet1") firstrow clear

* Loading ISO codes
kountry Country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace        iso3 = "GGY" if Country == "Guernsey"
replace        iso3 = "MHL" if Country == "Marshall Isladns"
replace        iso3 = "SYC" if Country == "Secyhelles"
replace        iso3 = "NRU" if Country == "Naurau"
replace        iso3 = "VUT" if Country == "Vaunuatu"

* Setting treated periods (just one off)
gen year    = 2015
gen quarter = quarterly("2015q2","YQ")
gen month   = monthly("2015m6","YM")

* Saving to hd 
save "$output\EU_2015_blacklist.dta", replace

* 2. 2016 EU releases conditions to be considered for blacklist
import delimited "$input\eu_scoreboard_final.csv", varnames(1) clear
foreach var of varlist strength_of_ties magnitude_of_activity stability_factors {
	replace `var' = trim(`var')
	replace `var' = "" if `var' == ".."
}
destring strength_of_ties magnitude_of_activity stability_factors,  replace

foreach var of varlist risk_transparency preferential_regime no_cit {
	replace `var' = trim(`var')
	replace `var' = "1" if `var' == "X" 
}
destring  risk_transparency preferential_regime no_cit, replace

* ISO codes
replace country = trim(country)
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3


replace iso3 = "CUW" if country == "Curacao"
replace iso3 = "GGY" if country  == "Guernsey"
replace iso3 = "IMN" if country  == "Isle of Man"
replace iso3 = "JEY" if country  == "Jersey"
replace iso3 = "RKS" if country  == "Kosovo*"
replace iso3 = "MNP" if country  == "Northern Mariana Islands"
replace iso3 = "SXM" if country  == "Sint Maarten (Dutch part)"
replace iso3 = "ALA" if country  == "Ãland Islands"
replace iso3 = "BES" if country  == "Bonaire, Sint Eustatius and Saba"
replace iso3 = "BVT" if country  == "Bouvet Island"
replace iso3 = "IOT" if country  == "British Indian Ocean Territory"
replace iso3 = "CPT" if country  == "Clipperton"
replace iso3 = "HMD" if country  == "Heard Island and McDonald Islands"
replace iso3 = "LAB" if country  == "Malaysia / Labuan Island"
replace iso3 = "NFK" if country  == "Norfolk Island"
replace iso3 = "PCN" if country  == "Pitcairn Islands"
replace iso3 = "SGS" if country  == "South Georgia and the South Sandwich Islands"
replace iso3 = "TKL" if country  == "Tokelau"
replace iso3 = "UMI" if country  == "United States Minor Outlying Islands"
replace iso3 = "MAC" if country == "China, Macao SAR"

* Saving criteria to disk
save "$output/EU_criteria_2016.dta", replace

* Setting treated periods (just one off) and saving
gen treated_scored = status == "Selected"
gen year    = 2016
gen quarter = quarterly("2015q3","YQ")
gen month   = monthly("2015m9","YM")

* Saving to hd
drop if iso3 =="" 
keep iso3 year quarter month treated_scored
save "$output\EU_2016_scored.dta", replace


* 3. Actual EU blacklist panel
import excel "$input\EU_BLGL_050322.xlsx", sheet("Sheet1") firstrow clear
split Country, parse(,)
replace Country1 = trim(Country1)
kountry Country1, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3

replace iso3 = "GRD" if Country1 == "Granada"
replace iso3 = "CUW" if Country1 == "Curacao"
replace iso3 = "GGY" if Country1  == "Guernsey"
replace iso3 = "IMN" if Country1  == "Isle of Man"
replace iso3 = "JEY" if Country1  == "Jersey"
replace iso3 = "MAC" if Country1  == "Macao SAR"
replace iso3 = "LAB" if Country1 == "Labuan Island"

save "$output\EU_BL_full_list.dta", replace

keep Date iso3 List
drop if iso3 == ""

* Saving to hd 
duplicates drop iso3 Date List, force
save "$output\EU_BL.dta", replace

* Saving just treated countries (in first round)
keep if Date == 21158
gen blacklisted = List == "BL"
gen greylisted  = List == "GL"
keep iso blacklisted grey
save "$output\EU_BL_list.dta", replace

* Creating panel for analysis over time
use "$output\EU_BL.dta", clear
gen listed_ = 1
reshape wide listed_, i(iso3 Date) j(List) string
reshape wide listed_BL listed_GL, i(iso3) j(Date) 
save "$output/EU_BL_panel_full.dta", replace

* Creating true panel
use "$output\EU_BL.dta", clear
gen listed_ = 1
duplicates drop
reshape wide listed_, i(iso3 Date) j(List) string
gen quarter = qofd(Date)
sort iso3 quarter Date
by iso3 quarter: keep if _n == 1
keep iso3 quarter listed*

gen status = ""
replace status = "Greylisted" if listed_GL == 1
replace status = "Blacklisted" if listed_BL == 1
replace status = "Neither" if listed_GL == 0 & listed_BL == 0 
tempfile ll 
save    `ll', replace 

* Filling in gaps 
keep iso3 
duplicates drop
expand 6
gen quarter = . 
bys iso3: replace quarter = 234 if _n ==1 
bys iso3: replace quarter = 238 if _n ==2
bys iso3: replace quarter = 241 if _n ==3
bys iso3: replace quarter = 242 if _n ==4
bys iso3: replace quarter = 245 if _n ==5
bys iso3: replace quarter = 246 if _n ==6
append using `ll'
sort iso3 quarter
by iso3 (quarter): carryforward status, replace
replace listed_GL = 1 if status == "Greylisted"
replace listed_BL = 1 if status == "Blacklisted"

save "$output\BLp.dta", replace

* Creating true monthly
use "$output\EU_BL.dta", clear
gen listed_ = 1
duplicates drop
reshape wide listed_, i(iso3 Date) j(List) string
gen month= mofd(Date)
sort iso3 month Date
by iso3 month: keep if _n == 1
keep iso3 month listed*
save "$output\BLp_m.dta", replace


* Creating annual of first time ever BL or GL 
use  "$output\BLp.dta", clear 
bys iso3 listed_BL (quarter): gen fBL = 1 if _n == 1 & listed_BL == 1
bys iso3 listed_GL (quarter): gen fGL = 1 if _n == 1 & listed_GL == 1
keep if fGL ==1 | fBL ==1
gen year = yofd(dofq(quarter))
drop quarter

gen year_bl = year if fBL == 1 
gen year_gl = year if fGL == 1
collapse (max) year*, by(iso3)

save "$output\BL_firstyear.dta", replace 

exit


* Generating graphs on who is on blacklist over time
use "$output\EU_BL_full_list.dta", clear
gen num_BL = List == "BL"
gen num_GL = List == "GL"

collapse (sum) num_BL num_GL, by(Date)

* Blog
twoway (line num_BL Date, lwidth(medthick))          ///
	   (line num_GL Date, sort lwidth(medthick))     ///
	   , ytitle(Number of jurisdictions) xtitle("")  ///
	     xlabel(21185 21366 21550 21731 21915)       ///
		 legend(order(1 "Blacklist" 2 "Greylist")  region(fcolor("250 250 250") lcolor("250 250 250")))   ///
		 scheme(modern_dark) xsize(8) scale(1.3) ///
	   graphregion(fcolor("250 250 250") lcolor("250 250 250")) 	
graph export "$ographs\time_blgl_blog.png", replace width(3000)

twoway (line num_BL Date, lcolor(black) lwidth(medthick))          ///
	   (line num_GL Date, lcolor(blue) sort lwidth(medthick))     ///
	   , ytitle(Number of jurisdictions) xtitle("")  ///
	     xlabel(21185 21366 21550 21731 21915 22281 22646 22097 22462)       ///
		 legend(order(1 "Blacklist" 2 "Greylist"))   ///
		 scheme(modern) xsize(8) scale(1.3)
graph export "$ographs\time_blgl_032522.png", replace width(3000)


* Presentation
graph set window fontface "Fira Sans Light"	
twoway (line num_BL Date, lwidth(medthick))          ///
	   (line num_GL Date, sort lwidth(medthick))     ///
	   , ytitle(Number of jurisdictions) xtitle("")  ///
	     xlabel(21185 21366 21550 21731 21915 22097)       ///
		 legend(order(1 "Blacklist" 2 "Greylist")  region(fcolor("250 250 250") lcolor("250 250 250")))   ///
		 scheme(modern) xsize(8) scale(1.3) ///
	   graphregion(fcolor("250 250 250") lcolor("250 250 250"))  plotregion(fcolor("250 250 250") lcolor("250 250 250"))
graph export "$ographs\time_blgl_pres.png", replace width(3000)


* Strength = 599 
* magnitude = 374
* stability = 697




keep if status == "Selected" | status == "Not Selected"
gen selected = status == "Selected"

* Generating euclidian distance
egen order = rownonmiss(strength magnitude stability)

* Gen EC
gen EC = (strength - 600)^2 + (magnitude - 375)^2 + (stability - 698)^2 if order == 3
replace EC = (strength - 600)^2 + (magnitude - 375)^2 if strength != . & magnitude !=. & stability == . 
replace EC = (magnitude - 375)^2 + (stability - 698)^2 if strength == . & magnitude !=. & stability != . 
replace EC = (strength - 600)^2 + (stability - 698)^2 if strength != . & magnitude ==. & stability != . 

replace EC = (strength - 600)^2  if strength != . & magnitude ==. & stability == . 
replace EC = (magnitude - 375)^2  if strength == . & magnitude !=. & stability == . 
replace EC = (stability - 698)^2  if strength == . & magnitude ==. & stability != . 

gen ED_abs = sqrt(EC)

gen ED = ED_abs
replace ED = -1*ED if strength > 600 & strength != . 
replace ED = -1*ED if magnitude > 375 & magnitude != . 
replace ED = -1*ED if stability > 698 & stability != .
