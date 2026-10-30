* P_tab_data_section.do  |  PENDING data-section descriptives (B11/A10)
* 2026-09-15: trimmed to Table t:econdata (governance-adoption figure and ITI coverage table dropped: not in the draft or appendix)
* 2026-09-15: rewritten for legibility (row-writer program desc_row replaced by an annotated inline loop per block; output unchanged). Backup do/old/replication_rr_pre_legibility_091526/
* 2026-09-14 (author): FDI winsorisation guard (missing values no longer set to p99), as T05
* 2026-09-13 (author, ~14:50, reversing the J&Z-only decision of ~14:30): the WIDER union-of-three-lists haven definition for every DiD split, for power (coverage table: union list); shifted-profits rows: all Atlas jurisdictions, as Figure 8
* Copied unchanged from do/rr_B11_data_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_B11_data_090926.do
*
* Data-section material for the ITAX revision (rr_plan.md items B11 and A10;
* Referee 1 main comment 3: "a proper Data section ... descriptive statistics
* and explicit time frames for the economic outcomes ... every source in one
* place", and 3d: document the RSIT/ITI tax-rate database).
*
* One product (Table t:econdata), derived from the existing analysis datasets:
*
*   A. Descriptive statistics for the economic outcomes, computed on the SAME
*      estimation samples as the paper's DiD regressions (Table 5 / Figure 6 /
*      Figure 7):
*        - foreign-held deposits (BIS LBS), quarterly 2015q1-2022q1, as in
*          bis_regs_051222_updated.do (complete panels, p99-winsorised, logged)
*        - inward FDI stock and flow, % of GNI (UNCTAD), annual 2012-2022, as in
*          fdi_regs_91125.do (13 complete years 2010-22, per-year p99 winsor.)
*        - statutory CIT rate, EATR, EMTR (RSIT ITI), annual 2010-2020, as in
*          new_etr.do (review design: all non-EU jurisdictions)
*        - shifted profits (Torslov-Wier-Zucman, Atlas of the Offshore World),
*          annual 2015-2021, tax havens as in weir_inport_090425.do (Figure 7)
*      -> tables/rr_B11_econ_descstats.tex, output/rr_B11_econ_descstats.csv
*
*   (2026-09-15: the governance-adoption figure and the ITI coverage table that this
*    file also produced are no longer built: neither is in the draft or the appendix.
*    Earlier version in do/old/replication_rr_pre_legibility_091526/.)
*
* Vintage note: the FDI script drops jurisdictions with missing 2010 GNI per
* capita pulled LIVE from the World Bank. That series is frozen here in
* output/wb_gnipc2010_vintage20260909.csv (API pull 2026-09-09) and the sample
* is asserted to match Table 5 (153 jurisdictions, 1,683 obs).
*
* Inputs : output/bis_091125_quarterly.dta, output/fdi_panel_newdata.dta,
*          input/ITI_CITR_ct_R2.dta, input/Profit shifting - Nov 2024.xlsx,
*          input/zucman_haven.dta, input/eu_states.xlsx, output/reviewed.dta,
*          output/BLp.dta, output/BL_firstyear.dta, output/regready.dta,
*          output/wb_gnipc2010_vintage20260909.csv, output/rr_A2_gov_panel.dta
* Requires: mmerge, kountry (+ do/kountry_fixes.do), grc1leg, scheme Modern
********************************************************************************

* Standalone guard: define paths if master.do section 1 has not been run
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global input   "$project\input"
    global output  "$project\output"
    global tables  "$project\tables"
    global graphs  "$project\graphs"
    global do      "$project\do"
}

cap graph set window fontface "LM Roman 10"

* ==============================================================================
* 1. Common inputs
* ==============================================================================

* --- 1a. EU member flag, as in bis_regs / fdi_regs (GBR excluded from the EU) --
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
drop if iso3 == "GBR"
assert iso3 != ""
keep iso3
gen byte eu = 1
tempfile eu
save    `eu', replace

* --- 1b. Ever listed (grey or black), through Feb 2026 (2026-09-13 (coherence review fix): was the 2022 file) ---
use "$output\BL_firstyear_2026.dta", clear
keep iso3 year_bl year_gl
gen byte everlisted = 1
tempfile listed
save    `listed', replace

