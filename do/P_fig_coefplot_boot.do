* P_fig_coefplot_boot.do  |  PENDING wild-bootstrap version of Figure 5 (fuzzy RD, rr_t3_coefplot_boot_091326)
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Copied unchanged from do/rr_t3_coefplot_boot_091026.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_t3_coefplot_boot_091026.do  (wild-bootstrap version of rr_t3_coefplot_091026.do)
*
* Coefficient-plot version of the revised Table 3 (author request 2026-09-10):
* fuzzy RD on the rule-eligible sample, headline (Euclidean) running variable,
* within-bandwidth 2SLS, without and with the log GDP per capita 2015 control.
* Reads the wild-bootstrap estimates written by rd_regressions_042722_boottest.do
* (output/rr_boot_estimates_091326.csv; Table A4): conventional coefficient with
* the boottest SE and (2026-09-14) boottest's inverted 95% CI - nothing is re-estimated here. Outcomes are
* grouped exactly as in the table. Conventional coefficient, robust 95% CI.
*
* Prints the figure-note statistics (sample size, effective observations,
* bandwidths, controls) to the log at the end.
*
* -> graphs/rr_t3_coefplot.png, graphs/rr_t3_coefplot.pdf
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global graphs  "$project\graphs"
}
cap graph set window fontface "LM Roman 10"
confirm file "$output/rr_boot_estimates_091326.csv"

* outcome order and labels, as in the table
local outcomes "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either any_letter cocg_issue numstandard_now"
local L_tax_transparency_now `""Mean outcome""'
local L_aeoi_2020_now        `""(i) CRS commitment by 2023""'
local L_per_EU_now           `""(ii) Share of EU covered by AEOI""'
local L_eoi_now              `""(iii) Largely compliant on EOIR""'
local L_maa_now              `""(iv) Signed up to MAA""'
local L_aeoi_ontrack         `""(v) AEOI rated On Track""'   // 2026-09-15: + AEOI On Track outcome (v), transparency mean of (i)-(v) (D11_aeoi_ontrack.do)
local L_fair_taxation_now    `""Mean outcome""'
local L_harm_now             `""(i) Reviewed w/ no harmful regimes""'
local L_anti_beps_now        `""Mean outcome""'
local L_cbcr_s_now           `""(i) Signed up to CbCR""'
local L_mil_signed_now       `""(ii) Signed up to MLI""'
local L_map_now              `""(iii) Published MAP profile""'
local L_if_part_now          `""Participation in IF""'
local L_global_deal_now      `""Signed up to global deal""'
local L_gf_now               `""Signed up to Global Forum""'
local L_ever_gl              `""Ever greylisted""'
local L_ever_bl              `""Ever blacklisted""'
local L_ever_either          `""Ever grey or blacklisted""'
local L_any_letter           `""Letter sent by COCG""'
local L_cocg_issue           `""COCG raised an issue""'
local L_numstandard_now      `""Number of minimum standards""'

* 2026-09-10 (author): two series only; number of minimum standards (count
* outcome, interval -1.3 to 3.2) dropped from the plot - it stays in the table.
local outcomes : subinstr local outcomes "numstandard_now" "", all
import delimited using "$output/rr_boot_estimates_091326.csv", clear varnames(1) case(preserve)
keep if rv == "distance" & outcome != "numstandard_now"
gen col = cond(ctype == "ncv", 1, 2)
rename b tau_cl
rename neff n_eff
rename h bw_h
* 2026-09-14: 95% CI = boottest's inverted bootstrap-t CI (ci_bt_lo/hi, as the table rd_regs_bot_091426.tex);
* the normal approximation b +/- z * se_boot is kept as the fallback and for the 90% level
gen ci95_lo = tau_cl - invnormal(0.975) * se_boot
gen ci95_hi = tau_cl + invnormal(0.975) * se_boot
capture confirm variable ci_bt_lo ci_bt_hi
if _rc == 0 {
    replace ci95_lo = ci_bt_lo if ci_bt_lo < .
    replace ci95_hi = ci_bt_hi if ci_bt_hi < .
}
gen ci90_lo = tau_cl - invnormal(0.95)  * se_boot
gen ci90_hi = tau_cl + invnormal(0.95)  * se_boot
gen ord = .
local i = 1
foreach o of local outcomes {
    replace ord = `i' if outcome == "`o'"
    local ++i
}
assert ord != .
sort col ord

