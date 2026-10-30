* D05_rd_sample.do  |  RD sample assembly -> rd_sample_032522.dta [World Bank series frozen; live with wb_refresh 1]
* 2026-10-30: the four World Bank series in section 0 are read from frozen copies of the March 2022 pull
* (output/wb_frozen_d05_*_032522.dta, made by do/freeze_wb_vintages.do); global wb_refresh 1 pulls them live.
* Copied unchanged from do/rd1_042822.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************

*************************************************************************************************************
* This file assembles data needed for RD estimates of the impact of grey/black listing on economic outcomes *
*************************************************************************************************************


*****************
* 0 - Data prep *
*****************

* Preparing other outcome data in `wide' form 
if "$wb_refresh" == "1" wbopendata, indicator(si.pov.dday)         clear year(2010:2018)
else use "$output/wb_frozen_d05_pov_032522.dta", clear
forvalues t = 2010/2018 {
	rename yr`t' pov_`t'
	lab var pov_`t' "Poverty rate in year `t'"
}
tempfile pov
save    `pov', replace


if "$wb_refresh" == "1" wbopendata, indicator(ny.gdp.pcap.pp.kd)   clear year(2010:2018)
else use "$output/wb_frozen_d05_gdppc_032522.dta", clear
forvalues t = 2010/2018 {
	rename yr`t' gdppc_`t'
	gen    lngdppc_`t' = ln(gdppc_`t')
	lab var   gdppc_`t' "GDP per capita in year `t'"
	lab var lngdppc_`t' "Log(GDP per capita) in year `t'"
}
tempfile gdppc
save    `gdppc', replace   // 2026-10-30: was `gdpc' (undefined), which saved over the file in memory


if "$wb_refresh" == "1" wbopendata, indicator(ny.gdp.pcap.cd)   clear year(2010:2018)
else use "$output/wb_frozen_d05_gdppcn_032522.dta", clear
forvalues t = 2010/2018 {
	rename yr`t' gdppcn_`t'
	gen    lngdppcn_`t' = ln(gdppcn_`t')
	lab var   gdppcn_`t' "GDP per capita in year `t'"
	lab var lngdppcn_`t' "Log(GDP per capita) in year `t'"
}
tempfile gdppcn
save    `gdppcn', replace

if "$wb_refresh" == "1" wbopendata, indicator(bx.klt.dinv.wd.gd.zs) clear year(2010:2018)
else use "$output/wb_frozen_d05_fdi_032522.dta", clear
forvalues t = 2010/2018 {
	rename yr`t' fdi_`t'
	gen    lnfdi_`t' = ln(fdi_`t')
	lab var fdi_`t' "FDI (as % of GDP) in year `t'"
	lab var lnfdi_`t' "Log [FDI (as % of GDP)] in year `t'"
}
tempfile fdi
save    `fdi', replace

* More FDI
import excel "$input\IMF_BOP_DI_NET_Q.xlsx", sheet("Quarterly") cellrange(A5:AG219) firstrow clear
foreach var of varlist Q1- Z{
	local v: variable label `var'
	rename `var' di_`v'
}
destring di_*, replace ignore(k K ... ",")

kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3

keep if iso3 != "" // *************** NEED TO FIX A FEW MORE COUNTRYNAMES
keep iso3 di_2016Q1 di_2017Q3 di_2018Q1 di_2018Q2
tempfile di 
save    `di', replace

*Oecd countries
import excel "$input\oecd.xlsx", sheet("Sheet1") clear
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
drop A
tempfile oecd
save    `oecd', replace