* ==============================================================================
* 2. Economic outcomes: descriptive statistics on the estimation samples
* ==============================================================================

* Each block below lists its rows (variable, label, source, frequency, period, number format,
* CSV key, optional sample condition) and then writes them with the same inline loop.
* The loop assumes iso3 and everlisted (0/1) are in memory.

file open T using "$tables/rr_B11_econ_descstats.tex", write replace
file open C using "$output/rr_B11_econ_descstats.csv", write replace
file write C "key,outcome,source,frequency,period,n_jurisdictions,n_obs,mean,sd,n_jur_neverlisted,mean_neverlisted,n_jur_everlisted,mean_everlisted" _n

file write T "\begin{table}[ht!]" _n
file write T "\centering" _n
file write T "\caption{Descriptive statistics and sources for all main outcomes\label{t:econdata}}" _n
file write T "\begin{adjustbox}{max width=\textwidth}" _n
file write T "\begin{tabular}{lllcrrrrrr}" _n
file write T "\toprule" _n
file write T " & & & & & & & & \multicolumn{2}{c}{\textbf{Mean by listing status}} \\" _n
file write T "\cmidrule(lr){9-10}" _n
file write T "\textbf{Outcome} & \textbf{Source} & \textbf{Freq.} & \textbf{Period} & \textbf{Jur.} & \textbf{Obs.} & \textbf{Mean} & \textbf{SD} & \textbf{Never} & \textbf{Ever} \\" _n
file write T "\midrule" _n

* --- 2a. Foreign-held deposits (bis_regs_051222_updated.do sample) ------------
use "$output/bis_091125_quarterly.dta", clear
drop if quarter > 248                                  // 2022q1
mmerge iso3 using "$output/reviewed.dta", type(n:1) unmatched(master)
mmerge iso3 using `eu', type(n:1) unmatched(master)
replace eu = 0 if eu == .
keep if quarter >= 200                                 // 2010q1
mmerge iso3 quarter using "$output\BLp.dta", type(1:1) unmatched(master)
* Winsorise at p99 over the 2010q1+ window, then log (order as in bis_regs)
foreach var of varlist dep* euro_dep {
    qui sum `var', detail
    replace `var' = min(`var', r(p99)) if `var' != .
    gen ln`var' = ln(`var')
}
keep if quarter >= 220                                 // 2015q1
gen nodep = deposits == .
bys iso3: egen sumno = sum(nodep)
drop if sumno > 0                                      // complete panels only
mmerge iso3 using `listed', type(n:1) unmatched(master)
replace everlisted = 0 if everlisted == .
qui levelsof iso3, local(L)
assert `: word count `L'' == 43                        // Table 5: 43 jurisdictions
assert _N == 1247                                      //          1,247 obs
gen deposits_bn = deposits / 1000
file write T "\multicolumn{10}{l}{\textbf{A. Foreign-held deposits and investment}} \\" _n
local rows "deposits_bn lndeposits"
local lab_deposits_bn  "Foreign-held deposits, USD bn"
local src_deposits_bn  "BIS LBS"
local freq_deposits_bn "Quarterly"
local per_deposits_bn  "2015q1--2022q1"
local fmt_deposits_bn  "%9.1f"
local key_deposits_bn  "dep_bn"
local lab_lndeposits  "~~~log(deposits, USD m)"
local src_lndeposits  "BIS LBS"
local freq_lndeposits "Quarterly"
local per_lndeposits  "2015q1--2022q1"
local fmt_lndeposits  "%9.2f"
local key_lndeposits  "ln_dep"
* Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
* mean and SD overall, and the means for never- and ever-listed jurisdictions.
foreach v of local rows {
    local cond "`cond_`v''"
    if "`cond'" == "" local cond "1"
    qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
    local nj : word count `L'
    qui sum `v' if !missing(`v') & (`cond')
    local n  = r(N)
    local m  = string(r(mean), "`fmt_`v''")
    local sd = string(r(sd),   "`fmt_`v''")
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
    local m0 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
    local nj0 : word count `L0'
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
    local m1 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
    local nj1 : word count `L1'
    local nfmt = string(`n', "%9.0fc")
    file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
    file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
    di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
}

