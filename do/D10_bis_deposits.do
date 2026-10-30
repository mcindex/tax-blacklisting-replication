* D10_bis_deposits.do  |  BIS locational banking statistics -> bis_091125_quarterly.dta
* Copied unchanged from do/bis_deposits_091125.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
* 2026-10-30: reads output/bis_lbs_2022_filtered.dta, the rows of the 530 MB 2022 BIS file
* (input/WS_LBS_D_PUB_csv_col.csv) that pass any of the four row filters below, made by
* do/bis_2022_extract.do so the package fits GitHub's 100 MB file limit.
********************************************************************************

****************************
* Loading EURO countries   *
****************************
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
drop if iso3 == "GBR"
replace iso3 = "CZE" if country=="Czechia"
tempfile e
save    `e', replace


* Loading BIS data 
use "$output\bis_lbs_2022_filtered.dta", clear		// Updated as April 2022

* Euro deposits only 
* Refining
keep if positiontype 	    == "Cross-border"
keep if balancesheet 	    == "Total liabilities" 
keep if measure    	    == "Amounts outstanding / Stocks"						// Amounts outstanding/stocks
keep if counterpartysector  == "Non-banks, total"
keep if typeofinstruments   == "All instruments"        // Is this right? Or should we restrict to loans and deposits? 
drop if reportingcountry    == "All reporting countries" 

* Formatting iso codes
kountry  l_cp_country, from(iso2c) to(iso3c) 
rename _ISO3C_ iso3

replace        iso3 = "CUW" if  l_cp_country == "CW"
replace        iso3 = "GGY" if counterpartycountry == "Guernsey"
replace        iso3 = "HKG" if counterpartycountry == "Hong Kong SAR"
replace        iso3 = "IMN" if counterpartycountry == "Isle of Man"
replace        iso3 = "JEY" if counterpartycountry == "Jersey"
replace        iso3 = "MAC" if counterpartycountry == "Macao SAR"
replace        iso3 = "SXM" if counterpartycountry == "Sint Maarten"
replace        iso3 = "BES" if counterpartycountry == "Bonaire, Sint Eustatius and Saba"
drop if iso3 != ""


mmerge iso3 using `e', type(n:1) unmatched(none)

