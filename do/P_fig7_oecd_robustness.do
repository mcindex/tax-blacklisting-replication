* P_fig7_oecd_robustness.do  |  PENDING Figure 7 robustness with OECD CTS (undecided)
* 2026-09-15: trimmed to the appendix figure f:oecd_prov (block B only; the comparison table rr_fig6_oecd_compare and blocks A, AE, C, D dropped)
* 2026-09-15: rewritten for legibility (estimation program f6_est replaced by an annotated inline loop; results unchanged). Backup do/old/replication_rr_pre_legibility_091526/
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/rr_fig6_oecd_091126.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_fig6_oecd_091126.do
*
* Robustness for the corporate-tax-rate event studies (Figure 6, new_etr.do):
* replace the ITI tax rates with the OECD Corporate Tax Statistics pulled via
* the SDMX API on 2026-09-11 (input/oecd_cts_cit_091126.csv, statutory
* combined CIT rate 2000-2026, 146 jurisdictions; input/oecd_cts_etr_baseline_
* 091126.csv, forward-looking EATR/EMTR 2017-2025, 105 jurisdictions; fixed
* macro assumptions, composite asset = the OECD headline).
*
* Designs as in new_etr.do: annual csdid (dripw, not-yet-treated), treatment =
* first greylisting year (gl; controls reviewed never GL), first blacklisting
* year (bl; controls reviewed never BL), review 2017 (rv; controls non-EU).
* Panel from 2010. LDCs kept (as in the governance DiD).
*
* Blocks:
*   A  statutory rate: ITI on the ITI sample to 2020 (= Figure 6, window -6..3)
*   B  statutory rate: OECD on the OECD sample to 2021 (window -6..4; capped
*      at 2021 to keep Pillar Two rate increases out - author, 2026-09-11)
*   C  statutory rate: ITI vs OECD on the COMMON jurisdictions and years
*      2010-2020 (window -6..3) - isolates the source
*   D  EATR and EMTR: OECD 2017-2021 (bl only - no pre-period for rv/gl) and
*      ITI vs OECD on the common jurisdictions 2017-2020; AE = ITI EMTR to 2020
*
* -> output/rr_fig6_oecd_091126.{dta,csv}, tables/rr_fig6_oecd_compare.tex
*    (+ Overleaf *_091126.tex), graphs/rr_fig6_oecd_scitr_{gl,bl,rv}.png and
*    Overleaf *_091126.pdf (OECD statutory event studies, three designs)
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global input   "$project\input"
    global output  "$project\output"
    global tables  "$project\tables"
    global graphs  "$project\graphs"
}
cap graph set window fontface "LM Roman 10"
set seed 20260825

*-------------------------------------------------------------------------------
* 1. Attributes: EU members, selection/review, first listing years
*-------------------------------------------------------------------------------
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
assert iso3 != ""
keep iso3
gen byte eu = 1
tempfile eu
save `eu'

use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
keep iso3 selected reviewed ldc status distance
tempfile attrs
save `attrs'

*-------------------------------------------------------------------------------
* 2. OECD rates -> annual panel (fractions, to match ITI)
*-------------------------------------------------------------------------------
import delimited using "$input/oecd_cts_cit_091126.csv", clear varnames(1) case(preserve) encoding(utf8)
keep if MEASURE == "CIT_C" & TARGETING == "ST"
keep REF_AREA TIME_PERIOD OBS_VALUE
rename (REF_AREA TIME_PERIOD OBS_VALUE) (iso3 year scitr_oecd)
replace scitr_oecd = scitr_oecd / 100
duplicates drop iso3 year, force
tempfile ocit
save `ocit'

import delimited using "$input/oecd_cts_etr_baseline_091126.csv", clear varnames(1) case(preserve) encoding(utf8)
keep if ETR_SCENARIO == "FIXED" & ETR_TAX_TYPE == "COMPOSITE" & inlist(MEASURE, "EATR", "EMTR")
keep REF_AREA TIME_PERIOD MEASURE OBS_VALUE
replace OBS_VALUE = OBS_VALUE / 100
reshape wide OBS_VALUE, i(REF_AREA TIME_PERIOD) j(MEASURE) string
rename (REF_AREA TIME_PERIOD OBS_VALUEEATR OBS_VALUEEMTR) (iso3 year eatr_oecd emtr_oecd)
tempfile oetr
save `oetr'