* *FSI
* 2015
import excel "$input\fsi.xlsx", sheet("Sheet1") firstrow clear
keep if year == 2015
keep ISO3 FinancialSecrecyIndexValueS SecrecyScore5 GlobalScaleWeightSourceFin 
drop if ISO3 == ""
gen lnfsi = ln(FinancialSecrecy)
lab var  FinancialSecrecyIndex "Financial Secrecy Index Score (2015)"
lab var  lnfsi				  "Log(Financial Secrecy Index Score (2015))"
lab var  SecrecyScore5         "Financial Secrecy Score (2015)"
destring SecrecyScore5, replace force
tempfile fsi15
save    `fsi15', replace

*2018
import excel "$input\FSI-Rankings-2018.xlsx", sheet("FSI Results") firstrow clear
replace Jurisdiction = subinstr(Jurisdiction, "2", "",.)
replace Jurisdiction = subinstr(Jurisdiction, "3", "",.)
replace Jurisdiction = trim(Jurisdiction)
drop if Jurisdiction == ""
kountry Jurisdiction, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "JEY" if Juris == "Jersey"
replace iso3 = "UAE" if Juris == "United Arab Emirates (Dubai),"
replace iso3 = "GGY" if Juris == "Guernsey"
replace iso3 = "IMN" if Juris == "Isle of Man"
replace iso3 = "CUW" if Juris == "Curacao"
drop                 if Juris == "Malaysia (Labuan)" | Juris == "Portugal (Madeira)"
assert  iso3 != ""
rename SecrecyScore SecrecyScore18
rename FSIValue     FSIValue18
gen    lnfsi18  = ln(FSIValue18)
keep iso3 Secrecy FSIValue lnfsi18

lab var  FSIValue "Financial Secrecy Index Score (2018*)"
lab var  lnfsi	  "Log(Financial Secrecy Index Score (2018*))"
lab var  Secrecy  "Financial Secrecy Score (2018*)"

tempfile fsi18
save    `fsi18', replace

* 2020 
import excel "$input\fsi_2020.xlsx", firstrow clear
replace Jurisdiction = subinstr(Jurisdiction, "2", "",.)
replace Jurisdiction = subinstr(Jurisdiction, "3", "",.)
egen cn = sieve(Jurisdiction), keep(a space)
drop Jurisdiction
rename cn Jurisdiction
replace Jurisdiction = trim(Jurisdiction)
drop if Jurisdiction == ""
kountry Jurisdiction, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "JEY" if Juris == "Jersey"
replace iso3 = "UAE" if Juris == "United Arab Emirates (Dubai),"
replace iso3 = "GGY" if Juris == "Guernsey"
replace iso3 = "IMN" if Juris == "Isle of Man"
replace iso3 = "CUW" if Juris == "Curacao"
drop                 if Juris == "Malaysia (Labuan)" | Juris == "Portugal (Madeira)"
assert  iso3 != ""
rename SecrecyScore SecrecyScore20
rename FSIValue     FSIValue20
rename Rank FSIrank_20
gen    lnfsi20  = ln(FSIValue20)
keep iso3 Secrecy FSIValue lnfsi20 FSIrank

lab var  FSIValue "Financial Secrecy Index Score (2020*)"
lab var  lnfsi	  "Log(Financial Secrecy Index Score (2020*))"
lab var  Secrecy  "Financial Secrecy Score (2020*)"

tempfile fsi20
save    `fsi20', replace

save "$output/fsi20.dta", replace

* EOIR
import excel "$input\eoir.xlsx", sheet("Sheet1") firstrow clear
egen cn = sieve(country), keep(a space)
replace cn = trim(cn)
replace cn = "Antigua and Barbuda" if cn == "Antigua and Barbuda ft"
kountry cn, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "JEY" if cn == "Jersey"
replace iso3 = "IMN" if cn == "Isle of Man"
replace iso3 = "CUW" if cn == "Curaao"
replace iso3 = "GGY" if cn == "Guernsey"
replace iso3 = "SXM" if cn == "Sint Maarten"
replace iso3 = "DMA" if cn == "Dominica ft"
replace iso3 = "MAC" if cn == "Macau China"
assert iso3 != ""
isid iso3
rename status eoir
keep iso3 eoir
tempfile eoir
save    `eoir', replace

* Cit rates
import delimited "$input\CTS_CIT_20052020215449889.csv", clear encoding("utf-8")