* row vectors for coefplot: coefficient, lower and upper robust CI, split
* into "significant" (robust CI excludes zero: solid marker) and "not
* significant" (hollow marker) - author, 2026-09-10. `cilev' toggles the
* level (95 or 90; the table reports 95% CIs with stars at 10/5/1%).
local cilev 95
foreach c in 1 2 {
    preserve
    keep if col == `c'
    sort ord
    gen byte sig = (ci`cilev'_lo > 0 | ci`cilev'_hi < 0)
    foreach g in S N {
        if "`g'" == "S" local cond "sig == 1"
        else            local cond "sig == 0"
        gen bb  = cond(`cond', tau_cl,  .)
        gen llo = cond(`cond', ci`cilev'_lo, .)
        gen hhi = cond(`cond', ci`cilev'_hi, .)
        mkmat bb,  matrix(b`g'`c')
        mkmat llo, matrix(lo`g'`c')
        mkmat hhi, matrix(hi`g'`c')
        drop bb llo hhi
        foreach m in b lo hi {
            matrix `m'`g'`c' = `m'`g'`c''
            matrix colnames `m'`g'`c' = `outcomes'
        }
    }
    restore
}

local cl ""
foreach o of local outcomes {
    local cl `"`cl' `o' = `L_`o''"'
}

local c1 "blue"
local c2 "red"
coefplot (matrix(bS1), ci((loS1 hiS1)) msymbol(O)  mcolor(`c1') ciopts(lcolor(`c1') lwidth(medthick))) ///
         (matrix(bN1), ci((loN1 hiN1)) msymbol(Oh) mcolor(`c1'%60) ciopts(lcolor(`c1'%60))) ///
         (matrix(bS2), ci((loS2 hiS2)) msymbol(D)  mcolor(`c2') ciopts(lcolor(`c2') lwidth(medthick))) ///
         (matrix(bN2), ci((loN2 hiN2)) msymbol(Dh) mcolor(`c2'%60) ciopts(lcolor(`c2'%60))), ///
    coeflabels(`cl', labsize(small)) ///
    headings(tax_transparency_now = "{bf:(A) Tax transparency}" ///
             fair_taxation_now    = "{bf:(B) Fair taxation}" ///
             anti_beps_now        = "{bf:(C) Anti-BEPS}" ///
             if_part_now          = "{bf:Intermediate outcomes}" ///
             any_letter           = "{bf:COCG deficiency letters}", labsize(medsmall) labcolor(black) gap(2)) ///
    graphregion(margin(l=10 r=4)) ///
    xline(0, lpattern(dash) lcolor(gs8)) xtitle("RD estimate (`cilev'% CI, wild bootstrap)") ///
    legend(order(2 "No controls" 6 "Log GDP per capita, 2015") rows(1) position(6) size(small) symxsize(6)) ///
    grid(none) scheme(modern) ysize(9) xsize(9) scale(0.8) ///
    name(t3coefboot, replace)
graph export "$graphs/rr_t3_coefplot_boot.png", replace width(2400)
graph export "$graphs/rr_t3_coefplot_boot.pdf", replace
* [off 2026-09-12] if "$ographs" != "" graph export "$ographs/rr_t3_coefplot_boot_091326.png", replace width(2400)
if "$ographs" != "" graph export "$ographs/rr_t3_coefplot_boot_091326.pdf", replace

*-------------------------------------------------------------------------------
* Figure-note statistics (copy into the caption)
*-------------------------------------------------------------------------------
tempfile est
save `est'
use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
qui count if elig & distance < .
local N1 = r(N)
qui count if elig & distance < . & lngdppcn_2015 < .
local N2 = r(N)
use `est', clear

di _n(2) as res "=== Figure-note statistics: wild-bootstrap coefficient plot (Table A4) ==="
di as txt "Sample: rule-eligible jurisdictions (all non-LDC jurisdictions plus Vanuatu) with a scoreboard running variable."
di as txt "Design: fuzzy RD (review instrumented by crossing the boundary; within-bandwidth 2SLS), local linear, triangular kernel, MSE-optimal bandwidth (rdrobust, masspoints off);"
di as txt "        solid markers: `cilev'% robust CI excludes zero; hollow markers: CI includes zero. Number of minimum standards omitted (see table);"
di as txt "        markers = conventional coefficient, whiskers = boottest's inverted bootstrap-t 95% CI (Roodman et al. 2019; 2SLS / OLS inside the MSE bandwidth, one cluster per jurisdiction). [2026-09-14: was b +/- z * bootstrap SE]"
foreach c in 1 2 {
    qui sum n_eff if col == `c'
    local ne : display %4.0f r(mean)
    qui sum bw_h if col == `c'
    local hm : display %4.1f r(mean)
    local hmin : display %4.1f r(min)
    local hmax : display %4.1f r(max)
    if `c' == 1 di as txt "Series 1 (no controls):        N = `N1'; avg effective obs = `ne'; bandwidth avg `hm' (min `hmin', max `hmax')."
    else        di as txt "Series 2 (log GDP pc 2015):    N = `N2'; avg effective obs = `ne'; bandwidth avg `hm' (min `hmin', max `hmax')."
}
di as txt "Mean outcome = average of the sub-outcomes in that category. 'Reviewed w/ no harmful regimes' is the only fair-taxation sub-outcome."
di as txt "Source estimates: output/rr_boot_estimates_091326.csv (rd_regressions_042722_boottest.do), distance columns ncv/cv."