* --- 2b. Inward FDI stock and flow, % of GNI (fdi_regs_91125.do sample) -------
use "$output\fdi_panel_newdata.dta", clear
mmerge iso3 using "$output/reviewed.dta", type(n:1) unmatched(master)
mmerge iso3 using `eu', type(n:1) unmatched(master)
replace eu = 0 if eu == .
* fdi_regs pulls 2010 GNI per capita live from the World Bank (wbopendata) and
* drops jurisdictions where it is missing. That pull is frozen here
* (output/wb_gnipc2010_vintage20260909.csv, API pull of 2026-09-09: DJI and
* NCL missing) so the sample is reproducible; it gives Table 5's 153 / 1,683.
preserve
    import delimited "$output/wb_gnipc2010_vintage20260909.csv", clear ///
        varnames(1) encoding(utf-8)
    keep iso3 ny_gnp_pcap_cd
    tempfile gnipc
    save    `gnipc', replace
restore
mmerge iso3 using `gnipc', type(n:1) unmatched(master)
keep if year >= 2010 & year <= 2022
bys iso3 (year): egen nonmissing = count(fdi_m_InwardFlow_gnp)
keep if nonmissing == 13
keep if year >= 2012
gen lngdppc = ln(ny_gnp_pcap_cd)
mmerge iso3 using "$output\regready.dta", type(n:1) ukeep(distance_homi) unmatched(none)
drop if lngdppc == .
forvalues y = 2012/2022 {
    foreach var of varlist fdi* {
        qui sum `var' if year == `y', detail
        replace `var' = min(`var', r(p99)) if year == `y' & `var' != .   // 2026-09-14 (author): guard added
    }
}
mmerge iso3 using `listed', type(n:1) unmatched(master)
replace everlisted = 0 if everlisted == .
qui levelsof iso3, local(L)
di as txt "FDI sample: `: word count `L'' jurisdictions, `=_N' obs (Table 5: 153 / 1,683)"
assert `: word count `L'' == 153
assert _N == 1683
gen fdi_stock_pct = 100 * fdi_m_InwardStock_gnp
gen fdi_flow_pct  = 100 * fdi_m_InwardFlow_gnp
local rows "fdi_stock_pct fdi_flow_pct"
local lab_fdi_stock_pct  "Inward FDI stock, \% of GNI"
local src_fdi_stock_pct  "UNCTAD"
local freq_fdi_stock_pct "Annual"
local per_fdi_stock_pct  "2012--2022"
local fmt_fdi_stock_pct  "%9.1f"
local key_fdi_stock_pct  "fdi_stock"
local lab_fdi_flow_pct  "Inward FDI flow, \% of GNI"
local src_fdi_flow_pct  "UNCTAD"
local freq_fdi_flow_pct "Annual"
local per_fdi_flow_pct  "2012--2022"
local fmt_fdi_flow_pct  "%9.1f"
local key_fdi_flow_pct  "fdi_flow"
* Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
* mean and SD overall, and the means for never- and ever-listed jurisdictions.
foreach v of local rows {
    local cond "`cond_`v''"
    if "`cond'" == "" local cond "1"
    qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
    local nj : word count `L'
    qui sum `v' if !missing(`v') & (`cond')
    local n  = r(N)
    local m  = string(r(mean), "`fmt_`v''")
    local sd = string(r(sd),   "`fmt_`v''")
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
    local m0 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
    local nj0 : word count `L0'
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
    local m1 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
    local nj1 : word count `L1'
    local nfmt = string(`n', "%9.0fc")
    file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
    file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
    di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
}

