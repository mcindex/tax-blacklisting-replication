* F09_T06_harmful_regimes.do  |  FIGURE 9 (f:rev) + TABLE 6 (t:rev) detection and rollback of harmful regimes, fuzzy RD
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; body = do/rr_fig8_t6_fuzzy_091226.do (built 2026-09-12 night), estimates identical to that run
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Copied unchanged from do/rr_fig8_t6_091026.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_fig8_t6_fuzzy_091226.do
*
* FUZZY-RD VARIANT (author, 2026-09-12 night) of rr_fig8_t6_091026.do: same code, with
*   - sample = all non-LDC jurisdictions plus Vanuatu, EXCLUDING the five EU tax
*     transparency agreement jurisdictions (reviewed regardless of score);
*   - review instrumented by crossing the boundary: rdrobust ..., fuzzy(reviewed_eu);
*     the four discretionary reviews (MHL, NIU, NRU, PLW) stay in as non-compliers.
* -> graphs/{identified,harmful,rollback}_{cocg,oecd}_fuzzy_euc.png (+ Overleaf *_fuzzy_euc_091226.png), tables/rr_nharmful_fuzzy_euc.tex (+ Overleaf rr_nharmful_fuzzy_euc_091226.tex)
* Adopted for the R&R on 2026-09-13; the sharp versions stay in ../do/ and in Overleaf under the _091026 names.
********************************************************************************
********************************************************************************
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* rr_fig8_t6_091026.do
*
* Figure 8 (f:rev) RD plots and Table 6 (t:rev, harmful-regime detection and
* rollback) re-estimated on the RULE-ELIGIBLE sample (non-LDC plus Vanuatu)
* with the headline (Euclidean) running variable, sharp reduced form, to match
* the revised Table 3 and the rr_figs_nonldc_091026.do figures. Author
* request 2026-09-10. The original pipeline file
* input_eu_harmful_updated_042922.do (Manhattan RV, fuzzy(selected), covs(ldc
* lngdppcn_2015), live regready file) is left untouched; this file rebuilds
* the six outcomes from its saved intermediates exactly as it does:
*   identified_{cocg,oecd}  = at least one regime reviewed by the COCG / FHTP
*   harmful_cocg   = any_harmful & identified_cocg
*   harmful_oecd   = (any_harmful & identified_oecd) | (harmful & reviewed_oecd)
*   rollback_cocg  = any_rollback & identified_cocg
*   rollback_oecd  = (any_rollback & identified_oecd) | (changed & reviewed_oecd)
* Figures: within-bandwidth local linear (robust 95% bands), rdplot bin means,
* "Fuzzy RD: b [95% robust CI]" top-left. Table: conventional coefficient
* with robust 95% CI, without / with log GDP pc 2015, revised-Table-3 layout.
*
* -> graphs/{identified,harmful,rollback}_{cocg,oecd}_nonldc_euc.png
*    tables/rr_nharmful_sharp_euc.tex (label t:rev), output/rr_fig8_t6_fuzzy_estimates.csv
* 2026-09-12: bands 90% -> 95% (author: 95% CIs everywhere; stars 10/5/1%),
*    subtitles dropped, Overleaf exports added (_091026 names, png + pdf).
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global graphs  "$project\graphs"
    global tables  "$project\tables"
}
cap graph set window fontface "LM Roman 10"

*-------------------------------------------------------------------------------
* Data: frozen file + harmful-regime intermediates
*-------------------------------------------------------------------------------
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
keep iso3 status distance distance_homi z_distance x_distance y_distance ldc lngdppcn_2015 selected reviewed
rename reviewed reviewed_eu
merge 1:1 iso3 using "$output/harm_043022.dta", keep(master match) nogen ///
    keepusing(identified_oecd_now identified_cocg_now any_harmful_now any_rollback_now)
rename (identified_oecd_now identified_cocg_now any_harmful_now any_rollback_now) ///
       (identified_oecd identified_cocg any_harmful any_rollback)
merge 1:1 iso3 using "$output/oecd_review_043022.dta", keep(master match) nogen ///
    keepusing(reviewed changed harmful)
rename reviewed reviewed_oecd
foreach v in identified_oecd identified_cocg any_harmful any_rollback reviewed_oecd changed harmful {
    replace `v' = 0 if `v' == .
}
* as in input_eu_harmful_updated_042922.do (after its oecd merge)
replace identified_oecd = 1 if reviewed_oecd == 1
replace any_rollback    = 1 if changed == 1
gen harmful_oecd  = (any_harmful  == 1 & identified_oecd == 1) | (harmful == 1 & reviewed_oecd == 1)
gen rollback_oecd = (any_rollback == 1 & identified_oecd == 1) | (changed == 1 & reviewed_oecd == 1)
gen harmful_cocg  = (any_harmful  == 1 & identified_cocg == 1)
gen rollback_cocg = (any_rollback == 1 & identified_cocg == 1)

gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // fuzzy-design sample
keep if elig
count if distance < .
di as txt "Rule-eligible sample with a running variable: `r(N)'"

local rv distance
local yt_identified_oecd "Pr(Regime reviewed)"
local yt_harmful_oecd    "Pr(Regime found harmful)"
local yt_rollback_oecd   "Pr(Regime rolled back)"
local yt_identified_cocg "Pr(Regime reviewed)"
local yt_harmful_cocg    "Pr(Regime found harmful)"
local yt_rollback_cocg   "Pr(Regime rolled back)"
local st_identified_oecd "Review"
local st_harmful_oecd    "Review + Detection"
local st_rollback_oecd   "Review + Detection + Rollback"
local st_identified_cocg "Review"
local st_harmful_cocg    "Review + Detection"
local st_rollback_cocg   "Review + Detection + Rollback"

*-------------------------------------------------------------------------------
* Estimates (table) and figures
*-------------------------------------------------------------------------------
tempname P
postfile `P' str16 outcome byte col double b se_rb p_rb lo hi h int nl nr N using "$output/rr_fig8_t6_fuzzy_estimates.dta", replace

foreach y in identified_cocg identified_oecd harmful_cocg harmful_oecd rollback_cocg rollback_oecd {
    * (1) no controls  (2) log GDP pc 2015
    foreach c in 1 2 {
        if `c' == 1 local cv
        else        local cv covs(lngdppcn_2015)
        rdrobust `y' `rv', c(0) p(1) kernel(triangular) all masspoints(off) `cv' fuzzy(reviewed_eu)
        post `P' ("`y'") (`c') (e(tau_cl)) (e(se_tau_rb)) (e(pv_rb)) (e(ci_l_rb)) (e(ci_r_rb)) (e(h_l)) (e(N_h_l)) (e(N_h_r)) (e(N))
        if `c' == 1 {
            local bandwidth = e(h_l)
            local est : display "Fuzzy RD: " %4.2f e(tau_cl) " [" %4.2f e(ci_l_rb) ", " %4.2f e(ci_r_rb) "]"
        }
    }
    * figure (no controls), style of rr_figs_nonldc_091026.do
    if strpos("`y'", "cocg") local col cranberry
    else                     local col blue
    cap drop rdplot*
    rdplot `y' `rv' if abs(`rv') <= `bandwidth', hide genvars p(1)
    twoway (lfitci `y' `rv' if `rv' < 0  & abs(`rv') <= `bandwidth', level(95) estopts(robust) lcolor(`col') fcolor(`col'%30) alcolor(%0)) ///
           (lfitci `y' `rv' if `rv' >= 0 & abs(`rv') <= `bandwidth', level(95) estopts(robust) lcolor(`col') fcolor(`col'%30) alcolor(%0)) ///
           (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <= `bandwidth', mcolor(`col'%75) mlcolor(%0)), xline(0) ///
           yline(0, lpattern(solid) lcolor(gs10)) ///
           ytitle(`yt_`y'') xtitle(Distance to cutoff) ///
           yscale(range(-0.2 1.1)) ylabel(-.2(.2)1) ///
           text(1.05 -`bandwidth' "`est'", place(e) size(small) box fcolor(white) lcolor(white) margin(vsmall)) ///
           legend(off) scheme(modern) scale(2) name(g_`y', replace)
    graph export "$graphs/`y'_fuzzy_euc.png", replace width(2000)
    if "$ographs" != "" graph export "$ographs/`y'_fuzzy_euc_091226.png", replace width(2000)   // Overleaf (name used by itax_rr_1.tex)
* [off 2026-09-12]     if "$ographs" != "" graph export "$ographs/`y'_fuzzy_euc_091226.pdf", replace
}
postclose `P'

*-------------------------------------------------------------------------------
* Table (revised Table 3 layout: coefficient with stars, [95% robust CI])
*-------------------------------------------------------------------------------
use "$output/rr_fig8_t6_fuzzy_estimates.dta", clear
export delimited using "$output/rr_fig8_t6_fuzzy_estimates.csv", replace
gen stars = cond(p_rb < .01, "***", cond(p_rb < .05, "**", cond(p_rb < .10, "*", "")))
list outcome col b lo hi h nl nr N stars, clean noobs

local R_identified_cocg "\hspace{.4cm} EU Code of Conduct Group"
local R_identified_oecd "\hspace{.4cm} OECD Forum on Harmful Tax Practices"
local R_harmful_cocg    "\hspace{.4cm} EU Code of Conduct Group"
local R_harmful_oecd    "\hspace{.4cm} OECD Forum on Harmful Tax Practices"
local R_rollback_cocg   "\hspace{.4cm} EU Code of Conduct Group"
local R_rollback_oecd   "\hspace{.4cm} OECD Forum on Harmful Tax Practices"
local H_identified_cocg "\emph{{\bf (A) At least one regime reviewed by:}}"
local H_harmful_cocg    "\midrule \emph{{\bf (B) Regime reviewed and found harmful by:}}"
local H_rollback_cocg   "\midrule \emph{{\bf (C) Regime reviewed and rolled back after review by:}}"

foreach c in 1 2 {
    qui sum N if col == `c'
    local N`c' = r(min)
    qui sum h if col == `c'
    local hm`c' : display %3.1f r(mean)
    local hmin`c' : display %3.1f r(min)
    local hmax`c' : display %3.1f r(max)
    qui gen ne = nl + nr
    qui sum ne if col == `c'
    local ne`c' : display %3.0f r(mean)
    drop ne
}

file open T using "$tables/rr_nharmful_fuzzy_euc.tex", write replace
file write T "\begin{table}[t]\centering" _n
file write T "\caption{Impact of EU review on the probability of detection and rollback of harmful regimes\label{t:rev}}" _n
file write T "\begin{adjustbox}{max width=\textwidth}" _n
file write T "\begin{tabular}{l*{4}{c}}" _n "\toprule" _n
file write T "&\multicolumn{2}{c}{(1)}&\multicolumn{2}{c}{(2)}\\" _n
file write T "&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}\\" _n
file write T "\midrule" _n
foreach y in identified_cocg identified_oecd harmful_cocg harmful_oecd rollback_cocg rollback_oecd {
    if "`H_`y''" != "" file write T "`H_`y''&&&&\\" _n
    file write T "`R_`y''"
    foreach c in 1 2 {
        qui sum b  if outcome == "`y'" & col == `c'
        local bb : display %4.2f r(mean)
        qui sum lo if outcome == "`y'" & col == `c'
        local ll : display %4.2f r(mean)
        qui sum hi if outcome == "`y'" & col == `c'
        local hh : display %4.2f r(mean)
        qui levelsof stars if outcome == "`y'" & col == `c', local(ss) clean
        file write T "& `bb'`ss' & [`ll', `hh']"
    }
    file write T "\\" _n
}
file write T "\midrule Controls&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}\\" _n
file write T "Observations&\multicolumn{2}{c}{`N1'}&\multicolumn{2}{c}{`N2'}\\" _n
file write T "Avg Effective \# Obs&\multicolumn{2}{c}{`ne1'}&\multicolumn{2}{c}{`ne2'}\\" _n
file write T "Avg Bandwidth&\multicolumn{2}{c}{`hm1'}&\multicolumn{2}{c}{`hm2'}\\" _n
file write T "Max Bandwidth&\multicolumn{2}{c}{`hmax1'}&\multicolumn{2}{c}{`hmax2'}\\" _n
file write T "Min Bandwidth&\multicolumn{2}{c}{`hmin1'}&\multicolumn{2}{c}{`hmin2'}\\" _n
file write T "\bottomrule" _n "\end{tabular}" _n "\end{adjustbox}" _n
file write T "\begin{minipage}{1\textwidth} \scriptsize" _n
file write T "{\bf Notes:} Fuzzy RD estimates of the effect of selection for review, with crossing the selection boundary as the instrument, on the sample of jurisdictions eligible for review (all non-LDC jurisdictions plus Vanuatu, excluding the five jurisdictions reviewed under EU tax transparency agreements), using the distance to the selection boundary as running variable. Outcomes are indicators for whether a jurisdiction had at least one preferential regime reviewed by the entity, whether at least one reviewed regime was found harmful, and whether at least one reviewed regime was rolled back, separately for the EU Code of Conduct Group (COCG) and the OECD Forum on Harmful Tax Practices (FHTP). Conventional local-linear coefficients with robust bias-corrected 95\% confidence intervals \cite{calonico2014robust}, MSE-optimal bandwidths, triangular kernel. Column (2) adds log GDP per capita in 2015. \$^{*}p<0.10\$, \$^{**}p<0.05\$, \$^{***}p<0.01\$ (robust \$p\$-values)." _n
file write T "\end{minipage}" _n "\end{table}" _n
file close T
type "$tables/rr_nharmful_fuzzy_euc.tex"
if "$otables" != "" copy "$tables/rr_nharmful_fuzzy_euc.tex" "$otables/rr_nharmful_fuzzy_euc_091226.tex", replace   // Overleaf (name used by itax_rr_1.tex)
