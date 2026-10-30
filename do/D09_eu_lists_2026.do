* D09_eu_lists_2026.do  |  EU list panel extended to Feb 2026 -> BLp_2026, BL_firstyear_2026 (read by T05)
* Copied unchanged from do/blacklist_update_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* blacklist_update_090926.do
*
* Extends the EU grey/blacklist status panels from the last revision in the
* submitted paper (24 February 2022) to the latest Council revision
* (17 February 2026), using the eight Council conclusions the author saved in
* input/updated_bl/ (ST 13092/22, 6375/23, 13879/23, 6776/24, 14269/24,
* 6322/25, 13777/25, 5869/26; Annex I = blacklist, Annex II = greylist).
*
* Source sheet: input/EU_BLGL_090926.xlsx = input/EU_BLGL_050322.xlsx (the
* file blacklist_data_032522.do reads, unchanged) + one row per (date,
* jurisdiction, list) for the eight new revisions, transcribed from the PDFs
* on 2026-09-09 (spellings follow the existing sheet so kountry resolves them).
*
* Outputs carry a _2026 suffix and NOTHING downstream reads them yet - the
* paper's BLp / BLp_m / BL_firstyear are left untouched:
*   output/EU_BL_full_list_2026.dta  one row per revision x jurisdiction x list
*   output/EU_BL_2026.dta            same, iso3 only, de-duplicated
*   output/BLp_2026.dta              quarterly status panel 2017q4-2026q1
*   output/BLp_m_2026.dta            monthly status at revision months
*   output/BL_firstyear_2026.dta     first year ever grey- / blacklisted
*   output/bl_revisions_2026.csv     jurisdictions on each list per revision
*
* Differences from blacklist_data_032522.do's panel construction:
*   - the quarterly grid is generated (fillin) rather than hard-coded, and a
*     jurisdiction that drops off both lists gets an explicit "Neither" row at
*     that revision, so carryforward cannot resurrect a delisted status;
*   - otherwise identical: one status per quarter (the FIRST revision in a
*     quarter wins, as before - so the known one-quarter-late dating of four
*     BL->GL moves in 2018q1 is preserved for comparability).
* The file asserts that, up to 2022q1, the new panels reproduce the old ones.
********************************************************************************

if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global input   "$project\input"
    global output  "$project\output"
    global do      "$project\do"
}

* ==============================================================================
* 1. Full list, all revisions (same mapping steps as blacklist_data_032522.do)
* ==============================================================================
import excel "$input\EU_BLGL_090926.xlsx", sheet("Sheet1") firstrow clear
* The sheet stores dates as datetimes (%tc); the paper's files use %td dates
local fmt : format Date
if strpos("`fmt'", "tc") > 0 {
    replace Date = dofc(Date)
}
format Date %td
split Country, parse(,)
replace Country1 = trim(Country1)
kountry Country1, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3

replace iso3 = "GRD" if Country1 == "Granada"
replace iso3 = "CUW" if Country1 == "Curacao"
replace iso3 = "GGY" if Country1 == "Guernsey"
replace iso3 = "IMN" if Country1 == "Isle of Man"
replace iso3 = "JEY" if Country1 == "Jersey"
replace iso3 = "MAC" if Country1 == "Macao SAR"
replace iso3 = "LAB" if Country1 == "Labuan Island"
replace iso3 = "BRN" if Country1 == "Brunei Darussalam"
replace iso3 = "SWZ" if Country1 == "Eswatini"
replace iso3 = "MKD" if Country1 == "North Macedonia"
replace iso3 = "CPV" if Country1 == "Cabo Verde"

* Every name must resolve
qui levelsof Country1 if iso3 == "", local(unm) clean
if "`unm'" != "" {
    di as err "Unmapped jurisdiction names: `unm'"
    exit 498
}
format Date %td
save "$output\EU_BL_full_list_2026.dta", replace

keep Date iso3 List
duplicates drop iso3 Date List, force
save "$output\EU_BL_2026.dta", replace

