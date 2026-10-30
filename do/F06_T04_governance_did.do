********************************************************************************
* F06_T04_governance_did.do
* FIGURE 6 and TABLE 4: staggered DiDs of EU review and listing on four
* tax-governance outcomes (plus appendix event-study figures).
********************************************************************************
*
* WHAT THIS FILE DOES
*   1. Builds a quarterly panel of four absorbing 0/1 governance outcomes:
*        inclusive : Inclusive Framework membership   (monthly IF timeline)
*        cbcr      : CbC-MCAA signature               (day-dated)
*        maa       : MAA convention signature         (day-dated)
*        map       : MAP-profile publication          (first OECD snapshot, or
*                    earlier Wayback "last updated" stamp)
*   2. Estimates Callaway-Sant'Anna DiDs (csdid, doubly robust, not-yet-treated
*      controls, wild-bootstrap SEs, no covariates) for three treatments:
*        rv : EU review          (all reviewed jurisdictions treated in 2017q1)
*        gl : first greylisting  (among reviewed jurisdictions)
*        bl : first blacklisting (among reviewed jurisdictions)
*      on several samples (full, RD bandwidth, top third of the score, havens,
*      non-havens excluding OECD/G20 members, and never-reviewed controls for
*      the appendix table written by P_tab_govdid_neverrev.do).
*   3. Draws the event-study figures and writes Table 4.
*   Only exhibits in the draft or the online appendix are produced.
*
* KEY CHOICES
*   - Each outcome's panel starts when the measure existed: IF 2016q2,
*     CbC-MCAA 2016q1, MAP 2016q3, MAA 2010q2. Panel ends 2022q1.
*   - Non-EU OECD members are coded as having published MAP profiles before the
*     panel starts (their profiles predate the BEPS template).
*   - Pre-treatment coefficients are long differences relative to the quarter
*     before treatment (csdid option long2). The pre-trend p-value in Table 4
*     tests that their average (Pre_avg) is zero.
*   - LDCs are kept as untreated units. With global A2_drop_ldc = 1 they are
*     dropped (except Vanuatu) and every output carries the suffix $A2_sfx.
*   - Event windows: -6/+16 quarters (-8/+16 for MAA). 95% CIs; stars 10/5/1%.
*
* OUTPUTS
*   output/rr_A2_gov_panel.dta             analysis panel (quarterly)
*   output/rr_A2_haven_lists.dta           haven-list flags
*   output/rr_A2_govdid_results.{dta,csv}  ATT, SE, pre-trend test, N per spec
*   output/rr_A2_govdid_events.{dta,csv}   event-study coefficients
*   tables/rr_A2_govdid_table.tex          Table 4 (main pass) / appendix no-LDC table (_noldc)
*   graphs/rr_A2_es_top3_4panel.png        Figure 6 (top third)
*   graphs/rr_A2_es_main_4panel.png        appendix: full-sample event studies
*   graphs/rr_A2_es_NE_4panel.png          appendix: non-havens excluding OECD/G20 (main pass only)
*   (Overleaf copies when $otables / $ographs are set by master_rr.do)
*   Also read by: P_tab_govdid_neverrev.do (specs glR blR glRb blRb),
*   P_tab_twfe_compare.do (spec main).
*
* INPUTS
*   output/regready_042822_gdp2026_frozen20260820.dta, output/if_fullpanel_monthly.dta,
*   output/cbcr_month_122219.dta, output/BLp_q.dta,
*   output/map_profile_*.dta, output/map_wayback_dates_iso3.csv,
*   input/eu_states.xlsx, input/zucman_havens.csv, input/EU_2015_blacklist.xlsx,
*   input/sink_ofcs.xlsx
*
* CHANGE LOG (most recent first; older versions in do/old/)
*   2026-09-15  Trimmed to exhibits in the draft / online appendix: dropped the haven event-study figure,
*               the duplicate appendix copy of Table 4, the results-file-only specs glN / blN / havenJZ and
*               the (switched-off) monthly MAP diagnostic. Earlier version in do/old/replication_rr_pre_legibility_091526/.
*   2026-09-15  Rewritten for legibility: the two custom programs (estimation,
*               figure) replaced by annotated inline loops; results unchanged.
*   2026-09-15  Panel start dates per outcome; MAP recode for OECD members;
*               restricted-sample spec NE; Table 4 columns grouped by treatment.
*   2026-09-15  long2 long differences; pre-trend row = Pre_avg p-value (the
*               former 'joint' test was a chi2(1) on the earliest lead only).
*   2026-09-14  Review treatment starts 2017q1 (was 2016q4). No-LDC variant now
*               reads its own suffixed results files.
*   2026-09-13  Haven samples use the union of three lists; greylisting added.
*   2026-09-12  95% CIs everywhere. Copied from do/rr_A2_govdid_all_082526.do.
********************************************************************************

