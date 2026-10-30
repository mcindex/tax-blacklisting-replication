* D02_map_mli_maa.do  |  MAP profiles, MLI and MAA signatories -> map_profile_*.dta, mil/maa_adoption
* Copied unchanged from do/map_profile_import_110519.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* This .do file imports the list of jurisdictions who have published MAP profiles from: 
* http://www.oecd.org/tax/dispute/country-map-profiles.htm


import excel "$input\map_profiles_062419.xlsx", sheet("Sheet1") firstrow clear

* Sorting out those who have a published map 
gen forthcoming = substr(Country,-1,1) == "*" & substr(Country,-2,.) != "**"
gen notreaties  = substr(Country,-2,.) == "**"
gen map_062419  = forthcoming == 0 & notreaties == 0 
gen map_committed_062419 = map_062419 | forthcoming


* Sorting out iso codes
egen    c = sieve(Country), keep(a n s)
replace c = ustrtrim(c)
replace Country = c

* Run these if the assert further down fails. 
*kountryadd "China (People's Republic of)" to "China" add
*kountryadd "China Peoples Republic of"    to "China" add
*kountryadd "Macau (China)" to "Macao" add
*kountryadd "Saint Vicent and the Grenadines" to "Saint Vincent and the Grenadines" add
*kountryadd "Côte d’Ivoire" to "Cote d'Ivoire" add

replace Country = subinstr(Country, "*", "",.)
kountry Country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3


replace iso3 = "GGY" if Country == "Guernsey"
replace iso3 = "JEY" if Country == "Jersey"
replace iso3 = "IMN" if Country == "Isle of Man"
replace iso3 = "CUW" if Country == "Curacao"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(Country), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(Country), "china") > 0 & strpos(lower(Country), "hong") == 0 & strpos(lower(Country), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(Country), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(Country), "macau") > 0 | strpos(lower(Country), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & (strpos(lower(Country), "ivoire") > 0 | strpos(lower(Country), "cote") > 0)
replace iso3 = "MKD" if iso3 == "" & strpos(lower(Country), "macedonia") > 0
replace iso3 = "SWZ" if iso3 == "" & strpos(lower(Country), "eswatini") > 0
replace iso3 = "VCT" if iso3 == "" & strpos(lower(Country), "saint vi") > 0 & strpos(lower(Country), "grenadines") > 0
assert  iso3 != ""

* Saving
save "$output/map_profile_062419.dta", replace 

**************************
* Now we also do the MLI *
**************************
import excel "$input\mli_signatories_062419.xlsx", sheet("Sheet1") firstrow clear


* Country codes
drop if Jurisdiction == ""
egen    c = sieve(Jurisdiction), keep(a n s )
replace c = ustrtrim(c)
replace Jurisdiction = c
kountry Jurisdiction, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if Jurisdiction == "Guernsey"
replace iso3 = "JEY" if Jurisdiction == "Jersey"
replace iso3 = "IMN" if Jurisdiction == "Isle of Man"
replace iso3 = "CUW" if Jurisdiction == "Curaao"

* Dates
replace Date_Signature = subinstr(Date_Signature, "[1]", "",.)
replace Date_Signature = subinstr(Date_Signature, "[2]", "",.)
replace Date_Signature = ustrtrim(Date_Signature)
foreach var of varlist Date_Signature *_date {
	replace `var' = subinstr(`var', "-", "/",.)
	gen d_`var'   = date(`var',"MDY",2000)
}

* Saving
keep iso3 Date_Signature ratified_date force_date d_Date_Signature d_ratified_date d_force_date
save "$output/mil_adoption_062419.dta", replace 


******************
* MAA convention *
******************
import excel "$input\Status_of_convention_11182019.xlsx", sheet("Table 1") cellrange(A4:H134) firstrow  clear

* Cleaning up country codes
drop if B == ""
egen country = sieve(B), keep(a s)
replace country = proper(country)
replace country = ustrtrim(country)
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3

replace iso3 = "GGY" if country == "Guernsey"
replace iso3 = "JEY" if country == "Jersey"
replace iso3 = "IMN" if country == "Isle of Man" 
replace iso3 = "IMN" if country == "Isle Of Man" 
replace iso3 = "CUW" if country == "Curaao"
replace iso3 = "SXM" if country == "Sint Maarten"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(country), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(country), "china") > 0 & strpos(lower(country), "hong") == 0 & strpos(lower(country), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(country), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(country), "macau") > 0 | strpos(lower(country), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & (strpos(lower(country), "ivoire") > 0 | strpos(lower(country), "cote") > 0)
replace iso3 = "MKD" if iso3 == "" & strpos(lower(country), "macedonia") > 0
replace iso3 = "SWZ" if iso3 == "" & strpos(lower(country), "eswatini") > 0
assert  iso3 != ""

* Some corrections to account for extensions to territories by their parent countries
rename SIGNATUREOpenedon27052010 maa_signed
replace maa_signed = maa_signed[127] if (iso == "AIA" | iso=="BMU"   | iso == "VGB" ///
                                       | iso == "CYM" | iso == "GIB" | iso =="GGY"  ///
									   | iso == "IMN" | iso == "JEY" | iso == "MSR" ///
									   | iso == "TCA")								///
									   & iso[127] == "GBR"							// UK territories
									   
replace maa_signed = maa_signed[88]  if (iso == "ABW" | iso == "CUW" | iso == "SXM" ///
									     )											///
									   & iso[88] == "NLD"							// Netherlands territories

replace maa_signed = maa_signed[34]  if (iso == "FRO" | iso == "GRL" )  			///
									   & iso[34] == "DNK"							// Danish

replace maa_signed = maa_signed[26]  if (iso == "HKG" | iso == "MAC"  )     		///
									   & iso[26] == "CHN"							// Hong Kong

split  maa_signed
drop   maa_signed
gen    maa_signed = date(maa_signed1,"DMY")
format maa_signed %td									   

rename H maa_date
gen maa = maa_date != .
keep iso3 maa maa_date maa_signed
save "$output/maa_adoption_111819.dta", replace 

exit