* --- Check 1: identical to the paper's EU_BL.dta up to 24 Feb 2022 -------------
preserve
    keep if Date <= td(24feb2022)
    merge 1:1 iso3 Date List using "$output\EU_BL.dta"
    qui count if _merge != 3
    if r(N) > 0 {
        list iso3 Date List _merge if _merge != 3, noobs
        di as err "EU_BL_2026 does not reproduce EU_BL.dta through 2022-02-24"
        exit 9
    }
    di as txt "EU_BL_2026 reproduces EU_BL.dta through 2022-02-24: OK (`=_N' rows)"
restore

* --- Revision summary to log and CSV -------------------------------------------
preserve
    gen byte n = 1
    collapse (sum) n, by(Date List)
    reshape wide n, i(Date) j(List) string
    rename (nBL nGL) (n_blacklisted n_greylisted)
    list, noobs sep(0)
restore
preserve
    sort Date List iso3
    by Date List: gen j = _n
    reshape wide iso3, i(Date List) j(j)
    egen jurisdictions = concat(iso3*), punct(" ")
    replace jurisdictions = trim(itrim(jurisdictions))
    keep Date List jurisdictions
    gen date = string(Date, "%tdCCYY-NN-DD")
    drop Date
    order date List jurisdictions
    export delimited using "$output/bl_revisions_2026.csv", replace
restore

* ==============================================================================
* 2. Quarterly status panel
* ==============================================================================
use "$output\EU_BL_2026.dta", clear
gen listed_ = 1
reshape wide listed_, i(iso3 Date) j(List) string
gen quarter = qofd(Date)
format quarter %tq

* Revision calendar: one date per quarter (the first, as in the original)
preserve
    keep Date quarter
    duplicates drop
    sort quarter Date
    by quarter: keep if _n == 1
    keep quarter
    gen byte revision = 1
    tempfile revq
    save    `revq', replace
restore

* One status per jurisdiction-quarter (first revision in the quarter wins)
sort iso3 quarter Date
by iso3 quarter: keep if _n == 1
keep iso3 quarter listed_BL listed_GL

* Full grid: every ever-listed jurisdiction x every quarter 2017q4..last
* (fillin only combines OBSERVED quarter values, so build the range explicitly)
qui sum quarter
local q0 = r(min)
local q1 = r(max)
preserve
    clear
    set obs `=`q1' - `q0' + 1'
    gen quarter = `q0' + _n - 1
    format quarter %tq
    tempfile allq
    save    `allq', replace
restore
preserve
    keep iso3
    duplicates drop
    cross using `allq'
    tempfile grid
    save    `grid', replace
restore
merge 1:1 iso3 quarter using `grid', assert(match using) nogen
mmerge quarter using `revq', type(n:1) unmatched(master)
replace revision = 0 if revision == .
drop _merge

* Status at revision quarters (absent from both annexes = delisted)
gen status = ""
replace status = "Greylisted"  if revision == 1 & listed_GL == 1
replace status = "Blacklisted" if revision == 1 & listed_BL == 1
replace status = "Neither"     if revision == 1 & status == ""
* Non-revision quarters inherit the last revision's status
sort iso3 quarter
by iso3 (quarter): carryforward status, replace
replace listed_GL = status == "Greylisted"
replace listed_BL = status == "Blacklisted"
keep iso3 quarter listed_BL listed_GL status revision
sort iso3 quarter
save "$output\BLp_2026.dta", replace