* --- 2c. Corporate tax rates (new_etr.do, review-design sample: non-EU) --------
use "$input\ITI_CITR_ct_R2.dta", clear
mmerge iso3 using `eu', type(n:1) unmatched(master)
replace eu = 0 if eu == .
mmerge iso3 using `listed', type(n:1) unmatched(master)
replace everlisted = 0 if everlisted == .
keep if year >= 2010
keep if eu == 0
foreach v in SCITR EMTR EATR {
    gen `v'_pct = 100 * `v'_ct
}
file write T "\addlinespace" _n
file write T "\multicolumn{10}{l}{\textbf{B. Corporate tax rates (per cent)}} \\" _n
local rows "SCITR_pct EATR_pct EMTR_pct"
local lab_SCITR_pct  "Statutory CIT rate"
local src_SCITR_pct  "RSIT ITI"
local freq_SCITR_pct "Annual"
local per_SCITR_pct  "2010--2020"
local fmt_SCITR_pct  "%9.1f"
local key_SCITR_pct  "scitr"
local lab_EATR_pct  "Effective average tax rate"
local src_EATR_pct  "RSIT ITI"
local freq_EATR_pct "Annual"
local per_EATR_pct  "2010--2020"
local fmt_EATR_pct  "%9.1f"
local key_EATR_pct  "eatr"
local lab_EMTR_pct  "Effective marginal tax rate"
local src_EMTR_pct  "RSIT ITI"
local freq_EMTR_pct "Annual"
local per_EMTR_pct  "2010--2020"
local fmt_EMTR_pct  "%9.1f"
local key_EMTR_pct  "emtr"
* Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
* mean and SD overall, and the means for never- and ever-listed jurisdictions.
foreach v of local rows {
    local cond "`cond_`v''"
    if "`cond'" == "" local cond "1"
    qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
    local nj : word count `L'
    qui sum `v' if !missing(`v') & (`cond')
    local n  = r(N)
    local m  = string(r(mean), "`fmt_`v''")
    local sd = string(r(sd),   "`fmt_`v''")
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
    local m0 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
    local nj0 : word count `L0'
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
    local m1 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
    local nj1 : word count `L1'
    local nfmt = string(`n', "%9.0fc")
    file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
    file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
    di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
}

* --- 2d. Shifted profits (weir_inport_090425.do: tax havens, Figure 7) --------
import excel "$input\Profit shifting - Nov 2024.xlsx", sheet("Sheet1") firstrow clear
keep if counterpart == "World"
keep if indicator == "shifted_profits"
rename value shifted_profits
keep iso3 year shifted_profits
mmerge iso3 using "$input\zucman_haven.dta", type(n:1) unmatched(master)
gen byte haven = _merge == 3
* keep if haven == 1   // 2026-09-13: all Atlas jurisdictions, as Figure 8 (F08_shifted_profits.do)
mmerge iso3 using `listed', type(n:1) unmatched(master)
replace everlisted = 0 if everlisted == .
file write T "\addlinespace" _n
file write T "\multicolumn{10}{l}{\textbf{C. Location of profits (Atlas jurisdictions)}} \\" _n
local rows "shifted_profits"
local lab_shifted_profits  "Shifted profits booked, USD bn"
local src_shifted_profits  "\shortciteN{torslov2023missing}"
local freq_shifted_profits "Annual"
local per_shifted_profits  "2015--2021"
local fmt_shifted_profits  "%9.1f"
local key_shifted_profits  "shifted"
* Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
* mean and SD overall, and the means for never- and ever-listed jurisdictions.
foreach v of local rows {
    local cond "`cond_`v''"
    if "`cond'" == "" local cond "1"
    qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
    local nj : word count `L'
    qui sum `v' if !missing(`v') & (`cond')
    local n  = r(N)
    local m  = string(r(mean), "`fmt_`v''")
    local sd = string(r(sd),   "`fmt_`v''")
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
    local m0 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
    local nj0 : word count `L0'
    qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
    local m1 = string(r(mean), "`fmt_`v''")
    qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
    local nj1 : word count `L1'
    local nfmt = string(`n', "%9.0fc")
    file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
    file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
    di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
}

