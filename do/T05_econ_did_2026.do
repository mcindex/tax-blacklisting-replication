* T05_econ_did_2026.do  |  TABLE 5 (t:didextended) economic DiDs, corrected panel + 2026 data; APPENDIX f:event_economic replacements (rr_econ_es_2026_*)
* CHANGE LOG (most recent first; older versions in do/old/)
*   2026-09-15  Listing designs only for the economic outcomes (author): the within-haven deposits designs (part H)
*               and the FDI review design are no longer estimated; listing_deposits / listing_fdistock show the
*               full-sample greylisting and blacklisting event studies (never-listed controls).
*   2026-09-15  Trimmed to exhibits in the draft / appendix: the extended and extended-bandwidth tables and the
*               2026-vintage FDI bandwidth estimates dropped (the main-text table is T05b's); dCDH blocks stay switched off.
*   2026-09-15  Rewritten for legibility: the eight custom programs replaced by annotated inline code. Each estimation
*               sample is built once (section 4); the estimation block is written out in sections 5a-5c; the tables are
*               written by one loop over panels. Results unchanged (row order of the estimates file differs).
*               The dCDH event-study .ster files are now saved only when dCDH is switched on.
* 2026-09-14 (author): (i) FDI winsorisation no longer imputes missing values (Stata min(., p99) = p99 had set 9 missing
*   inward-stock cells to the year's p99); (ii) `reviewed' dropped from the CSA-with-controls covariates (it perfectly
*   predicted non-treatment: every listed jurisdiction was reviewed); controls = log income per capita only
* 2026-09-13 (author, ~14:50, reversing the J&Z-only decision of ~14:30): the WIDER union-of-three-lists haven definition for every DiD split, for power (Part H within-haven deposits: union list, as on 2026-09-12)
* Copied unchanged from do/rr_econ_did_2026_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_econ_did_2026_090926.do
*
* Economic-outcome DiDs (deposits, FDI) re-estimated with (1) the corrected EU
* listing status panel and (2) the 2026 data vintages and listing revisions.
* R&R work, 2026-09-09. Two questions:
*
*   PART A - does fixing BLp.dta change Table 5?  The paper's quarterly status
*     panel shows delisted jurisdictions as still listed in the hand-filled gap
*     quarters (see blacklist_update_090926.do). Only the TWFE and Gardner
*     columns of the deposits block use contemporaneous status, so only they
*     can move. Deposits are re-run on the ORIGINAL data and sample
*     (bis_091125_quarterly.dta, 43 jurisdictions, 2015q1-2022q1) twice: with
*     BLp.dta (must reproduce Table 5) and with BLp_2026.dta (corrected).
*     The FDI block is re-run once on the original data as a reproduction
*     check (it keys on first-listing years, which the fix does not touch).
*
*   PART B - extended samples with the new vintages: deposits 2015q1-2026q1
*     from the BIS LBS zip saved 2026-09-09 (via python/econ_data_extract_2026.py),
*     status from BLp_2026.dta; inward FDI stock and flow (% of GNI) 2012-2024
*     from the updated UNCTAD file, first-listing years from
*     BL_firstyear_2026.dta. Same three treatments (first listing / first
*     greylisting / first blacklisting), same four estimators (TWFE, Gardner
*     did2s, Callaway-Sant'Anna without and with controls), same sample rules
*     as bis_regs_051222_updated.do and fdi_regs_91125.do.
*
* Conventions kept from the paper: TWFE/Gardner use the CONTEMPORANEOUS status
* for deposits (switches off at delisting) and the absorbing first-listing
* indicator for FDI; csdid uses never-treated controls (no notyet), dripw,
* wild-bootstrap SEs (seeded here); deposits winsorised at p99 over 2010q1+
* and logged; FDI winsorised at p99 within year; complete panels only; the
* 2010 GNI-per-capita screen for FDI uses the frozen World Bank pull.
*
* Inputs : output/bis_091125_quarterly.dta, output/bis_lbs_2026_filtered.csv,
*          output/fdi_panel_newdata.dta, output/US_FdiFlowsStock_2026.csv,
*          output/gni_current.dta, output/wb_gnipc2010_vintage20260909.csv,
*          output/BLp.dta, output/BLp_2026.dta, output/BL_firstyear.dta,
*          output/BL_firstyear_2026.dta, output/reviewed.dta,
*          output/regready.dta, input/eu_states.xlsx
* Outputs: output/bis_2026_quarterly.dta, output/fdi_panel_2026.dta,
*          output/rr_econ_did_2026_estimates.{dta,csv},
*          (2026-09-16: no .tex written here -- t:didcheck dropped from the appendix,
*           t:didextended is written by T05b_taxrate_econ_did_table.do)
*          graphs/rr_econ_es_2026_{deposits,fdistock,fdiflow}.png
* Requires: reghdfe, did2s, csdid, coefplot, mmerge, kountry, egenmore (sieve)
********************************************************************************

if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global input   "$project\input"
    global output  "$project\output"
    global tables  "$project\tables"
    global graphs  "$project\graphs"
    global do      "$project\do"
}
cap graph set window fontface "LM Roman 10"
set seed 20260909

* Set to 0 to skip sections 1-6 and 8 and only redraw the event-study figures
* from the saved estimates (output/rr_econ_es_2026_*.ster) - about 10 s.
local reestimate 1
if "$econ_reestimate" == "0" local reestimate 0   // 2026-09-12: set global econ_reestimate 0 to redraw figures/tables from the saved estimates
if `reestimate' == 0 {
    foreach f in es_dep_BT es_dep_GL es_dep_BL es_InwardStock_BT es_InwardStock_GL es_InwardStock_BL ///
                 es_InwardFlow_BT es_InwardFlow_GL es_InwardFlow_BL es_dep_GLhv es_dep_BLhv {
        estimates use "$output/rr_econ_es_2026_`f'.ster"
        estimates store `f'
    }
}
if `reestimate' == 1 {

* ==============================================================================
* 1. Common inputs
* ==============================================================================
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
drop if iso3 == "GBR"                                  // as in bis_regs / fdi_regs
replace iso3 = "CZE" if country == "Czechia"
keep iso3
gen byte eu = 1
tempfile eu
save    `eu', replace

* ==============================================================================
* 2. Deposits panel from the 2026 BIS vintage (as bis_deposits_091125.do)
* ==============================================================================
* Two series: `deposits' = cross-border liabilities to non-banks, all
* counterparties; `deposits_allsectors' = same, all sectors. The paper's
* euro_deposits / deposits_local series are not rebuilt (unused in Table 5;
* the euro series' counterparty filter in the original file is inverted).
* The same import is run twice, once per counterparty sector, and the two
* series are merged: first all sectors (saved to a tempfile), then non-banks.
foreach sector in allsectors nonbanks {
    if "`sector'" == "allsectors" {
        local sector_label "All sectors"
        local series_name  "deposits_allsectors"
    }
    if "`sector'" == "nonbanks" {
        local sector_label "Non-banks, total"
        local series_name  "deposits"
    }
    import delimited "$output/bis_lbs_2026_filtered.csv", clear varnames(1) ///
        case(lower) bindquote(strict) encoding(utf-8)
    keep if positiontype == "Cross-border"
    keep if counterpartysector == "`sector_label'"
    keep if inlist(counterpartycountry, "All countries", "All countries (total)")
    * Data columns start at position 32 (after the 31 metadata columns): rename them deposits<quarter>
    unab all : _all
    local counter = tq(1977q4)
    local i = 1
    foreach v of local all {
        if `i' >= 32 {
            rename `v' deposits`counter'
            local counter = `counter' + 1
        }
        local i = `i' + 1
    }
    cap destring deposits*, replace ignore("NaN")
    collapse (sum) deposits*, by(reportingcountry l_rep_cty)
    kountry l_rep_cty, from(iso2c) to(iso3c)
    rename _ISO3C_ iso3
    replace iso3 = "CUW" if l_rep_cty == "CW"
    replace iso3 = "GGY" if reportingcountry == "Guernsey"
    replace iso3 = "HKG" if reportingcountry == "Hong Kong SAR"
    replace iso3 = "IMN" if reportingcountry == "Isle of Man"
    replace iso3 = "JEY" if reportingcountry == "Jersey"
    replace iso3 = "MAC" if reportingcountry == "Macao SAR"
    replace iso3 = "SXM" if reportingcountry == "Sint Maarten"
    replace iso3 = "BES" if reportingcountry == "Bonaire, Sint Eustatius and Saba"
    replace iso3 = "TWN" if strpos(reportingcountry, "Taiwan") > 0 | strpos(reportingcountry, "Chinese Taipei") > 0
    assert iso3 != ""
    drop reportingcountry l_rep_cty
    reshape long deposits, i(iso3) j(quarter)
    format quarter %tq
    replace deposits = . if deposits == 0
    rename deposits `series_name'
    tempfile bis_`sector'
    save    `bis_`sector'', replace
}
use `bis_nonbanks', clear
mmerge iso3 quarter using `bis_allsectors', type(1:1) unmatched(both)
drop _merge
sort iso3 quarter
save "$output/bis_2026_quarterly.dta", replace
qui sum quarter if deposits != .
di as txt "BIS 2026 vintage: `: display %tq r(min)' - `: display %tq r(max)', " _c
qui levelsof iso3 if deposits != ., local(L)
di as txt "`: word count `L'' reporting jurisdictions"