* Handle BOM in CSV header - variable may be named cou or ïcou depending on encoding
cap rename ïcou iso3
cap rename cou iso3
keep if corp_tax=="CIT_RATE"
rename value cit 
keep cit iso3 year
reshape wide cit, i(iso3) j(year)
tempfile cit
save    `cit', replace

* Corporate tax haven index
import excel "$input\CTHI2019.xlsx", sheet("Ranking") firstrow clear
replace Jurisdiction = subinstr(Jurisdiction, "2", "",.)
replace Jurisdiction = subinstr(Jurisdiction, "3", "",.)
replace Jurisdiction = trim(Jurisdiction)
drop if Jurisdiction == ""
kountry Jurisdiction, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "JEY" if Juris == "Jersey"
replace iso3 = "UAE" if Juris == "United Arab Emirates (Dubai),"
replace iso3 = "GGY" if Juris == "Guernsey"
replace iso3 = "IMN" if Juris == "Isle of Man"
replace iso3 = "CUW" if Juris == "Curacao"
drop                 if Juris == "Malaysia (Labuan)" | Juris == "Portugal (Madeira)"
assert iso3 != ""
rename HavenScore2 HavenScore
rename GlobalScale HavenWeight
rename CTHIValue   CTHIValue
gen    lncthi = ln(CTHIValue)
tempfile cthi19
save    `cthi19', replace



* List of jurisdictions actually reviewed by the COCG group
import excel "$input\reviewed_list.xlsx", sheet("Sheet1") clear
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "UAE" if A == "United Arab Emirates (Dubai),"
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curacao"
replace iso3 = "LAB" if A == "Malaysia/La buan Island"
replace iso3 = "LIE" if A == "Liechtenstei n"
assert iso3 != ""
keep iso3 
gen reviewed = 1
tempfile reviewed
save    `reviewed', replace



*************************************************
* Starting with the 2016 EU criteria list 
use "$output/EU_criteria_2016.dta", clear

replace iso3 = "PSE" if country == "occupied Palestinian territory"
replace iso3 = "CIV" if country == "CÃ´te d'Ivoire"
replace iso3 = "LAB" if country == "Malaysia / Labuan Island"					// made up iso for labuan 
drop if iso3 == ""		// Note this drops Labuan, for which there is no data 


* Merging in the blacklist/greylisted list 
mmerge iso3 using "$output\EU_BL_list.dta", type(1:1)

* Merging in the panel data
mmerge iso3 using "$output\EU_BL_panel_full.dta", type(1:1)
foreach var of varlist listed* {
	replace `var' = 0 if `var' == . 
} 

* Merging in outcome data 
mmerge iso3 using `fdi' 								    , type(1:1) unmatched(master) umatch(countrycode) ukeep(fdi* lnfdi*)				// FDI
mmerge iso3 using "$output/fdi_unctad_rdd.dta" 				, type(1:1) unmatched(master) umatch(iso3) 											// FDI (from UNCTAD)
mmerge iso3 using `gdppc'									, type(1:1) unmatched(master) umatch(countrycode) ukeep(gdppc* lngdppc*)			// GDP per capita
mmerge iso3 using `gdppcn'									, type(1:1) unmatched(master) umatch(countrycode) ukeep(gdppc* lngdppc*)			// GDP per capita, nominal current
mmerge iso3 using `pov'  									, type(1:1) unmatched(master) umatch(countrycode) ukeep(pov*)						// Poverty
mmerge iso3 using "$output/correspondent_decline_041219.dta", type(1:1) unmatched(master)														// Correspondent banking connections
mmerge iso3 using "$output/bis_rdd_041219.dta"				, type(1:1) unmatched(master)														// Data on BIS deposits
mmerge iso3 using "$output/bis2_rdd_061219.dta"				, type(1:1) unmatched(master)														// More BIS deposits
mmerge iso3 using `fsi15'									, type(1:1) unmatched(master) umatch(ISO3)											// Financial Secrecy Index (2015)
mmerge iso3 using `fsi18'								    , type(1:1) unmatched(master) umatch(iso3)											// Financial Secrecy Index (2018)
mmerge iso3 using `fsi20'								    , type(1:1) unmatched(master) umatch(iso3)											// Financial Secrecy Index (2018)
mmerge iso3 using `cthi19'								    , type(1:1) unmatched(master) umatch(iso3) ukeep(CTHIValue lncthi HavenScore HavenWeight) // Corporate tax haven index (2019)
mmerge iso3 using `di'										, type(1:1) unmatched(master) umatch(iso3) 
mmerge iso3 using "$output\aeoi_com_061019.dta"				, type(1:1) unmatched(master)														// AEOI Committments
mmerge iso3 using "$output\aeoi_com_033020.dta"				, type(1:1) unmatched(master)														// AEOI Committments

mmerge iso3 using "$output\aeoi_number_042722.dta"			, type(1:1) unmatched(master) umatch(f_iso3)										// CRS active sharing
foreach var of varlist num_relationships num_relationships_2017 num_EU_relationships num_EU_relationships_2017 f_EU per_EU_relationships {
	replace `var' = 0 if `var' == .
	rename `var' `var'_now
	
}
mmerge iso3 using "$output\crs_number_042120.dta"			, type(1:1) unmatched(master) umatch(f_iso3)										// CRS active sharing
foreach var of varlist *_relationships* {
replace `var' = 0 if `var' == . 
}
mmerge iso3 using "$output\if_participation.dta"			, type(1:1) unmatched(master)														// IF participation (Jan 2019)
gen if_participation = _merge == 3
foreach date in 051117 110517 041618 062419 040620 020922 {
	mmerge iso3 using "$output\map_profile_`date'.dta"			, type(1:1) unmatched(master)														// Publishing of MAP proviles
	replace map_`date' = 0 if _merge != 3
	replace map_committed_`date' = 0 if _merge != 3
}
mmerge iso3 using "$output\if_reshaped.dta"			, type(1:1) unmatched(master)					
foreach var of varlist ifp* {
	replace `var' = 0 if `var' == . 
}