* ==============================================================================
* 2b. Tax governance and listing outcomes (author, 2026-09-12): quarterly panels
*     of the governance DiD (D) and the once-measured RD outcomes (E), same
*     columns. Dates in E are the "as of" dates of Table \ref{t:outcomes}.
* ==============================================================================
file write T "\addlinespace" _n
file write T "\multicolumn{10}{l}{\textbf{D. Tax governance outcomes: quarterly panels (used for governance difference-in-differences)}} \\" _n
preserve
    use "$output/rr_A2_gov_panel.dta", clear
    gen byte everlisted = (g_GL > 0 | g_BL > 0)
    * 2026-09-15 (author): governance panels start when each outcome existed (as F06): IF 2016q2, MAP 2016q3, MAA 2010q2
    local rows "inclusive cbcr maa map"
    local lab_inclusive  "IF membership"
    local src_inclusive  "OECD IF list"
    local freq_inclusive "Quarterly"
    local per_inclusive  "2016q2--2022q1"
    local fmt_inclusive  "%9.2f"
    local key_inclusive  "gov_if"
    local cond_inclusive "quarter >= tq(2016q2)"
    local lab_cbcr  "CbC-MCAA signatory"
    local src_cbcr  "OECD CbC MCAA list"
    local freq_cbcr "Quarterly"
    local per_cbcr  "2016q1--2022q1"
    local fmt_cbcr  "%9.2f"
    local key_cbcr  "gov_cbcr"
    local cond_cbcr "quarter >= tq(2016q1)"
    local lab_maa  "MAA convention signatory"
    local src_maa  "OECD Convention status"
    local freq_maa "Quarterly"
    local per_maa  "2010q2--2022q1"
    local fmt_maa  "%9.2f"
    local key_maa  "gov_maa"
    local cond_maa "quarter >= tq(2010q2)"
    local lab_map  "MAP profile published"
    local src_map  "OECD MAP profiles"
    local freq_map "Quarterly"
    local per_map  "2016q3--2022q1"
    local fmt_map  "%9.2f"
    local key_map  "gov_map"
    local cond_map "quarter >= tq(2016q3)"
    * Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
    * mean and SD overall, and the means for never- and ever-listed jurisdictions.
    foreach v of local rows {
        local cond "`cond_`v''"
        if "`cond'" == "" local cond "1"
        qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
        local nj : word count `L'
        qui sum `v' if !missing(`v') & (`cond')
        local n  = r(N)
        local m  = string(r(mean), "`fmt_`v''")
        local sd = string(r(sd),   "`fmt_`v''")
        qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
        local m0 = string(r(mean), "`fmt_`v''")
        qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
        local nj0 : word count `L0'
        qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
        local m1 = string(r(mean), "`fmt_`v''")
        qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
        local nj1 : word count `L1'
        local nfmt = string(`n', "%9.0fc")
        file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
        file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
        di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
    }