* Vintage comparison on the paper's window
preserve
    keep iso3 quarter deposits
    rename deposits deposits_2026
    mmerge iso3 quarter using "$output/bis_091125_quarterly.dta", type(1:1) ///
        unmatched(none) ukeep(deposits)
    keep if quarter >= tq(2015q1) & quarter <= tq(2022q1) & deposits != . & deposits_2026 != .
    gen dl = abs(ln(deposits_2026) - ln(deposits))
    qui sum dl
    di as txt "Deposits 2025 vs 2026 vintage, 2015q1-2022q1 overlap: N = `r(N)', mean |dlog| = " ///
        %6.4f r(mean) ", share revised > 1% = " _c
    qui count if dl > 0.01
    di as txt %5.3f r(N) / _N
restore

* ==============================================================================
* 3. FDI panel from the 2026 UNCTAD vintage (as fdi_regs_91125.do, block 1)
* ==============================================================================
import delimited "$output/US_FdiFlowsStock_2026.csv", clear varnames(1) ///
    case(lower) bindquote(strict) encoding(utf-8)
rename millionsofusatcurrentprices fdi
keep fdi economylabel year flowlabel directionlabel
reshape wide fdi, i(economylabel year flowlabel) j(directionlabel) string
reshape wide fdiInward fdiOutward, i(economylabel year) j(flowlabel) string
rename (fdiInwardFlow fdiOutwardFlow fdiInwardStock fdiOutwardStock) ///
       (fdi_m_InwardFlow fdi_m_OutwardFlow fdi_m_InwardStock fdi_m_OutwardStock)
egen country = sieve(economylabel), keep(a n s)
replace country = trim(country)
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
drop if country == "Germany Federal Republic of"
drop if country == "Serbia and Montenegro"
drop if country == "Yemen Democratic"
replace iso3 = "CUW" if country == "Curaao"
replace iso3 = "GGY" if country == "Guernsey"
replace iso3 = "HKG" if country == "Hong Kong SAR"
replace iso3 = "IMN" if country == "Isle of Man"
replace iso3 = "JEY" if country == "Jersey"
replace iso3 = "MAC" if country == "Macao SAR"
replace iso3 = "PRK" if country == "Korea Dem Peoples Rep of"
replace iso3 = "LAO" if country == "Lao Peoples Dem Rep"
replace iso3 = "SXM" if country == "Sint Maarten Dutch part"
replace iso3 = "CPV" if country == "Cabo Verde"
replace iso3 = "TWN" if strpos(country, "Taiwan") > 0
replace iso3 = "BOL" if strpos(country, "Bolivia") > 0
replace iso3 = "HKG" if strpos(country, "Hong Kong") > 0
replace iso3 = "MAC" if strpos(country, "Macao") > 0
replace iso3 = "CIV" if strpos(country, "Cote dIvoire") > 0 | strpos(country, "dIvoire") > 0
replace iso3 = "CUW" if strpos(country, "Curacao") > 0 | strpos(country, "Curaao") > 0
replace iso3 = "CZE" if strpos(country, "Czechia") > 0
replace iso3 = "PRK" if strpos(country, "Dem Peoples Rep of Korea") > 0
replace iso3 = "COD" if strpos(country, "Dem Rep of the Congo") > 0
replace iso3 = "SWZ" if strpos(country, "Eswatini") > 0
replace iso3 = "TUR" if strpos(country, "Turkiye") > 0 | strpos(country, "rkiye") > 0
replace iso3 = "VEN" if strpos(country, "Venezuela") > 0
replace iso3 = "CHE-LIE" if country == "Switzerland Liechtenstein"
di as txt "UNCTAD economies without an iso3 (dropped, as in fdi_regs):"
qui levelsof economylabel if iso3 == "", local(unm) clean separate(" | ")
di as txt "  `unm'"
drop if iso3 == ""
* 2026-10-29: the accepted paper's FDI exhibits were made with a kountry name list past Stata's size
* limit, which silently left North Macedonia and State of Palestine without an iso3. The package keeps
* both (default); global fdi_accepted_sample 1 drops them to reproduce the published FDI exhibits exactly.
if "$fdi_accepted_sample" == "1" drop if inlist(iso3, "MKD", "PSE")
duplicates tag iso3 year, gen(dup)
qui count if dup > 0
if r(N) > 0 {
    di as txt "Economy labels mapping to the same iso3 (first kept):"
    list iso3 year economylabel if dup > 0 & year == 2020, noobs
    sort iso3 year economylabel
    by iso3 year: keep if _n == 1
}
drop dup
isid iso3 year
keep if year >= 2005
mmerge iso3 year using "$output/gni_current.dta", type(1:1) unmatched(master) ///
    umatch(countrycode year) ukeep(ny_gnp_mktp_cd)