*================================================================ 0. Settings
set seed 20260825                                  // wild bootstrap is otherwise not reproducible

* Figure palette (as the submitted Figure 6): series 1 grey, 2 black, 3 pink
local col1 "118 118 118"
local col2 "black"
local col3 "212 17 89"

* Set global A2_redraw = 1 to skip sections 2-4 (inputs, panel, estimation)
* and redraw the figures and tables from the saved results files.
if "$A2_redraw" != "1" {
*================================================================ 2. Inputs

* --- 2a. EU member flag (as new_etr.do) ---
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
assert iso3 != ""
keep iso3
duplicates drop
gen eu = 1
tempfile eu
save `eu', replace

* --- 2b. IF: first month observed as member ---
use "$output\if_fullpanel_monthly.dta", clear
keep if inclusive == 1
collapse (min) if_month = month, by(iso3)
gen if_q = qofd(dofm(if_month))
keep iso3 if_q
tempfile ifq
save `ifq', replace

* --- 2c. CbCR: first signature month ---
use "$output\cbcr_month_122219.dta", clear
keep iso3 cbcr_month
drop if cbcr_month == .
gen cbcr_q = qofd(dofm(cbcr_month))
keep iso3 cbcr_q
duplicates drop
tempfile cbq
save `cbq', replace

* --- 2d. MAP profiles: first snapshot x Wayback stamp ---
tempfile snaps
local first = 1
foreach s in 051117 110517 041618 062419 040620 020922 {
    use "$output/map_profile_`s'.dta", clear
    keep if map_`s' == 1
    keep iso3
    local mm = substr("`s'",1,2)
    local dd = substr("`s'",3,2)
    local yy = substr("`s'",5,2)
    gen snapdate = date("`mm'/`dd'/20`yy'","MDY")
    if `first' == 0 append using `snaps'
    save `snaps', replace
    local first = 0
}
collapse (min) first_snap = snapdate, by(iso3)
tempfile firstsnap
save `firstsnap', replace

import delimited "$output/map_wayback_dates_iso3.csv", clear varnames(1) ///
    stringcols(_all)
gen lu_date  = date(last_updated, "YMD")
gen cap_date = date(wayback_first_capture, "YMD")
keep iso3 lu_date cap_date
tempfile wayback
save `wayback', replace

use `firstsnap', clear
mmerge iso3 using `wayback', type(1:1) unmatched(both)
drop _merge
* stamps date the captured VERSION, so the snapshot bounds them from the left
gen map_date = min(first_snap, lu_date)
replace map_date = min(first_snap, cap_date) if map_date == .   // DMA, MNG
assert map_date != .
gen map_q = qofd(map_date)
gen map_m = mofd(map_date)
keep iso3 map_q map_m
tempfile mapq
save `mapq', replace

* --- 2e. Haven lists (exactly as effort_011921.do, which draws Figure A9) ---
import   excel "$input\sink_ofcs.xlsx", sheet("Sheet1") firstrow clear
kountry  ISO2, from(iso2c) to(iso3c) m
drop     NAMES_STD MARKER
replace  _ISO3C_ = "JEY" if ISO2 == "JE"
replace  _ISO3C_ = "CUW" if ISO2 == "CW"
assert   _ISO3C != ""
rename   _ISO3C_ iso3
keep iso3
duplicates drop
gen sink = 1
tempfile sink
save `sink', replace

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
keep iso3
duplicates drop
gen oldlist = 1
tempfile oldlist
save `oldlist', replace

import delimited "$input\zucman_havens.csv", varnames(1) clear
keep iso3
replace iso3 = "VGB" if iso3 == "BVI"   // 2026-09-13: the csv codes the British Virgin Islands BVI; every analysis file uses VGB
duplicates drop
gen haven = 1
mmerge iso3 using `oldlist', type(1:1) unmatched(both)
mmerge iso3 using `sink',    type(1:1) unmatched(both)
drop _merge
foreach v in haven oldlist sink {
    replace `v' = 0 if `v' == .
}
gen union = 1
label var haven   "Johannesen & Zucman (2014) tax haven"
label var oldlist "Original 2015 EU blacklist"
label var sink    "Garcia-Bernardo et al. (2017) sink OFC"
label var union   "On any of the three lists"
save "$output/rr_A2_haven_lists.dta", replace

* --- 2f. Country attributes from the frozen RD sample ---
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
keep iso3 selected reviewed ldc maa_signed distance_homi distance
* top third of the multidimensional score (tertile over all scored
* jurisdictions; positive = risky / selected side)
_pctile distance_homi if distance_homi != ., p(66.667)
local cut = r(r1)
di as res "Top-third cut of distance_homi: `cut'"
gen top3 = distance_homi >= `cut' & distance_homi != .
* within the RD bandwidth (author, 2026-09-11): |Euclidean distance| <= 20,
* the maximum MSE-optimal bandwidth in the revised Table 3 (column 1) -
* the analogue of the submitted Table 4's bandwidth column
gen bw20 = abs(distance) <= 20 & distance != .
label var bw20 "Within 20 points of the selection boundary"
* MAA signature quarter: maa_signed is a true Stata date (do NOT use
* maa_date from maa_adoption_033020.dta — raw Excel serials)
gen maa_q = qofd(maa_signed)
qui sum maa_q
assert year(dofq(r(min))) >= 2009 & year(dofq(r(max))) <= 2021
* 2026-09-11 (author decision): DEFAULT = LDCs KEPT as untreated units
* (parallel trends does not require dropping them; the submitted Table 4 had
* dropped them). With global A2_drop_ldc = 1 the LDCs are dropped except
* Vanuatu (the reviewed LDC; matches the RD sample) for the APPENDIX variant,
* and every output carries the suffix $A2_sfx (= "_noldc") so the main files
* are not overwritten. Runner: run_rr_A2all_noldc.do.
if "$A2_drop_ldc" == "1" drop if ldc == 1 & iso3 != "VUT"   // as newdid_050922.do l.51, Vanuatu kept
if "$A2_drop_ldc" == "1" di as res "LDCs DROPPED (except Vanuatu) in the DiD panel (A2_drop_ldc = 1); outputs suffixed $A2_sfx"
replace selected = 0 if selected == .
replace reviewed = 0 if reviewed == .

foreach f in eu ifq cbq mapq {
    mmerge iso3 using ``f'', type(1:1) unmatched(master)
}
mmerge iso3 using "$output/rr_A2_haven_lists.dta", type(1:1) unmatched(master)
drop _merge
foreach v in eu haven oldlist sink union {
    replace `v' = 0 if `v' == .
}
* 2026-09-15 (author): non-EU OECD (13) and G20 (8) members in 2016, obliged to join the Inclusive Framework and the
* BEPS minimum standards at launch; 17 of them were reviewed, which drives the review-design pre-trends
gen byte oecdg20 = inlist(iso3, "AUS", "CAN", "CHL", "ISL", "ISR", "JPN", "KOR", "MEX", "NZL") | ///
                   inlist(iso3, "NOR", "CHE", "TUR", "USA", "ARG", "BRA", "CHN", "IND", "IDN") | ///
                   inlist(iso3, "RUS", "SAU", "ZAF")