* --- Check 2: same listed rows as the paper's BLp.dta through 2022q1 -----------
preserve
    keep if quarter <= tq(2022q1) & (listed_BL == 1 | listed_GL == 1)
    keep iso3 quarter listed_BL listed_GL
    tempfile newp
    save    `newp', replace
    use "$output\BLp.dta", clear
    keep if listed_BL == 1 | listed_GL == 1
    keep iso3 quarter listed_BL listed_GL
    replace listed_BL = 0 if listed_BL == .
    replace listed_GL = 0 if listed_GL == .
    mmerge iso3 quarter using `newp', type(1:1) unmatched(both) ///
        uname(n_) ukeep(listed_BL listed_GL)
    gen byte m1 = _merge
    * Known artefact of blacklist_data_032522.do: its carryforward runs over
    * listed-only rows, so a jurisdiction that has dropped off BOTH lists keeps
    * its last status in the hand-filled gap quarters (2018q3, 2019q3, 2020q2,
    * 2020q3, 2021q2, 2021q3). Those rows exist in the old panel only. Every
    * other row must match exactly.
    mmerge iso3 quarter using "$output\BLp_2026.dta", type(1:1) unmatched(master) ///
        uname(c_) ukeep(status revision)
    gen byte artefact = m1 == 1 & c_revision == 0 & c_status == "Neither"
    qui count if artefact
    local na = r(N)
    qui levelsof iso3 if artefact, local(alist) clean
    local nj : word count `alist'
    qui count if m1 == 2
    local nm2 = r(N)
    qui count if m1 == 1 & !artefact
    local nm1 = r(N)
    qui count if m1 == 3 & (listed_BL != n_listed_BL | listed_GL != n_listed_GL)
    local nd = r(N)
    di as txt "BLp_2026 vs BLp through 2022q1: `nd' status differences, `nm2' new-only rows, `nm1' unexplained old-only rows"
    di as txt "  old-panel artefact (delisted jurisdictions still shown as listed in gap quarters): `na' jurisdiction-quarters, `nj' jurisdictions"
    di as txt "  `alist'"
    if `nd' + `nm1' + `nm2' > 0 {
        list iso3 quarter listed_BL listed_GL n_listed_BL n_listed_GL _merge if m1 == 2 | (m1 == 1 & !artefact) | (m1 == 3 & (listed_BL != n_listed_BL | listed_GL != n_listed_GL)), noobs
        di as err "quarterly panel does not reproduce BLp.dta"
        exit 9
    }
restore

* ==============================================================================
* 3. Monthly status at revision months (as BLp_m.dta)
* ==============================================================================
use "$output\EU_BL_2026.dta", clear
gen listed_ = 1
duplicates drop
reshape wide listed_, i(iso3 Date) j(List) string
gen month = mofd(Date)
format month %tm
sort iso3 month Date
by iso3 month: keep if _n == 1
keep iso3 month listed*
save "$output\BLp_m_2026.dta", replace

* --- Check 3: identical to BLp_m.dta through 2022m2 ----------------------------
preserve
    keep if month <= tm(2022m2)
    cf _all using "$output\BLp_m.dta", verbose
    di as txt "BLp_m_2026 reproduces BLp_m.dta through 2022m2: OK"
restore

* ==============================================================================
* 4. First year ever grey- / blacklisted
* ==============================================================================
use "$output\BLp_2026.dta", clear
gen year = yofd(dofq(quarter))
gen year_bl = year if listed_BL == 1
gen year_gl = year if listed_GL == 1
collapse (min) year_bl year_gl, by(iso3)
egen year = rowmin(year_bl year_gl)
drop if year == .
order iso3 year year_bl year_gl
save "$output\BL_firstyear_2026.dta", replace

* --- Check 4 (informational): what changed relative to BL_firstyear.dta --------
mmerge iso3 using "$output\BL_firstyear.dta", type(1:1) unmatched(both) ///
    uname(o_) ukeep(year_bl year_gl)
di as txt _n "Jurisdictions first listed after Feb 2022 (new to the panel):"
list iso3 year year_bl year_gl if _merge == 1, noobs
di as txt _n "Jurisdictions whose first blacklisting year is new (greylisted before, blacklisted after Feb 2022):"
list iso3 year_bl year_gl o_year_bl o_year_gl if _merge == 3 & year_bl != o_year_bl, noobs
qui count if _merge == 3 & year_gl != o_year_gl
assert r(N) == 0                                       // first-GL years must be unchanged
qui count if _merge == 2
assert r(N) == 0                                       // nobody disappears