restore
file write T "\addlinespace" _n
file write T "\multicolumn{10}{l}{\textbf{E. Tax governance and listing outcomes measured once (all non-EU jurisdictions)}} \\" _n
preserve
    use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
    * 2026-09-12 (author): whole sample with data (all 209 non-EU jurisdictions in the analysis file), not only the RD-eligible set
    gen byte everlisted = ever_either
    merge 1:1 iso3 using "$output/cocg_letters_091026.dta", keep(master match) nogen keepusing(c_1 c_2 c_3 c_4 c_5 c_6 c_7)
    foreach v of varlist c_1 c_2 c_3 c_4 c_5 c_6 c_7 {
        replace `v' = 0 if `v' == .   // no letter on file = no letter (as in Table 3)
    }
    egen any_letter = rowmax(c_1 c_2 c_3 c_4 c_5 c_6 c_7)
    egen cocg_issue = rowmax(c_1 c_3 c_4 c_5 c_6)
    * 2026-09-15: + AEOI On Track outcome (v), transparency mean of (i)-(v) (D11_aeoi_ontrack.do)
    local rows "tax_transparency_now aeoi_2020_now per_EU_now maa_now eoi_now aeoi_ontrack fair_taxation_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now gf_now global_deal_now numstandard_now ever_gl ever_bl ever_either any_letter cocg_issue"
    local lab_tax_transparency_now  "Tax transparency (mean of A.1--A.5)"
    local src_tax_transparency_now  "OECD portals (A.1--A.5)"
    local freq_tax_transparency_now "Once"
    local per_tax_transparency_now  "May 2022"
    local fmt_tax_transparency_now  "%9.2f"
    local key_tax_transparency_now  "rd_taxtransp"
    local lab_aeoi_2020_now  "~~A.1 AEOI commitment"
    local src_aeoi_2020_now  "OECD AEOI portal"
    local freq_aeoi_2020_now "Once"
    local per_aeoi_2020_now  "May 2022"
    local fmt_aeoi_2020_now  "%9.2f"
    local key_aeoi_2020_now  "rd_aeoi"
    local lab_per_EU_now  "~~A.2 Share of EU states with AEOI link"
    local src_per_EU_now  "OECD AEOI portal"
    local freq_per_EU_now "Once"
    local per_per_EU_now  "May 2022"
    local fmt_per_EU_now  "%9.2f"
    local key_per_EU_now  "rd_pereu"
    local lab_maa_now  "~~A.3 MAA convention"
    local src_maa_now  "OECD Convention status"
    local freq_maa_now "Once"
    local per_maa_now  "Feb 2022"
    local fmt_maa_now  "%9.2f"
    local key_maa_now  "rd_maa"
    local lab_eoi_now  "~~A.4 EOIR largely compliant"
    local src_eoi_now  "OECD EOIR ratings"
    local freq_eoi_now "Once"
    local per_eoi_now  "May 2022"
    local fmt_eoi_now  "%9.2f"
    local key_eoi_now  "rd_eoir"
    local lab_aeoi_ontrack  "~~A.5 AEOI rated On Track"
    local src_aeoi_ontrack  "OECD AEOI ratings"
    local freq_aeoi_ontrack "Once"
    local per_aeoi_ontrack  "Dec 2025"   // 2026-09-16 (author): the OECD page date (last updated), as in Table 2, not the extraction date
    local fmt_aeoi_ontrack  "%9.2f"
    local key_aeoi_ontrack  "rd_aeoiontrack"
    local lab_fair_taxation_now  "Fair taxation (B.1)"
    local src_fair_taxation_now  "EU COCG, OECD FHTP"
    local freq_fair_taxation_now "Once"
    local per_fair_taxation_now  "Apr 2021"
    local fmt_fair_taxation_now  "%9.2f"
    local key_fair_taxation_now  "rd_fairtax"
    local lab_anti_beps_now  "Anti-BEPS (mean of C.1--C.3)"
    local src_anti_beps_now  "OECD portals (C.1--C.3)"
    local freq_anti_beps_now "Once"
    local per_anti_beps_now  "May 2022"
    local fmt_anti_beps_now  "%9.2f"
    local key_anti_beps_now  "rd_antibeps"
    local lab_cbcr_s_now  "~~C.1 CbC-MCAA signatory"
    local src_cbcr_s_now  "OECD CbC MCAA list"
    local freq_cbcr_s_now "Once"
    local per_cbcr_s_now  "May 2022"
    local fmt_cbcr_s_now  "%9.2f"
    local key_cbcr_s_now  "rd_cbcr"
    local lab_mil_signed_now  "~~C.2 MLI signatory"
    local src_mil_signed_now  "OECD MLI signatories"
    local freq_mil_signed_now "Once"
    local per_mil_signed_now  "May 2022"
    local fmt_mil_signed_now  "%9.2f"
    local key_mil_signed_now  "rd_mli"
    local lab_map_now  "~~C.3 MAP profile published"
    local src_map_now  "OECD MAP profiles"
    local freq_map_now "Once"
    local per_map_now  "May 2022"
    local fmt_map_now  "%9.2f"
    local key_map_now  "rd_map"
    local lab_if_part_now  "IF membership (I.1)"
    local src_if_part_now  "OECD IF list"
    local freq_if_part_now "Once"
    local per_if_part_now  "Nov 2021"
    local fmt_if_part_now  "%9.2f"
    local key_if_part_now  "rd_if"
    local lab_gf_now  "Global Forum membership (I.2)"
    local src_gf_now  "OECD Global Forum"
    local freq_gf_now "Once"
    local per_gf_now  "May 2022"
    local fmt_gf_now  "%9.2f"
    local key_gf_now  "rd_gf"
    local lab_global_deal_now  "Two-pillar statement signatory"
    local src_global_deal_now  "OECD statement"
    local freq_global_deal_now "Once"
    local per_global_deal_now  "Oct 2021"
    local fmt_global_deal_now  "%9.2f"
    local key_global_deal_now  "rd_globaldeal"
    local lab_numstandard_now  "Number of minimum standards met"
    local src_numstandard_now  "OECD portals (A--C)"
    local freq_numstandard_now "Once"
    local per_numstandard_now  "May 2022"
    local fmt_numstandard_now  "%9.2f"
    local key_numstandard_now  "rd_numstd"
    local lab_ever_gl  "Ever greylisted (I.3)"
    local src_ever_gl  "EU Council"
    local freq_ever_gl "Once"
    local per_ever_gl  "Dec 2017--Feb 2022"
    local fmt_ever_gl  "%9.2f"
    local key_ever_gl  "rd_evergl"
    local lab_ever_bl  "Ever blacklisted (I.4)"
    local src_ever_bl  "EU Council"
    local freq_ever_bl "Once"
    local per_ever_bl  "Dec 2017--Feb 2022"
    local fmt_ever_bl  "%9.2f"
    local key_ever_bl  "rd_everbl"
    local lab_ever_either  "Ever grey or blacklisted (I.5)"
    local src_ever_either  "EU Council"
    local freq_ever_either "Once"
    local per_ever_either  "Dec 2017--Feb 2022"
    local fmt_ever_either  "%9.2f"
    local key_ever_either  "rd_everlisted"
    local lab_any_letter  "COCG deficiency letter received"
    local src_any_letter  "EU COCG letters"
    local freq_any_letter "Once"
    local per_any_letter  "Oct 2017"
    local fmt_any_letter  "%9.2f"
    local key_any_letter  "rd_letter"
    local lab_cocg_issue  "~~Letter raised an issue"
    local src_cocg_issue  "EU COCG letters"
    local freq_cocg_issue "Once"
    local per_cocg_issue  "Oct 2017"
    local fmt_cocg_issue  "%9.2f"
    local key_cocg_issue  "rd_issue"
    * Write one table row (LaTeX) and one CSV row per variable: jurisdictions, observations,
    * mean and SD overall, and the means for never- and ever-listed jurisdictions.
    foreach v of local rows {
        local cond "`cond_`v''"
        if "`cond'" == "" local cond "1"
        qui levelsof iso3 if !missing(`v') & (`cond'), local(L)
        local nj : word count `L'
        qui sum `v' if !missing(`v') & (`cond')
        local n  = r(N)
        local m  = string(r(mean), "`fmt_`v''")
        local sd = string(r(sd),   "`fmt_`v''")
        qui sum `v' if !missing(`v') & (`cond') & everlisted == 0
        local m0 = string(r(mean), "`fmt_`v''")
        qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 0, local(L0)
        local nj0 : word count `L0'
        qui sum `v' if !missing(`v') & (`cond') & everlisted == 1
        local m1 = string(r(mean), "`fmt_`v''")
        qui levelsof iso3 if !missing(`v') & (`cond') & everlisted == 1, local(L1)
        local nj1 : word count `L1'
        local nfmt = string(`n', "%9.0fc")
        file write T "`lab_`v'' & `src_`v'' & `freq_`v'' & `per_`v'' & `nj' & `nfmt' & `m' & `sd' & `m0' & `m1' \\" _n
        file write C `"`key_`v'',"`lab_`v''","`src_`v''","`freq_`v''","`per_`v''",`nj',`n',`m',`sd',`nj0',`m0',`nj1',`m1'"' _n
        di as txt "  `key_`v'': `nj' jurisdictions (`nj0' never / `nj1' ever listed), `n' obs, mean `m', sd `sd'"
    }
restore

file write T "\bottomrule" _n
file write T "\end{tabular}" _n
file write T "\end{adjustbox}" _n
file write T "\begin{flushleft}\scriptsize" _n
file write T "{\bf Notes:}  Table shows outcome data provenance and descriptive statistics for jurisdictions used in both the regression discontinuity and difference-in-difference analyses in Section \ref{sec:results}." _n
file write T "\end{flushleft}" _n
file write T "\end{table}" _n
file close T
file close C
di as txt "Wrote tables/rr_B11_econ_descstats.tex and output/rr_B11_econ_descstats.csv"

* Overleaf copy
if "$otables" != "" copy "$tables/rr_B11_econ_descstats.tex" "$otables/rr_B11_econ_descstats_091226.tex", replace