mmerge iso3 using "$output\mil_adoption_033020.dta"			, type(1:1) unmatched(master)														// MIL adoption
mmerge iso3 using "$output\maa_adoption_033020.dta"			, type(1:1) unmatched(master)					  ukeep(maa maa_signed maa_date)	// MAA adoption
replace maa = 0 if maa == . 
mmerge iso3 using "$output\cbcr_122219.dta"					, type(1:1) unmatched(master)														// Signed up to CBR
replace cbcr_signed = 0 if _merge != 3

* IF participatino at different poitns in time
foreach k in 071516 060717 100117 050118 030119 103119 121519 {
	mmerge iso3 using "$output\if_participation`k'.dta"		, type(1:1) unmatched(master)
	gen if_participation_`k' = _merge == 3
}
* Global forum participation at different pointsin time
foreach k in 091516 111919 {
	mmerge iso3 using "$output\global_forum_`k'.dta"		, type(1:1) unmatched(master)
	gen gf_participation_`k' = _merge == 3
}

* Eurostat, etc balance data
mmerge iso3 using "$output\euro_balance.dta"		, type(1:1) unmatched(master) umatch(countrycode)

*Oecd
mmerge iso3 using `oecd', type(1:1) unmatched(master) 
gen oecd = _merge == 3

* Eoir
mmerge iso3 using `eoir', type(1:1) unmatched(master)

* cit
mmerge iso3 using `cit', type(1:1) unmatched(master)

* Harmfulregimes 
mmerge iso3 using  "$output/harm.dta", type(1:1) unmatched(master)	   // old
mmerge iso3 using  "$output/harm_043022.dta", type(1:1) unmatched(master)

* Reviewed 
mmerge iso3 using  `reviewed', type(1:1) unmatched(master)
replace reviewed = 0 if reviewed == .


* ETRs for anks
mmerge iso3 using "$output\bank_etrs_RD.dta", type(1:1) unmatched(master)

* New CBCR data
mmerge iso3 using "$output\cbcr_signed_date_latest.dta", type(1:1) unmatched(master)

*********************************************
* Feb 9, 2022:  Latest outcomes from OECD   *
*********************************************
mmerge iso3 using "$output\outcomes_latest_020922.dta", unmatched(master)
foreach var of varlist inclusive_now- eoir_compliance {
	replace `var' = 0 if `var' == . 
}


* Ever grey or blacklsited 
mmerge iso3 using "$output\BL_firstyear.dta", type(1:1) unmatched(master) ukeep(year_*)
gen ever_bl = year_bl != .
gen ever_gl = year_gl != .


* cleaning up
replace blacklisted  = 0 if blacklisted == . 
replace greylisted = 0 if greylist  == . 