*-------------------------------------------------------------------------------
* 3. Combined panel: ITI + OECD, 2010 onward
*-------------------------------------------------------------------------------
use "$input\ITI_CITR_ct_R2.dta", clear
keep iso3 year SCITR_ct EATR_ct EMTR_ct
rename (SCITR_ct EATR_ct EMTR_ct) (scitr_iti eatr_iti emtr_iti)
merge 1:1 iso3 year using `ocit', nogen
merge 1:1 iso3 year using `oetr', nogen
keep if year >= 2010
merge m:1 iso3 using `eu', keep(master match) nogen
replace eu = 0 if eu == .
merge m:1 iso3 using `attrs', keep(master match) nogen
replace selected = 0 if selected == .
replace reviewed = 0 if reviewed == .
merge m:1 iso3 using "$output/BL_firstyear.dta", keep(master match) nogen keepusing(year_bl year_gl)
replace year_bl = 0 if year_bl == .
replace year_gl = 0 if year_gl == .
gen year_rv = cond(reviewed == 1, 2017, 0)
egen c = group(iso3)
* common-source flags (jurisdiction has both series in every year 2010-2020)
bys iso3: egen n_both_s = total(scitr_iti < . & scitr_oecd < . & year <= 2020)
gen byte both_s = n_both_s == 11
bys iso3: egen n_both_e = total(eatr_iti < . & eatr_oecd < . & year >= 2017 & year <= 2020)
gen byte both_e = n_both_e == 4
save "$output/rr_fig6_oecd_panel_091126.dta", replace

qui count if both_s & year == 2016
di as txt "Jurisdictions with both statutory series 2010-2020: `r(N)'"
qui count if both_s & year == 2016 & reviewed == 1
di as txt "  of which reviewed: `r(N)'"

*-------------------------------------------------------------------------------
* 4. Estimation
*-------------------------------------------------------------------------------
* Each run = a block (tax-rate series, sample, years) x a treatment design:
*   gl = first greylisting year (year_gl), sample reviewed jurisdictions
*   bl = first blacklisting year (year_bl), sample reviewed jurisdictions
*   rv = review in 2017 (year_rv), sample non-EU jurisdictions
local sample_gl "selected == 1"
local sample_bl "selected == 1"
local sample_rv "eu == 0"

* One block, run for all three designs (the appendix figure f:oecd_prov):
*   B : OECD statutory rate, OECD sample, to 2021 (before Pillar Two), event window -6..4
* (2026-09-15: blocks A, AE, C1, C2 and D1-D5 and their comparison table dropped: not in the draft or appendix)
local var_B  "scitr_oecd"
local cond_B "year <= 2021"
local win_B  "-6 4"

local runs "B:gl B:bl B:rv"