label var oecdg20 "Non-EU OECD or G20 member (2016)"
* 2026-09-15 (author, option 2): OECD member countries already had "Country Profiles on Mutual Agreement Procedures" on the
* OECD website before BEPS (page archived August 2015, "of all OECD member countries"), so their MAP profile predates the
* panel. Our dating (first snapshot May 2017 / 'last updated' stamp) would code them as adopting in 2016-17. Recode the 13
* non-EU OECD members of 2015 as adopted before the MAP panel starts (2016q3), keeping every Table 4 column on the same units.
replace map_q = tq(2015q2) if inlist(iso3, "AUS", "CAN", "CHL", "ISL", "ISR", "JPN", "KOR", "MEX", "NZL") | ///
                              inlist(iso3, "NOR", "CHE", "TUR", "USA")
replace map_m = tm(2015m6) if inlist(iso3, "AUS", "CAN", "CHL", "ISL", "ISR", "JPN", "KOR", "MEX", "NZL") | ///
                              inlist(iso3, "NOR", "CHE", "TUR", "USA")

*================================================================ 3. Panel
local sd = qofd(date("01/01/2010","DMY"))
local ed = qofd(date("01/01/2022","DMY"))
local e  = `ed' - `sd' + 1
expand `e'
bys iso3: gen quarter = `sd' - 1 + _n
format quarter %tq

gen inclusive = if_q   != . & quarter >= if_q
gen cbcr      = cbcr_q != . & quarter >= cbcr_q
gen maa       = maa_q  != . & quarter >= maa_q
gen map       = map_q  != . & quarter >= map_q

