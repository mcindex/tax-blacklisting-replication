* D01_if_membership.do  |  Inclusive Framework membership timeline -> if_participation*.dta
* Copied unchanged from do/if_membership_load_033020.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
*****************************************************************************************
* This .do file creates graphs and maps of membership of the IF and AEOI, specifically  *																*
*****************************************************************************************






********************************************
* Participation in the Inclusive framework *
********************************************

* We pull in data from many different points in time
* Starting out with membership of the IF as on jan 2019, which requires a bit of formatting
import excel "$input\members_if_jan_19.xlsx", sheet("members") clear
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curacao"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert  iso3 != ""
tempfile IF
save    `IF', replace
duplicates drop
save "$output\if_participation.dta", replace


* Timeline of IF adoption ( this is data taken from archive.org of different lists published
* by the OECD)

*Date: 071516
import excel "$input\IF_membership_timeline_052919.xlsx", sheet("Members_071516") clear
destring A, gen(N) force
keep if  N == .
replace A = subinstr(A, "*", "",.)
replace A = trim(A)
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curaçao"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert  iso3 != ""
keep iso3
tempfile m071516
save    `m071516', replace
save "$output\if_participation071516.dta", replace


*Date:  060717
import excel "$input\IF_membership_timeline_052919.xlsx", sheet("Members_060717") clear
destring A, gen(N) force
keep if  N == .
replace A = subinstr(A, "*", "",.)
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curaçao"
replace iso3 = "MAC" if A == "Macau (China)"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert  iso3 != ""
keep iso3
tempfile m060717
save    `m060717', replace
save "$output\if_participation060717.dta", replace


*Date:  100117
import excel "$input\IF_membership_timeline_052919.xlsx", sheet("Members_100117") clear
destring A, gen(N) force
keep if  N == .
replace A = subinstr(A, "*", "",.)
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curaçao"
replace iso3 = "MAC" if A == "Macau (China)"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert  iso3 != ""
keep iso3
tempfile m100117
save    `m100117', replace
save "$output\if_participation100117.dta", replace



*Date: 050118
import excel "$input\IF_membership_timeline_052919.xlsx", sheet("Members_050118") clear
destring A, gen(N) force
keep if  N == .
replace A = subinstr(A, "*", "",.)
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curaçao"
replace iso3 = "MAC" if A == "Macau (China)"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert  iso3 != ""
keep iso3
tempfile m050118
save    `m050118', replace
save "$output\if_participation050118.dta", replace



*Date: 030119
import excel "$input\IF_membership_timeline_052919.xlsx", sheet("Members_030119") clear
replace A = trim(regexr(trim(A), "^[0-9]", ""))
replace A = trim(regexr(trim(A), "^[0-9]", ""))
replace A = trim(regexr(trim(A), "^[0-9]", ""))
replace A = subinstr(A, ".", "",.)
replace A = subinstr(A, "�", "",.)
replace A = subinstr(A, "3", "",.)
replace A = trim(A)
replace A = substr(A,18,.) in 1/9
replace A = substr(A,14,.) in 10/53
replace A = substr(A,10,.) in 54/83
kountry A, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "GGY" if A == "Guernsey"
replace iso3 = "JEY" if A == "Jersey"
replace iso3 = "IMN" if A == "Isle of Man"
replace iso3 = "CUW" if A == "Curaçao"
replace iso3 = "MAC" if A == "Macau (China)"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(A), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(A), "china") > 0 & strpos(lower(A), "hong") == 0 & strpos(lower(A), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(A), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(A), "macau") > 0 | strpos(lower(A), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "ivoire") > 0
replace iso3 = "CIV" if iso3 == "" & strpos(lower(A), "cote") > 0
assert iso3 != ""
keep iso3
gen if9 = 1
tempfile 030119
save    `030119', replace
save "$output\if_participation030119.dta", replace



*Date: 103119
import excel "$input\if_membership_timeline_103119.xlsx", sheet("Table 1") clear
egen country = sieve(B), keep(a space)
replace country = trim(country)
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO iso3
replace iso3 = "GGY" if country == "Guernsey"
replace iso3 = "JEY" if country == "Jersey"
replace iso3 = "IMN" if country == "Isle of Man"
replace iso3 = "CUW" if country == "Curaao"
replace iso3 = "MAC" if country == "Macau China"
replace iso3 = "CUW" if iso3 == "" & strpos(lower(country), "cura") > 0
replace iso3 = "CHN" if iso3 == "" & strpos(lower(country), "china") > 0 & strpos(lower(country), "hong") == 0 & strpos(lower(country), "maca") == 0
replace iso3 = "HKG" if iso3 == "" & strpos(lower(country), "hong kong") > 0
replace iso3 = "MAC" if iso3 == "" & (strpos(lower(country), "macau") > 0 | strpos(lower(country), "macao") > 0)
replace iso3 = "CIV" if iso3 == "" & (strpos(lower(country), "ivoire") > 0 | strpos(lower(country), "cote") > 0)
assert iso3 != ""
save "$output\if_participation103119.dta", replace

* Date 12/15/19ish 
* List is same as previous except for the addition of Honduras and Honduras and Montenegro
use "$output\if_participation103119.dta", clear
set obs 136
replace A       = 136 in 136
replace B       = "Montenegro" in 136
replace country = "Montenegro" in 136
replace iso3    = "MNE" in 136
set obs 137
replace A       = 137 in 137
replace B		= "Honduras" in 137
replace country = "Honduras" in 137
replace iso3 	= "HND" in 137
save "$output\if_participation121519.dta", replace


exit