foreach var of varlist fdi_m_* {
    gen `var'_gnp = (`var' * 1000000) / ny_gnp_mktp_cd
}
drop _merge
save "$output/fdi_panel_2026.dta", replace
qui sum year if fdi_m_InwardStock_gnp != .
di as txt "UNCTAD 2026 vintage: FDI/GNI available `r(min)'-`r(max)'"
preserve
    keep iso3 year fdi_m_InwardStock_gnp fdi_m_InwardFlow_gnp
    rename (fdi_m_InwardStock_gnp fdi_m_InwardFlow_gnp) (stock26 flow26)
    mmerge iso3 year using "$output/fdi_panel_newdata.dta", type(1:1) unmatched(none) ///
        ukeep(fdi_m_InwardStock_gnp fdi_m_InwardFlow_gnp)
    keep if year >= 2012 & year <= 2022
    gen ds = abs(stock26 - fdi_m_InwardStock_gnp) / max(abs(fdi_m_InwardStock_gnp), 0.01)
    qui count if ds != .
    local n = r(N)
    qui count if ds > 0.01 & ds != .
    di as txt "FDI stock/GNI 2025 vs 2026 vintage, 2012-2022 overlap: N = `n', share revised > 1% = " %5.3f r(N) / `n'
restore

* ==============================================================================
* 4. Estimation samples
* ==============================================================================
* Each sample is built once and saved to a tempfile; the estimation sections
* below load them with -use-.
*
* In every sample, for each treatment tr in BT (either list), GL, BL:
*   S_tr    0/1 CONTEMPORANEOUS status (switches off at delisting)
*   A_tr    0/1 ABSORBING indicator (1 from first listing onward)
*   qo_tr   first treated period (0 = never)
*   ever_tr 1 if ever treated (used to restrict the comparison group)

* --- 4a. Deposits samples (as bis_regs_051222_updated.do) ----------------------
*   dep_A_old : original BIS data, the paper's status panel BLp.dta, 2015q1-2022q1 (Table 5 as published)
*   dep_A_new : original BIS data, corrected status panel BLp_2026.dta, 2015q1-2022q1
*   dep_B     : 2026 BIS vintage, corrected status panel, 2015q1-2026q1
local depfile_A_old    "$output/bis_091125_quarterly.dta"
local statusfile_A_old "$output/BLp.dta"
local qend_A_old       = tq(2022q1)
local depfile_A_new    "$output/bis_091125_quarterly.dta"
local statusfile_A_new "$output/BLp_2026.dta"
local qend_A_new       = tq(2022q1)
local depfile_B        "$output/bis_2026_quarterly.dta"
local statusfile_B     "$output/BLp_2026.dta"
local qend_B           = tq(2026q1)

foreach v in A_old A_new B {
    use "`depfile_`v''", clear
    keep iso3 quarter deposits
    drop if quarter > `qend_`v''
    mmerge iso3 using "$output/reviewed.dta", type(n:1) unmatched(master)
    keep if quarter >= tq(2010q1)
    mmerge iso3 quarter using "`statusfile_`v''", type(1:1) unmatched(master) ukeep(listed_BL listed_GL)
    foreach var of varlist listed* {
        replace `var' = 0 if `var' == .
    }
    gen byte BT = listed_BL | listed_GL
    rename listed_BL BL
    rename listed_GL GL
    mmerge iso3 using "$output/regready.dta", type(n:1) ukeep(selected lngdppcn_2015) unmatched(master)
    * winsorise at p99 over 2010q1 onward, then log
    qui sum deposits, detail
    replace deposits = min(deposits, r(p99)) if deposits != .
    gen lndeposits = ln(deposits)
    keep if quarter >= tq(2015q1)
    * complete panels only
    gen byte nodep = deposits == .
    bys iso3: egen sumno = sum(nodep)
    drop if sumno > 0
    egen c = group(iso3)
    tsset c quarter
    foreach var of varlist BT BL GL {
        by c (quarter), sort: gen noccur = sum(`var')
        by c: gen byte first_`var' = noccur == 1 & noccur[_n - 1] != noccur
        drop noccur
        gen q`var' = quarter if first_`var' == 1
        bys c: egen qo_`var' = max(q`var')
        replace qo_`var' = 0 if qo_`var' == .
        bys c: egen ever_`var' = max(`var')
        rename `var' S_`var'                                    // contemporaneous status
        gen byte A_`var' = qo_`var' > 0 & quarter >= qo_`var'   // absorbing
    }
    replace reviewed = 0 if reviewed == .
    rename lngdppcn_2015 lngdp
    tempfile dep_`v'
    save `dep_`v'', replace
}

* --- 4b. FDI samples (as fdi_regs_91125.do) ------------------------------------
*   fdi_old : original UNCTAD panel, first-listing years to Feb 2022, 2012-2022
*   fdi_new : 2026 UNCTAD vintage, first-listing years to Feb 2026, 2012-2024
local panel_old     "$output/fdi_panel_newdata.dta"
local firstyear_old "$output/BL_firstyear.dta"
local yend_old      = 2022
local panel_new     "$output/fdi_panel_2026.dta"
local firstyear_new "$output/BL_firstyear_2026.dta"
local yend_new      = 2024

foreach v in old new {
    use "`panel_`v''", clear
    mmerge iso3 using "$output/reviewed.dta", type(n:1) unmatched(master)
    preserve
        import delimited "$output/wb_gnipc2010_vintage20260909.csv", clear varnames(1) encoding(utf-8)
        keep iso3 ny_gnp_pcap_cd
        tempfile gnipc
        save    `gnipc', replace
    restore
    mmerge iso3 using `gnipc', type(n:1) unmatched(master)
    mmerge iso3 using "`firstyear_`v''", type(n:1) unmatched(master) ukeep(year_bl year_gl)
    egen year_BT = rowmin(year_bl year_gl)
    rename year_bl year_BL
    rename year_gl year_GL
    foreach tr in BT BL GL {
        gen qo_`tr' = year_`tr'
        replace qo_`tr' = . if qo_`tr' > `yend_`v''            // listed after the sample ends = never treated here
        gen byte A_`tr' = year >= qo_`tr' & qo_`tr' != .       // absorbing (the paper's FDI coding)
        replace qo_`tr' = 0 if qo_`tr' == .
        gen byte ever_`tr' = qo_`tr' > 0
    }
    * Contemporaneous status at year-end (Q4) from the corrected quarterly panel
    gen quarter = yq(year, 4)
    mmerge iso3 quarter using "$output/BLp_2026.dta", type(n:1) unmatched(master) ukeep(listed_BL listed_GL)
    replace listed_BL = 0 if listed_BL == .
    replace listed_GL = 0 if listed_GL == .
    gen byte S_BT = listed_BL | listed_GL
    gen byte S_GL = listed_GL
    gen byte S_BL = listed_BL
    drop quarter listed_BL listed_GL
    egen c = group(iso3)
    tsset c year
    * complete panels from 2010, then keep 2012 onward
    keep if year >= 2010 & year <= `yend_`v''
    bys iso3 (year): egen nonmissing = count(fdi_m_InwardFlow_gnp)
    keep if nonmissing == `yend_`v'' - 2010 + 1
    keep if year >= 2012
    gen lngdppc = ln(ny_gnp_pcap_cd)
    * Sample filter as in the submitted code (jurisdictions in regready.dta); the bandwidth
    * restriction uses the Euclidean distance from the frozen file. ALA, SHN, VAT and VEN are in
    * regready.dta but not in the frozen file: they stay in the full sample, not in the bandwidth panels.
    mmerge iso3 using "$output/regready.dta", type(n:1) ukeep(distance_homi) unmatched(none)
    drop distance_homi _merge
    mmerge iso3 using "$output/regready_042822_gdp2026_frozen20260820.dta", type(n:1) ukeep(distance) unmatched(master)
    drop _merge
    drop if lngdppc == .
    * winsorise at p99 within year (missing values stay missing)
    forvalues y = 2012/`yend_`v'' {
        foreach var of varlist fdi* {
            qui sum `var' if year == `y', detail
            replace `var' = min(`var', r(p99)) if year == `y' & `var' != .
        }
    }
    replace reviewed = 0 if reviewed == .
    tempfile fdi_`v'
    save `fdi_`v'', replace
}

* ==============================================================================
* 5. Estimation: deposits and FDI, three treatments, four estimators
* ==============================================================================
* All estimates are posted to one file, one row per part x outcome x sample x treatment x estimator.
*   part A_old / A_new : deposits on the original data (as published / corrected status)
*   part C_old / D_old : FDI stock / flow on the original data (reproduction check)
*   part B             : deposits, 2026 vintage
*   part C_new / D_new : FDI stock / flow, 2026 vintage
* Treatments: first listing (BT, used only by the appendix check table and figure), first greylisting (GL),
* first blacklisting (BL); controls = never-listed jurisdictions. No review design for the economic outcomes
* (author, 2026-09-15: review is not a channel for them).
*
* THE ESTIMATION BLOCK. The same block is written out in sections 5a and 5b.
* It runs on the data in memory for one treatment `tr' and needs these locals:
*   y, t (time variable), cov (CSA controls), part, outcome, sample,
*   mode (absorb = TWFE/Gardner on A_tr; contemp = on S_tr), eff / pl (dCDH only),
*   esname (if set: save the CSA event study under this name) and window (its event window).
* Estimators:
*   DiD     TWFE, jurisdiction and period fixed effects, clustered by jurisdiction
*   Gardner two-stage DiD (did2s)
*   dCDH    de Chaisemartin-D'Haultfoeuille on the non-absorbing status (off: global econ_dcdh 1)
*   CSA     Callaway-Sant'Anna, dripw, never-treated controls, first-listing cohorts, wild bootstrap
*   CSAx    CSA with controls `cov' (posted as missing if it fails, e.g. with six controls)

postfile H str8 part str16 outcome str12 sample str2 tr str8 est ///
    double b se int nj long n double pplac using "$output/rr_econ_did_2026_estimates.dta", replace

* --- 5a. Deposits: parts A_old, A_new and B --------------------------------------
foreach v in A_old A_new B {
    di as txt _n "Deposits, sample `v'"
    use `dep_`v'', clear
    qui levelsof iso3, local(L)
    if "`v'" != "B" assert `: word count `L'' == 43 & _N == 1247    // the Table 5 sample
    if "`v'" == "B" {
        di as txt "  extended deposits sample: `: word count `L'' jurisdictions, `=_N' obs"
        qui levelsof iso3 if ever_BT == 1, local(LT) clean
        di as txt "  ever listed: `LT'"
    }
    foreach tr in BT GL BL {
        preserve
        * comparison group: the blacklisting design drops greylisted-only jurisdictions, and vice versa
        if "`tr'" == "BL" keep if ever_BT == 0 | ever_BL == 1
        if "`tr'" == "GL" keep if ever_BT == 0 | ever_GL == 1

        local y       "lndeposits"
        local t       "quarter"
        local cov     "lngdp"
        local part    "`v'"
        local outcome "deposits"
        local sample  = cond("`v'" == "B", "ext", "43")
        local mode    = cond("`v'" == "A_old", "contemp", "absorb")   // as published: contemporaneous status
        local eff     = 12
        local pl      = 8
        local esname  = cond("`v'" == "B", "es_dep_`tr'", "")
        local window  "-8 12"

        * --- estimation block ---
        local d = cond("`mode'" == "contemp", "S_`tr'", "A_`tr'")
        qui levelsof iso3, local(L)
        local nj : word count `L'
        local n = _N
        qui reghdfe `y' `d', absorb(i.c i.`t') cluster(c)
        post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("DiD") (_b[`d']) (_se[`d']) (`nj') (`n') (.)
        qui did2s `y', first_stage(i.c i.`t') second_stage(i.`d') treatment(`d') cluster(c)
        post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("Gardner") (_b[1.`d']) (_se[1.`d']) (`nj') (`n') (.)
        if "$econ_dcdh" == "1" {
            qui did_multiplegt_dyn `y' c `t' S_`tr', effects(`eff') placebo(`pl') cluster(c) graph_off
            post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("dCDH") (e(Av_tot_effect)) (e(se_avg_total_effect)) (`nj') (`n') (e(p_jointplacebo))
            if "`esname'" != "" {
                est store dc_`esname'
                qui estimates save "$output/rr_econ_es_2026_dc_`esname'.ster", replace
            }
        }
        tempfile cur                                   // csdid_stats reads the saved RIF file, so park the data
        qui save `cur', replace
        qui csdid `y', ivar(c) time(`t') gvar(qo_`tr') method(dripw) saverif(_nc_) replace
        use _nc_, clear
        set seed 20260909
        qui csdid_stats simple, wboot
        matrix b = e(b)
        matrix V = e(V)
        post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
        if "`esname'" != "" {
            set seed 20260909
            qui csdid_stats event, window(`window') wboot estore(`esname')
            qui estimates save "$output/rr_econ_es_2026_`esname'.ster", replace
        }
        use `cur', clear
        capture {
            qui csdid `y' `cov', ivar(c) time(`t') gvar(qo_`tr') method(dripw) saverif(_rif_) replace
            use _rif_, clear
            set seed 20260909
            qui csdid_stats simple, wboot
            matrix b = e(b)
            matrix V = e(V)
        }
        if _rc == 0 post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSAx") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
        else {
            di as err "  CSA with covariates failed (rc = " _rc ") for `part' `outcome' `sample' `tr' -- posted as missing"
            post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSAx") (.) (.) (`nj') (`n') (.)
        }
        use `cur', clear
        di as txt "  `part' `outcome' `sample' `tr': `nj' jurisdictions, `n' obs - done"
        * --- end of estimation block ---

        restore
    }
}

* --- 5b. FDI: parts C_old / D_old (original data) and C_new / D_new (2026 vintage) ---
foreach v in old new {
    di as txt _n "FDI, sample `v'"
    use `fdi_`v'', clear
    qui levelsof iso3, local(L)
    if "`v'" == "old" assert `: word count `L'' == 153 & _N == 1683
    if "`v'" == "new" di as txt "  extended FDI sample: `: word count `L'' jurisdictions, `=_N' obs"
    local samples "All Bandwidth"                                  // original data: both panels of the appendix check table
    if "`v'" == "new" local samples "All"                          // 2026 vintage: the bandwidth panels are not in the draft or appendix
    foreach k of local samples {
        foreach oc in InwardStock InwardFlow {
            foreach tr in BT GL BL {
                preserve
                if "`k'" == "Bandwidth" keep if abs(distance) <= 20     // within 20 Euclidean points of the boundary
                if "`tr'" == "BL" keep if ever_BT == 0 | ever_BL == 1
                if "`tr'" == "GL" keep if ever_BT == 0 | ever_GL == 1
                * complete panels for this outcome
                bys iso3 (year): egen numnon = count(fdi_m_`oc'_gnp)
                qui sum numnon
                keep if numnon == r(max)

                local y       "fdi_m_`oc'_gnp"
                local t       "year"
                local cov     "lngdppc"
                local part    = cond("`oc'" == "InwardStock", "C_`v'", "D_`v'")
                local outcome "`oc'"
                local sample  "`k'"
                local mode    "absorb"
                local eff     = cond("`v'" == "old", 5, 6)
                local pl      = 4
                local esname  = cond("`v'" == "new" & "`k'" == "All", "es_`oc'_`tr'", "")
                local window  "-5 6"

                * --- estimation block ---
                local d = cond("`mode'" == "contemp", "S_`tr'", "A_`tr'")
                qui levelsof iso3, local(L)
                local nj : word count `L'
                local n = _N
                qui reghdfe `y' `d', absorb(i.c i.`t') cluster(c)
                post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("DiD") (_b[`d']) (_se[`d']) (`nj') (`n') (.)
                qui did2s `y', first_stage(i.c i.`t') second_stage(i.`d') treatment(`d') cluster(c)
                post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("Gardner") (_b[1.`d']) (_se[1.`d']) (`nj') (`n') (.)
                if "$econ_dcdh" == "1" {
                    qui did_multiplegt_dyn `y' c `t' S_`tr', effects(`eff') placebo(`pl') cluster(c) graph_off
                    post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("dCDH") (e(Av_tot_effect)) (e(se_avg_total_effect)) (`nj') (`n') (e(p_jointplacebo))
                    if "`esname'" != "" {
                        est store dc_`esname'
                        qui estimates save "$output/rr_econ_es_2026_dc_`esname'.ster", replace
                    }
                }
                tempfile cur
                qui save `cur', replace
                qui csdid `y', ivar(c) time(`t') gvar(qo_`tr') method(dripw) saverif(_nc_) replace
                use _nc_, clear
                set seed 20260909
                qui csdid_stats simple, wboot
                matrix b = e(b)
                matrix V = e(V)
                post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
                if "`esname'" != "" {
                    set seed 20260909
                    qui csdid_stats event, window(`window') wboot estore(`esname')
                    qui estimates save "$output/rr_econ_es_2026_`esname'.ster", replace
                }
                use `cur', clear
                capture {
                    qui csdid `y' `cov', ivar(c) time(`t') gvar(qo_`tr') method(dripw) saverif(_rif_) replace
                    use _rif_, clear
                    set seed 20260909
                    qui csdid_stats simple, wboot
                    matrix b = e(b)
                    matrix V = e(V)
                }
                if _rc == 0 post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSAx") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
                else {
                    di as err "  CSA with covariates failed (rc = " _rc ") for `part' `outcome' `sample' `tr' -- posted as missing"
                    post H ("`part'") ("`outcome'") ("`sample'") ("`tr'") ("CSAx") (.) (.) (`nj') (`n') (.)
                }
                use `cur', clear
                di as txt "  `part' `outcome' `sample' `tr': `nj' jurisdictions, `n' obs - done"
                * --- end of estimation block ---

                restore
            }
        }
    }
}

* ==============================================================================
* 6. Haven / non-haven splits (columns (3)-(4) of the combined main-text table)
* ==============================================================================
* The CSA specification of column (1) (dripw, never-treated controls, no covariates) with
* BOTH treated and control jurisdictions restricted to tax havens (union list, EU havens
* included) or to non-havens. Posted as sample "<sample>_hv" / "<sample>_nh", estimator CSA.
* A split without never-listed controls posts missing.

* --- 6a. Deposits, 2026 vintage ---
di as txt _n "Haven / non-haven splits (deposits)"
use `dep_B', clear
mmerge iso3 using "$output/rr_A2_haven_lists.dta", type(n:1) unmatched(master) ukeep(union)
replace union = 0 if union == .
foreach hs in hv nh {
    foreach tr in BT GL BL {
        preserve
        keep if union == cond("`hs'" == "hv", 1, 0)
        if "`tr'" == "BL" keep if ever_BT == 0 | ever_BL == 1
        if "`tr'" == "GL" keep if ever_BT == 0 | ever_GL == 1

        qui levelsof iso3, local(L)
        local nj : word count `L'
        local n = _N
        tempfile cur
        qui save `cur', replace
        capture {
            qui csdid lndeposits, ivar(c) time(quarter) gvar(qo_`tr') method(dripw) saverif(_hs_) replace
            use _hs_, clear
            set seed 20260909
            qui csdid_stats simple, wboot
            matrix b = e(b)
            matrix V = e(V)
            * havens, greylisting and blacklisting: event study for Figure 7(c) (author, 2026-09-15: Table 5 panel C column (3))
            if "`hs'" == "hv" & "`tr'" != "BT" {
                set seed 20260909
                qui csdid_stats event, window(-8 12) wboot estore(es_dep_`tr'hv)
                qui estimates save "$output/rr_econ_es_2026_es_dep_`tr'hv.ster", replace
            }
        }
        if _rc == 0 post H ("B") ("deposits") ("ext_`hs'") ("`tr'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
        else {
            di as err "  CSA failed (rc = " _rc ") for B deposits ext_`hs' `tr' -- posted as missing"
            post H ("B") ("deposits") ("ext_`hs'") ("`tr'") ("CSA") (.) (.) (`nj') (`n') (.)
        }
        use `cur', clear
        di as txt "  B deposits ext_`hs' `tr': `nj' jurisdictions, `n' obs - done"

        restore
    }
}

* --- 6b. FDI, 2026 vintage ---
di as txt _n "Haven / non-haven splits (FDI)"
use `fdi_new', clear
mmerge iso3 using "$output/rr_A2_haven_lists.dta", type(n:1) unmatched(master) ukeep(union)
replace union = 0 if union == .
foreach oc in InwardStock InwardFlow {
    local part = cond("`oc'" == "InwardStock", "C_new", "D_new")
    foreach hs in hv nh {
        foreach tr in BT GL BL {
            preserve
            keep if union == cond("`hs'" == "hv", 1, 0)
            if "`tr'" == "BL" keep if ever_BT == 0 | ever_BL == 1
            if "`tr'" == "GL" keep if ever_BT == 0 | ever_GL == 1
            bys iso3 (year): egen numnon = count(fdi_m_`oc'_gnp)
            qui sum numnon
            keep if numnon == r(max)

            qui levelsof iso3, local(L)
            local nj : word count `L'
            local n = _N
            tempfile cur
            qui save `cur', replace
            capture {
                qui csdid fdi_m_`oc'_gnp, ivar(c) time(year) gvar(qo_`tr') method(dripw) saverif(_hs_) replace
                use _hs_, clear
                set seed 20260909
                qui csdid_stats simple, wboot
                matrix b = e(b)
                matrix V = e(V)
            }
            if _rc == 0 post H ("`part'") ("`oc'") ("All_`hs'") ("`tr'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
            else {
                di as err "  CSA failed (rc = " _rc ") for `part' `oc' All_`hs' `tr' -- posted as missing"
                post H ("`part'") ("`oc'") ("All_`hs'") ("`tr'") ("CSA") (.) (.) (`nj') (`n') (.)
            }
            use `cur', clear
            di as txt "  `part' `oc' All_`hs' `tr': `nj' jurisdictions, `n' obs - done"

            restore
        }
    }
}
cap erase _hs_.dta
postclose H
}   // end of `reestimate' == 1 block (sections 1-6)

* ==============================================================================
* 7. Event-study figures (Part B, csdid without controls, 95% CIs as Fig. A11)
* ==============================================================================
local grey  "118 118 118"
local pink  "212 17 89"
coefplot (es_dep_GL, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
         (es_dep_BL, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
         (es_dep_BT, recast(connected) mcolor("`pink'") lcolor("`pink'") ciopts(recast(rcap) lcolor("`pink'"))) ///
    , vertical keep(Tm* Tp*) drop(Pre_avg Post_avg) omitted                                                       ///
      rename(Tm8=-8 Tm7=-7 Tm6=-6 Tm5=-5 Tm4=-4 Tm3=-3 Tm2=-2 Tm1=-1 Tp0=0 Tp1=1 Tp2=2 Tp3=3 Tp4=4 Tp5=5 Tp6=6 Tp7=7 Tp8=8 Tp9=9 Tp10=10 Tp11=11 Tp12=12) ///
      xline(8.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black))                                            ///
      xtitle("Quarters relative to first listing") ytitle("Effect on log(foreign-held deposits)")                  ///
      xlabel(, labsize(small)) ci(95) scheme(Modern) xsize(8) ysize(6)                                            ///
      legend(order(2 "Greylisted" 4 "Blacklisted" 6 "Either list") rows(1) position(6))                          ///
      title("Deposits, 2015q1-2026q1", size(medsmall)) name(es_dep, replace)
graph export "$graphs/rr_econ_es_2026_deposits.png", replace width(2400)
if "$ographs" != "" graph export "$ographs/rr_econ_es_2026_deposits_091226.png", replace width(2400)   // Overleaf (2026-09-12)

foreach oc in InwardStock InwardFlow {
    if "`oc'" == "InwardStock" {
        local ttl "Inward FDI stock (% of GNI), 2012-2024"
        local fn  "fdistock"
        local yopt "yscale(range(-.25 .25)) ylabel(-.2(.1).2)"   // author, 2026-09-14: tighter y axis (95% CIs span -0.26 to 0.19)
    }
    else {
        local ttl "Inward FDI flow (% of GNI), 2012-2024"
        local fn  "fdiflow"
        local yopt ""
    }
    coefplot (es_`oc'_GL, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
             (es_`oc'_BL, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
             (es_`oc'_BT, recast(connected) mcolor("`pink'") lcolor("`pink'") ciopts(recast(rcap) lcolor("`pink'"))) ///
        , vertical keep(Tm* Tp*) drop(Pre_avg Post_avg) omitted                                                       ///
          rename(Tm5=-5 Tm4=-4 Tm3=-3 Tm2=-2 Tm1=-1 Tp0=0 Tp1=1 Tp2=2 Tp3=3 Tp4=4 Tp5=5 Tp6=6)                       ///
          xline(5.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black))                                            ///
          xtitle("Years relative to first listing") ytitle("Effect on FDI / GNI")                                    ///
          ci(95) scheme(Modern) xsize(8) ysize(6)                                                                    ///
          legend(order(2 "Greylisted" 4 "Blacklisted" 6 "Either list") rows(1) position(6))                          ///
          `yopt' title("`ttl'", size(medsmall)) name(es_`fn', replace)
    graph export "$graphs/rr_econ_es_2026_`fn'.png", replace width(2400)
    if "$ographs" != "" graph export "$ographs/rr_econ_es_2026_`fn'_091226.png", replace width(2400)   // Overleaf (2026-09-12)
}

* ---- 7b. Main-text Figure 7 panels (c) and (d): listing_deposits, listing_fdistock
*      Same look as listing_ctr / listing_eatr (F07): grey = greylisted, black = blacklisted;
*      connected markers, rcap 95% CIs, ATT annotations. 2026-09-15 (author): listing designs only
*      (review is not a channel for the economic outcomes), never-listed controls.
*      Deposits (c): tax havens only, treated and controls (Table 5 panel C, column (3)).
*      FDI stock (d): full sample (Table 5 panel D, column (1)).
preserve
    use "$output/rr_econ_did_2026_estimates.dta", clear
    foreach tr in GL BL {
        qui sum b  if part == "B" & outcome == "deposits" & sample == "ext_hv" & tr == "`tr'" & est == "CSA"
        local bd = r(mean)
        qui sum se if part == "B" & outcome == "deposits" & sample == "ext_hv" & tr == "`tr'" & est == "CSA"
        local att_dep_`tr' : display %5.3f `bd' " (" %5.3f r(mean) ")"
        qui sum b  if part == "C_new" & outcome == "InwardStock" & sample == "All" & tr == "`tr'" & est == "CSA"
        local bs = r(mean)
        qui sum se if part == "C_new" & outcome == "InwardStock" & sample == "All" & tr == "`tr'" & est == "CSA"
        local att_fdi_`tr' : display %5.3f `bs' " (" %5.3f r(mean) ")"
    }
restore

* Deposits: top of the plotted confidence intervals, to place the ATT labels above the estimates
* (the FDI panel keeps its fixed axis, author 2026-09-14)
foreach fig in dep {
    local ytop_`fig' = .
    foreach tr in GL BL {
        estimates restore es_`fig'_`tr'hv
        matrix b = e(b)
        matrix V = e(V)
        local names : colnames b
        local k = 1
        foreach nm of local names {
            if substr("`nm'", 1, 2) == "Tm" | substr("`nm'", 1, 2) == "Tp" {
                local ytop_`fig' = max(`ytop_`fig'', b[1,`k'] + invnormal(.975) * sqrt(V[`k',`k']))
            }
            local k = `k' + 1
        }
    }
}
local y1_dep = `ytop_dep' + 0.10
local y2_dep = `ytop_dep' + 0.05
local yaxis_top = `ytop_dep' + 0.13                 // room for the labels inside the plot

coefplot (es_dep_GLhv, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
         (es_dep_BLhv, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
    , vertical keep(Tm* Tp*) drop(Pre_avg Post_avg) omitted                                                       ///
      xline(8.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(solid))                             ///
      xtitle("Quarters until first listing") ytitle("Log(foreign-held deposits)")                                  ///
      xlabel(1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "-1" 9 "0" 10 "1" 11 "2" 12 "3" 13 "4" 14 "5" 15 "6" 16 "7" 17 "8" 18 "9" 19 "10" 20 "11" 21 "12", labsize(small)) ///
      ci(95) scheme(Modern) xsize(8) ysize(8)                                                                      ///
      legend(on order(2 "Greylisted" 4 "Blacklisted") position(6) rows(1)) scale(1.3)                           ///
      name(listing_dep, replace) yscale(range(. `yaxis_top'))                                                      ///
      ttext(`y1_dep' 4.3 "ATT:  `att_dep_GL' ", color("`grey'") size(vsmall))                                         ///
      ttext(`y2_dep' 4.3 "ATT:  `att_dep_BL' ", color(black) size(vsmall))
graph export "$graphs/listing_deposits.png", replace width(2000)
if "$ographs" != "" graph export "$ographs/listing_deposits_091226.png", replace width(2000)

coefplot (es_InwardStock_GL, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
         (es_InwardStock_BL, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
    , vertical keep(Tm* Tp*) drop(Pre_avg Post_avg Tm5) omitted                                                   ///
      xline(4.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(solid))                             ///
      xtitle("Years until first listing") ytitle("Inward FDI stock (% of GNI)")                                  ///
      xlabel(1 "-4" 2 "-3" 3 "-2" 4 "-1" 5 "0" 6 "1" 7 "2" 8 "3" 9 "4" 10 "5" 11 "6") ylabel(-.2(.1).2) yscale(range(-.25 .25)) ///
      ci(95) scheme(Modern) xsize(8) ysize(8)                                                                      ///
      legend(on order(2 "Greylisted" 4 "Blacklisted") position(6) rows(1)) scale(1.3)                           ///
      name(listing_fdi, replace)                                                                                   ///
      ttext(0.24 2.55 "ATT:  `att_fdi_GL' ", color("`grey'") size(vsmall))                                      ///
      ttext(0.21 2.55 "ATT:  `att_fdi_BL' ", color(black) size(vsmall))
graph export "$graphs/listing_fdistock.png", replace width(2000)
if "$ographs" != "" graph export "$ographs/listing_fdistock_091226.png", replace width(2000)

if "$econ_dcdh" == "1" {   // 2026-09-12: dCDH event studies dropped (author)
* --- dCDH (non-absorbing) dynamic effects and placebos, same samples ------------
* x-axis: periods relative to the last period before the status changes (0)
local ren_q "Placebo_8=-8 Placebo_7=-7 Placebo_6=-6 Placebo_5=-5 Placebo_4=-4 Placebo_3=-3 Placebo_2=-2 Placebo_1=-1 Effect_1=1 Effect_2=2 Effect_3=3 Effect_4=4 Effect_5=5 Effect_6=6 Effect_7=7 Effect_8=8 Effect_9=9 Effect_10=10 Effect_11=11 Effect_12=12"
* order() is matched AFTER rename(), so it must list the new labels
local ord_q "-8 -7 -6 -5 -4 -3 -2 -1 1 2 3 4 5 6 7 8 9 10 11 12"
coefplot (dc_es_dep_GL, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
         (dc_es_dep_BL, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
         (dc_es_dep_BT, recast(connected) mcolor("`pink'") lcolor("`pink'") ciopts(recast(rcap) lcolor("`pink'"))) ///
    , vertical keep(Placebo_* Effect_*) drop(Av_tot_eff Effect_0) order(`ord_q') rename(`ren_q')                    ///
      xline(8.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black))                                            ///
      xtitle("Quarters relative to last quarter before status changes") ytitle("Effect on log(foreign-held deposits)") ///
      xlabel(, labsize(small)) ci(95) scheme(Modern) xsize(8) ysize(6)                                            ///
      legend(order(2 "Greylisted" 4 "Blacklisted" 6 "Either list") rows(1) position(6))                          ///
      title("Deposits, 2015q1-2026q1: de Chaisemartin-D'Haultfoeuille, non-absorbing status", size(medsmall))    ///
      name(dc_dep, replace)
graph export "$graphs/rr_econ_es_2026_dcdh_deposits.png", replace width(2400)
if "$ographs" != "" graph export "$ographs/rr_econ_es_2026_dcdh_deposits_091226.png", replace width(2400)   // Overleaf (2026-09-12, provisional appendix figure)

local ren_y "Placebo_4=-4 Placebo_3=-3 Placebo_2=-2 Placebo_1=-1 Effect_1=1 Effect_2=2 Effect_3=3 Effect_4=4 Effect_5=5 Effect_6=6"
local ord_y "-4 -3 -2 -1 1 2 3 4 5 6"
foreach oc in InwardStock InwardFlow {
    if "`oc'" == "InwardStock" {
        local ttl "Inward FDI stock (% of GNI), 2012-2024"
        local fn  "fdistock"
    }
    else {
        local ttl "Inward FDI flow (% of GNI), 2012-2024"
        local fn  "fdiflow"
    }
    coefplot (dc_es_`oc'_GL, recast(connected) mcolor("`grey'") lcolor("`grey'") ciopts(recast(rcap) lcolor("`grey'"))) ///
             (dc_es_`oc'_BL, recast(connected) mcolor(black)    lcolor(black)    ciopts(recast(rcap) lcolor(black)))    ///
        , vertical keep(Placebo_* Effect_*) drop(Av_tot_eff Effect_0) order(`ord_y') rename(`ren_y')                    ///
          xline(4.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black))                                            ///
          xtitle("Years relative to last year before status changes") ytitle("Effect on FDI / GNI")                  ///
          ci(95) scheme(Modern) xsize(8) ysize(6)                                                                    ///
          legend(order(2 "Greylisted" 4 "Blacklisted" 6 "Either list") rows(1) position(6))                          ///
          title("`ttl': dCDH, non-absorbing status", size(medsmall)) name(dc_`fn', replace)
    graph export "$graphs/rr_econ_es_2026_dcdh_`fn'.png", replace width(2400)
    if "$ographs" != "" graph export "$ographs/rr_econ_es_2026_dcdh_`fn'_091226.png", replace width(2400)   // Overleaf (2026-09-12)
}
}   // end of the dCDH block (off by default)

* ==============================================================================
* 8. Tables
* ==============================================================================
* Always rebuilt from the saved estimates.
use "$output/rr_econ_did_2026_estimates.dta", clear
replace outcome = "InwardStock" if outcome == "InwardStoc"   // older estimates files had str10 and truncated the name
cap drop p stars bs ses                                      // present after a previous run
gen p = 2 * (1 - normal(abs(b / se)))
gen stars = cond(p < .01, "\sym{***}", cond(p < .05, "\sym{**}", cond(p < .10, "\sym{*}", "")))
gen bs  = cond(b == ., "--", strtrim(string(b,  "%9.3f")) + stars)
gen ses = cond(se == ., "", "(" + strtrim(string(se, "%9.3f")) + ")")
export delimited using "$output/rr_econ_did_2026_estimates.csv", replace
save "$output/rr_econ_did_2026_estimates.dta", replace

* 2026-09-16 (lock-down): the appendix check table (t:didcheck, "Table 5 re-estimated with the
* corrected listing-status panel") was dropped from the online appendix by the author on
* 2026-09-15, so it is no longer written here. Parts A_old / A_new / C_old / D_old are still
* estimated above and their coefficients are saved in output/rr_econ_did_2026_estimates.{dta,csv},
* so the comparison of the published Table 5 with the corrected panel remains fully recoverable
* without re-running anything. The main-text table (t:didextended) is written by
* T05b_taxrate_econ_did_table.do from the same estimates file.
di as txt "Estimates saved to output/rr_econ_did_2026_estimates.dta (no check table written)"