lab var volume_change_1517 			"% change in volume of payment between 2012 and 2017"
lab var value_change_1517  			"% change in value of payment messages btw 2012 and 2017"
lab var correspondent_change_1517	"% change in number of correspondent connections btw 2012 & 2017"
lab var correspondent_change_1518   "% change in number of correspondent connections btw 2012 & 2018"

gen selected = status == "Selected"


***********************************************
* RD distance euclidian distance calculations *
***********************************************

* Generating euclidian distance
egen order = rownonmiss(strength magnitude stability)

gen above = 0

gen x = strength 
gen y = magnitude
gen z = stability

* Setting cutoffs based on EU report
gen x1 = 60
gen y1 = 40
gen z1 = 70


* Distance calculations

* For those with all three nonmissing values
gen distance = . 
gen sector   = . 
replace distance = -1 * sqrt((x-x1)^2 + (y - y1)^2 + (z - z1)^2) if y >  y1 & x >  x1 & z >  z1 & order == 3		// none
replace sector   = 1											 if y >  y1 & x >  x1 & z >  z1 & order == 3
replace distance = -1 * sqrt(           (y - y1)^2 + (z - z1)^2) if y >  y1 & x <= x1 & z >  z1 & order == 3		// x
replace sector   = 2											 if y >  y1 & x <= x1 & z >  z1 & order == 3	
replace distance = -1 * sqrt((x-x1)^2 +              (z - z1)^2) if y <= y1 & x >  x1 & z >  z1 & order == 3		// y
replace sector   = 3											 if y <= y1 & x >  x1 & z <= z1 & order == 3		
replace distance = -1 * sqrt((x-x1)^2 + (y - y1)^2             ) if y >  y1 & x >  x1 & z <= z1 & order == 3		// z
replace sector   = 4											 if y >  y1 & x >  x1 & z <= z1 & order == 3		
replace distance = -1 * abs((z - z1)) 							 if y <= y1 & x <= x1 & z >  z1 & order == 3		// xy
replace sector   = 5											 if y <= y1 & x <= x1 & z >  z1 & order == 3		
replace distance = -1 * abs((y - y1)) 							 if y >  y1 & x <= x1 & z <= z1 & order == 3		// xz
replace sector   = 6											 if y >  y1 & x <= x1 & z <= z1 & order == 3		
replace distance = -1 * abs((x - x1)) 							 if y <= y1 & x >  x1 & z <= z1 & order == 3		// yz
replace sector   = 7											 if y <= y1 & x >  x1 & z <= z1 & order == 3		
replace distance =      min(abs(x - x1),abs(y-y1),abs(z-z1)) 	 if y <= y1 & x <= x1 & z <= z1 & order == 3		// xyz
replace sector   = 8											 if y <= y1 & x <= x1 & z <= z1 & order == 3		

* For those with only two nonmissing values

* X Y 
replace distance = -1 * sqrt((x-x1)^2 + (y - y1)^2) if y >  y1 & x >  x1 & order == 2 & z == .    // none
replace sector = 	4								if y >  y1 & x >  x1 & order == 2 & z == .   
replace distance = -1 * abs(x-x1)			        if y <= y1 & x >  x1 & order == 2 & z == .    // y
replace sector =    7 						        if y <= y1 & x >  x1 & order == 2 & z == .    
replace distance = -1 * abs(y-y1)				    if y >  y1 & x <= x1 & order == 2 & z == .    // x
replace sector =    6 						        if y >  y1 & x <= x1 & order == 2 & z == .    // 
replace distance = min(abs(x - x1),abs(y-y1))		if y <= y1 & x <= x1 & order == 2 & z == .    // xy
replace sector =    9 								if y <= y1 & x <= x1 & order == 2 & z == .  

* X Z 
replace distance = -1 * sqrt((x-x1)^2 + (z - z1)^2) if z >  z1 & x >  x1 & order == 2 & y == .    // none
replace distance = -1 * abs(x-x1)					if z <= z1 & x >  x1 & order == 2 & y == .    // z
replace distance = -1 * abs(z-z1)					if z >  z1 & x <= x1 & order == 2 & y == .    // x
replace distance = min(abs(x - x1),abs(z-z1)	)	if z <= z1 & x <= x1 & order == 2 & y == .    // xz