* Formatting and reshaping into a panel
local counter = quarterly("1977-Q4","YQ",2000)	// Setting counter to start at the first
foreach var of varlist q4-v221 {
	rename `var' deposits`counter'
	local counter = `counter' + 1
}

destring dep*, replace ignore(NaN)

collapse(sum) dep*, by(reporting l_rep_cty)

* Formatting iso codes
kountry l_rep_cty, from(iso2c) to(iso3c) 
rename _ISO3C_ iso3

replace        iso3 = "CUW" if l_rep_cty 		== "CW"
replace        iso3 = "GGY" if reportingcountry == "Guernsey"
replace        iso3 = "HKG" if reportingcountry == "Hong Kong SAR"
replace        iso3 = "IMN" if reportingcountry == "Isle of Man"
replace        iso3 = "JEY" if reportingcountry == "Jersey"
replace        iso3 = "MAC" if reportingcountry == "Macao SAR"
replace        iso3 = "SXM" if reportingcountry == "Sint Maarten"
replace        iso3 = "BES" if reportingcountry == "Bonaire, Sint Eustatius and Saba"
assert iso3 != ""

drop reportingcountry*

* Reshaping and saving two variants:
reshape long deposits, i(iso3) j(quarter)
keep iso3 deposits quarter
rename deposits euro_deposits
tempfile d
save    `d', replace


*******************************
* Regular data - all deposits *
*******************************
* Loading BIS data 
use "$output\bis_lbs_2022_filtered.dta", clear		// Updated as Feb 2022

* Refining
keep if positiontype 	    == "Cross-border"
keep if balancesheet 	    == "Total liabilities" 
keep if measure    	    == "Amounts outstanding / Stocks"						// Amounts outstanding/stocks
keep if counterpartysector  == "All sectors"
keep if typeofinstruments   == "All instruments"        // Is this right? Or should we restrict to loans and deposits? 
drop if reportingcountry    == "All reporting countries" 
keep if counterpartycountry == "All countries (total)"

* Formatting and reshaping into a panel
local counter = quarterly("1977-Q4","YQ",2000)	// Setting counter to start at the first
foreach var of varlist q4-v221 {
	rename `var' deposits`counter'
	local counter = `counter' + 1
}

destring dep*, replace ignore(NaN)

collapse(sum) dep*, by(reporting l_rep_cty)

* Formatting iso codes
kountry l_rep_cty, from(iso2c) to(iso3c) 
rename _ISO3C_ iso3

replace        iso3 = "CUW" if l_rep_cty 		== "CW"
replace        iso3 = "GGY" if reportingcountry == "Guernsey"
replace        iso3 = "HKG" if reportingcountry == "Hong Kong SAR"
replace        iso3 = "IMN" if reportingcountry == "Isle of Man"
replace        iso3 = "JEY" if reportingcountry == "Jersey"
replace        iso3 = "MAC" if reportingcountry == "Macao SAR"
replace        iso3 = "SXM" if reportingcountry == "Sint Maarten"
replace        iso3 = "BES" if reportingcountry == "Bonaire, Sint Eustatius and Saba"
assert iso3 != ""

drop reportingcountry*

* Reshaping and saving two variants:
reshape long deposits, i(iso3) j(quarter)
keep iso3 deposits quarter
rename deposits deposits_allsectors

tempfile allsectors
save    `allsectors', replace

*********************************
* Regular data - local deposits *
*********************************
* Loading BIS data 
use "$output\bis_lbs_2022_filtered.dta", clear		// Updated as Feb 2022

* Refining
keep if positiontype 	    == "Local"
keep if balancesheet 	    == "Total liabilities" 
keep if measure    	    == "Amounts outstanding / Stocks"						// Amounts outstanding/stocks
keep if counterpartysector  == "Non-banks, total"
keep if currencydenomination == "All currencies"
keep if currencytypeofreportingcountry == "All currencies (=D+F+U)"
keep if typeofinstruments   == "All instruments"        // Is this right? Or should we restrict to loans and deposits? 
drop if reportingcountry    == "All reporting countries" 


* Formatting and reshaping into a panel
local counter = quarterly("1977-Q4","YQ",2000)	// Setting counter to start at the first
foreach var of varlist q4-v221 {
	rename `var' deposits`counter'
	local counter = `counter' + 1
}

destring dep*, replace ignore(NaN)

collapse(sum) dep*, by(reporting l_rep_cty)

* Formatting iso codes
kountry l_rep_cty, from(iso2c) to(iso3c) 
rename _ISO3C_ iso3

replace        iso3 = "CUW" if l_rep_cty 		== "CW"
replace        iso3 = "GGY" if reportingcountry == "Guernsey"
replace        iso3 = "HKG" if reportingcountry == "Hong Kong SAR"
replace        iso3 = "IMN" if reportingcountry == "Isle of Man"
replace        iso3 = "JEY" if reportingcountry == "Jersey"
replace        iso3 = "MAC" if reportingcountry == "Macao SAR"
replace        iso3 = "SXM" if reportingcountry == "Sint Maarten"
replace        iso3 = "BES" if reportingcountry == "Bonaire, Sint Eustatius and Saba"
assert iso3 != ""


drop reportingcountry*

* Reshaping and saving two variants:
reshape long deposits, i(iso3) j(quarter)
keep iso3 deposits quarter
rename deposits deposits_local
replace deposits_local = . if deposits_local == 0

tempfile local
save    `local', replace


************************************
* Regular data - non-bank deposits *
************************************
* Loading BIS data 
use "$output\bis_lbs_2022_filtered.dta", clear		// Updated as Feb 2022

* Refining
keep if positiontype 	    == "Cross-border"
keep if balancesheet 	    == "Total liabilities" 
keep if measure    	   		== "Amounts outstanding / Stocks"						// Amounts outstanding/stocks
keep if counterpartysector  == "Non-banks, total"
keep if typeofinstruments   == "All instruments"        // Is this right? Or should we restrict to loans and deposits? 
drop if reportingcountry    == "All reporting countries" 
keep if counterpartycountry == "All countries (total)"

* Formatting and reshaping into a panel
local counter = quarterly("1977-Q4","YQ",2000)	// Setting counter to start at the first
foreach var of varlist q4-v221 {
	rename `var' deposits`counter'
	local counter = `counter' + 1
}

destring dep*, replace ignore(NaN)

collapse(sum) dep*, by(reporting l_rep_cty)

* Formatting iso codes
kountry l_rep_cty, from(iso2c) to(iso3c) 
rename _ISO3C_ iso3

replace        iso3 = "CUW" if l_rep_cty 		== "CW"
replace        iso3 = "GGY" if reportingcountry == "Guernsey"
replace        iso3 = "HKG" if reportingcountry == "Hong Kong SAR"
replace        iso3 = "IMN" if reportingcountry == "Isle of Man"
replace        iso3 = "JEY" if reportingcountry == "Jersey"
replace        iso3 = "MAC" if reportingcountry == "Macao SAR"
replace        iso3 = "SXM" if reportingcountry == "Sint Maarten"
replace        iso3 = "BES" if reportingcountry == "Bonaire, Sint Eustatius and Saba"
assert iso3 != ""

drop reportingcountry*

* Reshaping and saving two variants:
reshape long deposits, i(iso3) j(quarter)
keep iso3 deposits quarter

mmerge iso3 quarter using `d', type(1:1)
replace euro = . if euro == 0  & deposits != . 
gen per_euro = euro / dep

mmerge iso3 quarter using `allsectors', type(1:1)
mmerge iso3 quarter using `local', type(1:1)

foreach var of varlist deposits* {
	replace `var' = . if `var' == 0 
}

save "$output/bis_091125_quarterly.dta", replace	// Quarterly


exit 