* Listing status and first-GL / first-BL quarters. NB: BLp_q carries one
* status per quarter, so BHR, LCA, MHL (BL->GL within 2018q1) and NAM
* (2018q4) get their first greylisting one quarter later than in the
* monthly file; immaterial for results (checked 2026-08-25).
mmerge iso3 quarter using "$output\BLp_q.dta", type(1:1) unmatched(master)
drop _merge
foreach var of varlist listed_BL listed_GL {
    replace `var' = 0 if `var' == .
}
egen c = group(iso3)
foreach tr in GL BL {
    bys c (quarter): gen noccur = sum(listed_`tr')
    by  c: gen byte first = noccur == 1 & noccur[_n-1] != noccur
    gen qx = quarter if first == 1
    bys c: egen g_`tr' = max(qx)
    replace g_`tr' = 0 if g_`tr' == .
    drop noccur first qx
}
* Review: 2026-09-14 (author): review treatment starts 2017q1 (selection finalised Jan 2017, letters 1 Feb 2017; was 2016q4)
gen g_RV = qofd(date("01/01/2017","MDY")) if reviewed == 1
replace g_RV = 0 if g_RV == .
format g_GL g_BL g_RV %tq

label var inclusive "Inclusive Framework membership"
label var cbcr      "CbC-MCAA signature"
label var maa       "MAA convention signature"
label var map       "MAP profile publication"
label var top3      "Top third of multidimensional score"
save "$output/rr_A2_gov_panel$A2_sfx.dta", replace

*================================================================ 4. Estimation

*--- 4a. Panel start and event window, by outcome ------------------------------
* Panels never start before the outcome existed: IF launched June 2016; first
* CbC-MCAA signatures January 2016; first MAP profiles under the BEPS Action 14
* template 2016q3; amended MAA convention opened for signature May 2010.
local start_inclusive = tq(2016q2)
local start_cbcr      = tq(2016q1)
local start_map       = tq(2016q3)
local start_maa       = tq(2010q2)
local win_inclusive "-6 16"
local win_cbcr      "-6 16"
local win_map       "-6 16"
local win_maa       "-8 16"

*--- 4b. Specifications: which designs are run on which sample -----------------
* A specification is a sample (spec) crossed with a treatment design:
*   rv = EU review (gvar g_RV), gl = first greylisting (g_GL), bl = first blacklisting (g_BL).
* The sample condition for each spec x design is written out in full below.
* Row order in the results file follows this list.

* main: Table 4 columns (1), (4), (7); Figure A (full event studies)
local designs_main "rv gl bl"
local sample_main_rv "eu == 0"                     // treated = reviewed; controls = never-reviewed non-EU jurisdictions
local sample_main_gl "selected == 1"               // reviewed jurisdictions only
local sample_main_bl "selected == 1"

* bw20: review design within 20 points of the RD boundary (Table 4 column 2)
local designs_bw20 "rv"
local sample_bw20_rv "bw20 == 1 & eu == 0"

* glR / blR: controls = jurisdictions never selected for review (appendix table, P_tab_govdid_neverrev.do)
local designs_glR "gl"
local sample_glR_gl "selected == 0 | g_GL > 0"
local designs_blR "bl"
local sample_blR_bl "selected == 0 | g_BL > 0"

* glRb / blRb: as glR / blR, within 20 points of the RD boundary
local designs_glRb "gl"
local sample_glRb_gl "(selected == 0 | g_GL > 0) & bw20 == 1"
local designs_blRb "bl"
local sample_blRb_bl "(selected == 0 | g_BL > 0) & bw20 == 1"

* top3: top third of the multidimensional score (Table 4 columns 5 and 8; Figure 6).
*   The review design is infeasible there (61 reviewed vs 1 control).
local designs_top3 "gl bl"
local sample_top3_gl "top3 == 1 & selected == 1"
local sample_top3_bl "top3 == 1 & selected == 1"

* havenU: tax havens on any of the three lists, reviewed or not (Table 4 columns 6 and 9)
local designs_havenU "gl bl"
local sample_havenU_gl "union == 1"
local sample_havenU_bl "union == 1"

* NE: non-havens excluding non-EU OECD and G20 members (Table 4 column 3; appendix figure).
*   Main pass only: skipped in the no-LDC variant.
local designs_NE "rv gl bl"
local sample_NE_rv "union == 0 & oecdg20 == 0 & eu == 0"
local sample_NE_gl "union == 0 & oecdg20 == 0 & selected == 1"
local sample_NE_bl "union == 0 & oecdg20 == 0 & selected == 1"

local specs "main bw20 glR blR glRb blRb top3 havenU NE"
if "$A2_sfx" != "" local specs "main bw20 top3 havenU"     // no-LDC pass: only the columns of its appendix table

*--- 4c. Estimate every specification -------------------------------------------
* Results go to two postfiles:
*   res : one row per outcome x spec x design (ATT, SE, pre-trend test, sample sizes)
*   ev  : one row per event-study coefficient
tempfile resf evf
postfile res str8 spec str10 outcome str4 design ///
    double(att se pre_avg pre_se pt_chi2 pt_df pt_p) long(n_treat n_ctrl n_obs) using `resf'
postfile ev str8 spec str10 outcome str4 design str10 term ///
    double(coef se) using `evf'

use "$output/rr_A2_gov_panel$A2_sfx.dta", clear
foreach var in inclusive cbcr maa map {
    foreach spec of local specs {
        foreach d of local designs_`spec' {

            di as res _n "=== `spec' | `var' | `d' ==="
            local gvar = "g_" + upper("`d'")        // g_RV, g_GL or g_BL

            * Sample: this spec x design, from the outcome's start quarter
            preserve
            qui keep if (`sample_`spec'_`d'') & quarter >= `start_`var''

            * Sample sizes (jurisdictions treated / never treated; observations)
            qui egen tag = tag(c)
            qui count if tag & `gvar' > 0
            local nt = r(N)
            qui count if tag & `gvar' == 0
            local nc = r(N)
            qui count
            local nobs = r(N)
            drop tag

            * Callaway-Sant'Anna, doubly robust, not-yet-treated controls.
            * long2: pre-treatment ATT(g,t) are long differences relative to g-1 with the
            * usual sign (universal base period), so Tm1 is the reference and is not estimated.
            capture noisily csdid `var', ivar(c) time(quarter) gvar(`gvar') ///
                method(dripw) saverif(_rif_) replace notyet long2
            if _rc != 0 {
                di as err "csdid failed for `spec' `var' `d' (rc = " _rc ")"
                post res ("`spec'") ("`var'") ("`d'") (.) (.) (.) (.) (.) (.) (.) (`nt') (`nc') (`nobs')
                restore
                continue
            }

            * Aggregate from the saved influence functions, wild bootstrap
            use _rif_, clear
            set seed 20260825                      // reseed so draws do not depend on the order of specs

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

            * (ii) Event study. With long2, csdid_stats counts the window's leads from Tm2,
            * so the lower bound is shifted up by one to keep exactly the plotted leads
            * (-6..-2, or -8..-2 for MAA).
            local wlo = real(word("`win_`var''", 1)) + 1
            local whi = word("`win_`var''", 2)
            local pre     = .
            local prese   = .
            local pt_chi2 = .
            local pt_df   = .
            local pt_p    = .
            capture noisily csdid_stats event, window(`wlo' `whi') wboot
            if _rc == 0 {
                matrix b = e(b)
                matrix V = e(V)
                local names : colnames b
                local k = 1
                foreach nm of local names {
                    local bb = b[1,`k']
                    local ss = sqrt(V[`k',`k'])
                    post ev ("`spec'") ("`var'") ("`d'") ("`nm'") (`bb') (`ss')
                    if "`nm'" == "Pre_avg" {
                        local pre   = `bb'
                        local prese = `ss'
                    }
                    local k = `k' + 1
                }
                * (iii) Pre-trend test: average pre-treatment coefficient = 0, one df.
                * (A joint Wald test is not possible: the wild-bootstrap covariance has rank 1.)
                if `pre' < . & `prese' < . & `prese' > 0 {
                    local pt_chi2 = (`pre' / `prese')^2
                    local pt_df   = 1
                    local pt_p    = 2 * normal(-abs(`pre' / `prese'))
                }
            }

            post res ("`spec'") ("`var'") ("`d'") (`att') (`se') ///
                (`pre') (`prese') (`pt_chi2') (`pt_df') (`pt_p') (`nt') (`nc') (`nobs')
            restore
        }
    }
}
postclose res
postclose ev

*--- 4d. Save results ------------------------------------------------------------
use `resf', clear
gen p = 2*(1 - normal(abs(att/se)))
gen stars = cond(p < .01, "***", cond(p < .05, "**", cond(p < .1, "*", "")))
save "$output/rr_A2_govdid_results$A2_sfx.dta", replace
export delimited using "$output/rr_A2_govdid_results$A2_sfx.csv", replace
list spec outcome design att se stars pre_avg n_treat n_ctrl, noobs sepby(outcome)

use `evf', clear
save "$output/rr_A2_govdid_events$A2_sfx.dta", replace
export delimited using "$output/rr_A2_govdid_events$A2_sfx.csv", replace

}   // end of sections 2-4 (skipped when A2_redraw = 1)
*================================================================ 5. Event-study figures
* One panel per outcome x figure set, then one 2x2 figure per set.
*   main  : greylisted, blacklisted, reviewed (full samples)            -> appendix
*   top3  : greylisted, blacklisted, top third of the score             -> Figure 6
*   NE    : greylisted, blacklisted, reviewed; non-havens excl. OECD/G20 -> appendix (main pass only)
* Coefficients and ATTs are read back from the results files saved in section 4.

local ttl_inclusive "IF membership"
local ttl_cbcr      "CbC-MCAA signature"
local ttl_maa       "MAA convention signature"
local ttl_map       "MAP profile publication"
local npre_inclusive = 6
local npre_cbcr      = 6
local npre_map       = 6
local npre_maa       = 8
local npost = 16

* Series drawn in each figure set (spec:design, in colour order 1, 2, 3) and their legend labels
local series_main  "main:gl main:bl main:rv"
local labels_main  `""Greylisted" "Blacklisted" "Reviewed""'
local xtitle_main  "Quarters until first listing/review"
local series_top3  "top3:gl top3:bl"
local labels_top3  `""Greylisted" "Blacklisted""'
local xtitle_top3  "Quarters until first listing"
local series_NE    "NE:gl NE:bl NE:rv"
local labels_NE    `""Greylisted" "Blacklisted" "Reviewed""'
local xtitle_NE    "Quarters until first listing/review"

local sets "main top3 NE"
if "$A2_sfx" != "" local sets ""                           // no-LDC pass: no figures (only its table is in the appendix)

preserve
foreach set of local sets {
    foreach var in inclusive cbcr maa map {

        * Event-time terms on the x axis (Tm6 ... Tm1 Tp0 ... Tp16) and their labels (every second quarter)
        local npre  = `npre_`var''
        local nterm = `npre' + `npost' + 1
        local xline = `npre' + 0.5                  // dashed treatment line, between Tm1 and Tp0
        local terms ""
        local xlab  ""
        local pos = 1
        forvalues j = `npre'(-1)1 {
            local terms "`terms' Tm`j'"
            if mod(`j',2) == 0 local xlab "`xlab' `pos' "-`j'""
            local pos = `pos' + 1
        }
        forvalues j = 0/`npost' {
            local terms "`terms' Tp`j'"
            if mod(`j',2) == 0 local xlab "`xlab' `pos' "`j'""
            local pos = `pos' + 1
        }

        * One coefficient vector and (diagonal) variance matrix per series
        local i = 0
        local plots  ""
        local legend ""
        local ymin = .
        foreach s of local series_`set' {
            local i = `i' + 1
            local sp = substr("`s'", 1, strpos("`s'", ":") - 1)
            local d  = substr("`s'", strpos("`s'", ":") + 1, .)

            matrix b`i' = J(1, `nterm', .)
            matrix V`i' = J(`nterm', `nterm', 0)
            matrix colnames b`i' = `terms'
            matrix colnames V`i' = `terms'
            matrix rownames V`i' = `terms'

            use "$output/rr_A2_govdid_events$A2_sfx.dta", clear
            qui keep if spec == "`sp'" & outcome == "`var'" & design == "`d'"
            local j = 1
            foreach t of local terms {
                qui count if term == "`t'"
                if r(N) == 1 {
                    qui sum coef if term == "`t'"
                    matrix b`i'[1, `j'] = r(mean)
                    qui sum se if term == "`t'"
                    matrix V`i'[`j', `j'] = r(mean)^2
                }
                local j = `j' + 1
            }
            * Reference quarter (Tm1) is not estimated under long2: draw it at zero
            local j1 : list posof "Tm1" in terms
            if `j1' > 0 {
                if missing(b`i'[1, `j1']) matrix b`i'[1, `j1'] = 0
            }
            * Lowest confidence bound across series sets the bottom of the y axis
            qui gen lo = coef - invnormal(.975)*se
            qui sum lo
            local ymin = min(`ymin', r(min))

            * ATT label for this series, e.g. "0.261 (0.058)"
            use "$output/rr_A2_govdid_results$A2_sfx.dta", clear
            qui keep if spec == "`sp'" & outcome == "`var'" & design == "`d'"
            local att_`i' : display %5.3f att[1] " (" %5.3f se[1] ")"

            * Series style: colour i, offset so the whiskers do not overlap, thin spikes without caps
            local c : word `i' of `"`col1'"' `"`col2'"' `"`col3'"'
            local sercol_`i' "`c'"
            local off = cond(`i' == 1, -0.25, cond(`i' == 2, 0, 0.25))
            local plots `"`plots' (matrix(b`i'), v(V`i') recast(scatter) msize(small) mcolor("`c'") offset(`off') ciopts(recast(rspike) lcolor("`c'") lwidth(thin)))"'
            local lab : word `i' of `labels_`set''
            local legend `"`legend' `=2*`i'' "`lab'""'
        }
        local nser = `i'

        * ATT labels: top band of the plot, just right of the treatment line, one row per series.
        * Fixed positions (0.52, 0.46, 0.40) because the 2x2 figure shares a common y axis.
        local xt  = `xline' + 0.4
        local txt ""
        forvalues i = 1/`nser' {
            local y = 0.52 - 0.06*(`i' - 1)
            local txt `"`txt' text(`y' `xt' "ATT:  `att_`i''", color("`sercol_`i''") size(vsmall) place(e))"'
            di as txt "   rr_A2_es_`set'_`var' series `i': ATT `att_`i''"
        }

        coefplot `plots', vertical keep(T*) order(`terms')                    ///
            xline(`xline', lcolor(black) lpattern(dash))                       ///
            xtitle("`xtitle_`set''") ytitle("P(`ttl_`var'')")                  ///
            yline(0, lcolor(black) lpattern(solid))                            ///
            scheme(Modern) ci(95) yscale(range(`ymin' 0.6))                    ///
            xlabel(`xlab', labsize(small)) xsize(8) ysize(5)                   ///
            legend(on order(`legend') position(6) rows(1)) scale(1.0)          ///
            title("`ttl_`var''", size(medsmall)) name(rr_A2_es_`set'_`var', replace) `txt'
    }

    * 2x2 figure for this set: four outcomes, shared legend, common y axis
    grc1leg rr_A2_es_`set'_inclusive rr_A2_es_`set'_cbcr                     ///
            rr_A2_es_`set'_maa rr_A2_es_`set'_map,                            ///
        cols(2) ycommon legendfrom(rr_A2_es_`set'_inclusive)                  ///
        position(6) xsize(10) ysize(8) scheme(Modern) name(g4_`set', replace)
    if "`set'" != "NE" {
        graph export "$graphs/rr_A2_es_`set'_4panel$A2_sfx.png", replace width(3000)
        if "$ographs" != "" graph export "$ographs/rr_A2_es_`set'_4panel${A2_sfx}_091126.pdf", replace
    }
    if "`set'" == "NE" {
        graph export "$graphs/rr_A2_es_NE_4panel.png", replace width(3000)
        if "$ographs" != "" graph export "$ographs/rr_A2_es_NE_4panel_091526.pdf", replace
    }
}
restore
*================================================================ 6. Results tables
* Table 4. Columns grouped by treatment: Reviewed | Greylisted | Blacklisted.
*   Main pass (9 columns): reviewed full / bandwidth / non-havens excl. OECD-G20 (spec NE);
*   greylisted full / top third / havens; blacklisted full / top third / havens.
*   No-LDC pass (8 columns): the same without NE.
use "$output/rr_A2_govdid_results$A2_sfx.dta", clear
local cols "main:rv bw20:rv main:gl top3:gl havenU:gl main:bl top3:bl havenU:bl"
local ncol = 8
local nrv = 2
if "$A2_sfx" == "" {
    local cols "main:rv bw20:rv NE:rv main:gl top3:gl havenU:gl main:bl top3:bl havenU:bl"
    local ncol = 9
    local nrv = 3
}
local ncol1 = `ncol' + 1
* 2026-09-11 (author): MAP in the main table too; both files now carry all four
local outs_main     "inclusive cbcr maa map"
local file_main     "rr_A2_govdid_table$A2_sfx"

foreach tab in main {
    local outs "`outs_`tab''"
    tempname fh
    file open `fh' using "$tables/`file_`tab''.tex", write replace text
    file write `fh' "\begin{adjustbox}{max width=\textwidth}" _n
    * 2026-09-15 (author): spanning treatment row, then column numbers, then one \shortstack per column (sample)
    local c1 = 2
    local c2 = 1 + `nrv'
    local c3 = `c2' + 1
    local c4 = `c2' + 3
    local c5 = `c4' + 1
    local c6 = `c4' + 3
    file write `fh' "\begin{tabular}{l*{`ncol'}{c}}" _n
    file write `fh' "\toprule" _n
    file write `fh' " & \multicolumn{`nrv'}{c}{Reviewed} & \multicolumn{3}{c}{Greylisted} & \multicolumn{3}{c}{Blacklisted} \\" _n
    file write `fh' "\cmidrule(lr){`c1'-`c2'}\cmidrule(lr){`c3'-`c4'}\cmidrule(lr){`c5'-`c6'}" _n
    local nums ""
    forvalues k = 1/`ncol' {
        local nums "`nums' & \multicolumn{1}{c}{(`k')}"
    }
    file write `fh' "`nums' \\" _n
    local s_full  "\multicolumn{1}{c}{\shortstack{Full \\ sample}}"
    local s_bw    "\multicolumn{1}{c}{\shortstack{Bandwidth \\ $|d| \leq 20$}}"
    local s_ne    "\multicolumn{1}{c}{\shortstack{Non-havens \\ excl. OECD/G20}}"
    local s_top3  "\multicolumn{1}{c}{\shortstack{Top third \\ of score}}"
    local s_haven "\multicolumn{1}{c}{\shortstack{Tax \\ havens}}"
    if `nrv' == 3 file write `fh' " & `s_full' & `s_bw' & `s_ne' & `s_full' & `s_top3' & `s_haven' & `s_full' & `s_top3' & `s_haven' \\" _n
    else          file write `fh' " & `s_full' & `s_bw' & `s_full' & `s_top3' & `s_haven' & `s_full' & `s_top3' & `s_haven' \\" _n
    file write `fh' "\midrule" _n

    * ATT rows (outcomes numbered; the numbers key the pre-trend rows below)
    file write `fh' "\multicolumn{`ncol1'}{l}{\emph{Average treatment effect on the treated}} \\" _n
    local on = 0
    foreach var of local outs {
        local on = `on' + 1
        local num_`var' = `on'
        local line1 "(`on') `ttl_`var''"
        local line2 ""
        foreach c of local cols {
            local sp = substr("`c'", 1, strpos("`c'", ":") - 1)
            local d  = substr("`c'", strpos("`c'", ":") + 1, .)
            qui count if spec == "`sp'" & outcome == "`var'" & design == "`d'" & att != .
            if r(N) == 0 {
                local line1 "`line1' & --"
                local line2 "`line2' & "
                continue
            }
            qui levelsof att   if spec == "`sp'" & outcome == "`var'" & design == "`d'", local(a) clean
            qui levelsof se    if spec == "`sp'" & outcome == "`var'" & design == "`d'", local(s) clean
            qui levelsof stars if spec == "`sp'" & outcome == "`var'" & design == "`d'", local(st) clean
            local a : display %5.3f `a'
            local s : display %5.3f `s'
            local line1 "`line1' & `a'`st'"
            local line2 "`line2' & (`s')"
        }
        file write `fh' "`line1' \\" _n
        file write `fh' "`line2' \\" _n
    }
    file write `fh' "\midrule" _n

    * Pre-trend row, one row per outcome: p-value that the AVERAGE pre-treatment event-study coefficient
    * (window) is zero, wild-bootstrap SE (2026-09-15, option 2; was labelled a joint test but was chi2(1))
    file write `fh' "\multicolumn{`ncol1'}{l}{\emph{Average pre-treatment event-study coefficient (window) $=0$, \$p\$-value}} \\" _n
    foreach var of local outs {
        local line1 "\hspace{.4cm} Outcome (`num_`var'')"
        foreach c of local cols {
            local sp = substr("`c'", 1, strpos("`c'", ":") - 1)
            local d  = substr("`c'", strpos("`c'", ":") + 1, .)
            qui count if spec == "`sp'" & outcome == "`var'" & design == "`d'" & pt_p != .
            if r(N) == 0 {
                local line1 "`line1' & --"
                continue
            }
            qui levelsof pt_p if spec == "`sp'" & outcome == "`var'" & design == "`d'", local(a) clean
            local a : display %5.3f `a'
            local line1 "`line1' & `a'"
        }
        file write `fh' "`line1' \\" _n
    }
    file write `fh' "\midrule" _n

    * Sample sizes (units; identical across outcomes within a column)
    local lt "Treated jurisdictions"
    local lc "Control jurisdictions"
    foreach c of local cols {
        local sp = substr("`c'", 1, strpos("`c'", ":") - 1)
        local d  = substr("`c'", strpos("`c'", ":") + 1, .)
        qui levelsof n_treat if spec == "`sp'" & outcome == "inclusive" & design == "`d'", local(nt) clean
        qui levelsof n_ctrl  if spec == "`sp'" & outcome == "inclusive" & design == "`d'", local(nc) clean
        local lt "`lt' & `nt'"
        local lc "`lc' & `nc'"
    }
    file write `fh' "`lt' \\" _n
    file write `fh' "`lc' \\" _n
    file write `fh' "\bottomrule" _n
    file write `fh' "\end{tabular}" _n
    file write `fh' "\end{adjustbox}" _n
    file close `fh'
    type "$tables/`file_`tab''.tex"
    if "$otables" != "" copy "$tables/`file_`tab''.tex" "$otables/`file_`tab''_091126.tex", replace
}

*================================================================ 7. Sample rosters (log only)
use "$output/rr_A2_gov_panel$A2_sfx.dta", clear
keep iso3 selected reviewed eu top3 union haven g_GL g_BL distance_homi
duplicates drop
di as res _n "=== Top third of score: jurisdictions ==="
sort g_BL g_GL iso3
list iso3 distance_homi reviewed g_GL g_BL if top3 == 1, noobs sepby(g_BL)
di as res _n "=== Tax havens (union of Figure A9 lists; haven = J&Z flag) ==="
list iso3 haven g_GL g_BL if union == 1, noobs sepby(g_BL)

di as res _n "F06_T04_governance_did.do completed."