* Y Z 
replace distance = -1 * sqrt((y-y1)^2 + (z - z1)^2) if z >  z1 & y >  y1 & order == 2 & x == .  // none
replace distance = -1 * abs(y-y1)					if z <= z1 & y >  y1 & order == 2 & x == .  // z
replace distance = -1 * abs(z-z1)					if z >  z1 & y <= y1 & order == 2 & x == .  // y
replace distance = min(abs(y - y1),abs(z-z1))		if z <= z1 & y <= y1 & order == 2 & x == .  // yz

* For those with only one-nonmissing value, we calculate for x, y and Z separately
foreach d in x y z {
	replace distance = -1 * (`d' - `d'1) if order == 1 & `d' != . 
}

* Outcome if blacklisted OR greylsited
gen both = max(blacklisted,greylisted)

* Generating individual RD distances
foreach var of varlist x y z {
	gen `var'_distance = `var'1 - `var'

}

* Generating nearesst boundary fixed effects
foreach var of varlist x y z {
	gen `var'_boundary = 0 
}

replace x_boundary = 1 if abs(x_distance) < abs(y_distance) & abs(x_distance) < abs(z_distance) & order == 3
replace y_boundary = 1 if abs(y_distance) < abs(x_distance) & abs(y_distance) < abs(z_distance) & order == 3
replace z_boundary = 1 if abs(z_distance) < abs(y_distance) & abs(z_distance) < abs(x_distance) & order == 3

replace x_boundary = 1 if abs(x_distance) < abs(y_distance) & z_distance == . & order == 2
replace x_boundary = 1 if abs(x_distance) < abs(z_distance) & y_distance == . & order == 2

replace y_boundary = 1 if abs(y_distance) < abs(x_distance) & z_distance == . & order == 2
replace y_boundary = 1 if abs(y_distance) < abs(z_distance) & x_distance == . & order == 2

replace z_boundary = 1 if abs(z_distance) < abs(y_distance) & x_distance == . & order == 2
replace z_boundary = 1 if abs(z_distance) < abs(x_distance) & y_distance == . & order == 2

replace x_boundary = 1 if y_distance == . & z_distance == . & order == 1
replace y_boundary = 1 if x_distance == . & z_distance == . & order == 1
replace z_boundary = 1 if y_distance == . & x_distance == . & order == 1

**********************************************************
* Generating alternative distance measure for robustness *
**********************************************************
* Instead of euclidian distance, we consider the actual number of percentage scores one has to change
* In actuality, this only affects those who have > 1 score remaining below the threshold
gen distance_homi = distance

*xyz
replace distance_homi = x_distance + y_distance + z_distance if y > y1 & x > x1 & z > z1 & order == 3
replace distance_homi = 			    y_distance + z_distance if y > y1 & x <= x1 & z > z1 & order == 3
replace distance_homi = x_distance + y_distance 				if y > y1 & x > x1 & z <= z1 & order == 3
replace distance_homi = x_distance 			   + z_distance if y <= y1 & x > x1 & z > z1 & order == 3

*xz
replace distance_homi =  x_distance  + z_distance if z >  z1 & x >  x1 & order == 2 & y == .    
replace distance_homi =  x_distance 	        	 if z <=  z1 & x >  x1 & order == 2 & y == .    
replace distance_homi =  y_distance 	        	 if z >  z1 & x <=  x1 & order == 2 & y == .    

*xy
replace distance_homi =  x_distance  + y_distance if y >  y1 & x >  x1 & order == 2 & z == .    
replace distance_homi =  x_distance 	        	 if y <=  y1 & x >  x1 & order == 2 & z == .    
replace distance_homi =  y_distance 	        	 if y >  y1 & x <=  x1 & order == 2 & z == .    

*yz
replace distance_homi =  z_distance  + y_distance if y >  y1 & z >  z1 & order == 2 & x == .    
replace distance_homi =  z_distance 	        	 if y <=  y1 & z >  z1 & order == 2 & x == .    
replace distance_homi =  y_distance 	        	 if y >  y1 & z <=  z1 & order == 2 & x == .    

* Saving so we can run the actual regressions in a different file

save "$output/rd_sample_032522.dta", replace

exit




exit