capture postclose R
postfile R str4 block str12 var str4 tr double(att se pt_p) long(n_treat n_ctrl dummy) using "$output/rr_fig6_oecd_091126.dta", replace
est drop _all
use "$output/rr_fig6_oecd_panel_091126.dta", clear
foreach run of local runs {
    local b  = substr("`run'", 1, strpos("`run'", ":") - 1)
    local tr = substr("`run'", strpos("`run'", ":") + 1, .)
    local var "`var_`b''"
    di as res _n "=== `b' | `var' | `tr' ==="

    preserve
    qui keep if `sample_`tr'' & `cond_`b''

    * Callaway-Sant'Anna, doubly robust, not-yet-treated controls, annual
    capture noisily csdid `var', ivar(c) time(year) gvar(year_`tr') method(dripw) saverif(_rif_) replace notyet
    if _rc != 0 {
        di as err "csdid failed: `b' `var' `tr'"
        post R ("`b'") ("`var'") ("`tr'") (.) (.) (.) (.) (.) (.)
        restore
        continue
    }

    * Jurisdictions treated / never treated
    qui egen tag = tag(c)
    qui count if tag & year_`tr' > 0
    local nt = r(N)
    qui count if tag & year_`tr' == 0
    local nc = r(N)
    drop tag

    * Aggregate from the saved influence functions, wild bootstrap
    use _rif_, clear
    set seed 20260825

    * (i) Overall ATT
    local att = .
    local se  = .
    capture noisily csdid_stats simple, wboot
    if _rc == 0 {
        matrix b = e(b)
        matrix V = e(V)
        local att = b[1,1]
        local se  = sqrt(V[1,1])
    }

    * (ii) Event study; block B is kept in memory (eB_gl, eB_bl, eB_rv) for the figure in section 6
    local keep_est ""
    if "`b'" == "B" local keep_est "estore(eB_`tr')"
    local pt_p = .
    capture noisily csdid_stats event, window(`win_`b'') wboot `keep_est'
    if _rc == 0 {
        * (iii) Pre-trend test: p-value that the average pre-treatment coefficient (Pre_avg) is zero
        matrix b = e(b)
        matrix V = e(V)
        local names : colnames b
        local k = 1
        foreach nm of local names {
            if "`nm'" == "Pre_avg" & V[`k',`k'] > 0 local pt_p = 2 * normal(-abs(b[1,`k'] / sqrt(V[`k',`k'])))
            local k = `k' + 1
        }
    }
    post R ("`b'") ("`var'") ("`tr'") (`att') (`se') (`pt_p') (`nt') (`nc') (.)
    restore
}
postclose R
*-------------------------------------------------------------------------------
* 5. Results file
*-------------------------------------------------------------------------------
use "$output/rr_fig6_oecd_091126.dta", clear
export delimited using "$output/rr_fig6_oecd_091126.csv", replace
list, clean noobs

*-------------------------------------------------------------------------------
* 6. Figure: OECD statutory event studies (block B), three designs
*-------------------------------------------------------------------------------
local col_gl "118 118 118"
local col_bl "black"
local col_rv "212 17 89"
local lab_gl "Greylisted"
local lab_bl "Blacklisted"
local lab_rv "Reviewed"
local plots ""
local leg ""
local i = 0
foreach tr in gl bl rv {
    local i = `i' + 1
    capture estimates restore eB_`tr'
    if _rc == 0 {
        local off = cond(`i' == 1, -0.25, cond(`i' == 2, 0, 0.25))
        local plots `"`plots' (eB_`tr', recast(scatter) msize(small) mcolor("`col_`tr''") offset(`off') ciopts(recast(rspike) lcolor("`col_`tr''") lwidth(thin)))"'
        local leg `"`leg' `=2*`i'' "`lab_`tr''""'
    }
}
coefplot `plots', vertical keep(T*) drop(Pre_avg Post_avg) ci(95) ///
    order(Tm6 Tm5 Tm4 Tm3 Tm2 Tm1 Tp0 Tp1 Tp2 Tp3 Tp4) ///
    xline(6.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black)) ///
    coeflabels(Tm6 = "-6" Tm5 = "-5" Tm4 = "-4" Tm3 = "-3" Tm2 = "-2" Tm1 = "-1" Tp0 = "0" Tp1 = "1" Tp2 = "2" Tp3 = "3" Tp4 = "4", labsize(small)) ///
    xtitle("Years until first listing / review") ytitle("Statutory CIT rate (OECD CTS, to 2021)") ///
    legend(order(`leg') position(6) rows(1)) scheme(Modern) xsize(8) ysize(5) scale(1.0) ///
    name(f6oecd, replace)
graph export "$graphs/rr_fig6_oecd_scitr.png", replace width(2000)
if "$ographs" != "" graph export "$ographs/rr_fig6_oecd_scitr_091126.pdf", replace
