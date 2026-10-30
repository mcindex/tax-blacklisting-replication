* F04_first_stage_rd_plots.do  |  FIGURE 4 (f:fsg) first-stage (actual review) and aggregate-outcome fuzzy-RD plots, rule-eligible sample
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; body = do/rr_figs_fuzzy_091226.do (built 2026-09-12 night), estimates identical to that run
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Copied unchanged from do/rr_figs_nonldc_091026.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_figs_fuzzy_091226.do
*
* FUZZY-RD VARIANT (author, 2026-09-12 night) of rr_figs_nonldc_091026.do: same code, with
*   - sample = all non-LDC jurisdictions plus Vanuatu, EXCLUDING the five EU tax
*     transparency agreement jurisdictions (reviewed regardless of score);
*   - review instrumented by crossing the boundary: rdrobust ..., fuzzy(reviewed);
*     the four discretionary reviews (MHL, NIU, NRU, PLW) stay in as non-compliers.
* -> graphs/{fs_1,fs_2,fs_3,tax_transparency_now,fair_taxation_now,anti_beps_now}_fuzzy_euc.png (+ Overleaf *_fuzzy_euc_091226.png); fs_1 (first stage) unchanged in form
* Adopted for the R&R on 2026-09-13; the sharp versions stay in ../do/ and in Overleaf under the _091026 names.
********************************************************************************
*************************************************************************************
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Drawing Figure 4 (a-e) (local linear estiamtes and global estimates for appendix) *
*************************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global graphs  "$project\graphs"
}
local G "$graphs"   // 2026-09-13: project copies (undated) to graphs/; Overleaf gets the _091226 names below

use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
assert selected == reviewed
gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // fuzzy-design sample
keep if elig
replace both = ever_either

* COCG deficiency letters (author, 2026-09-10): indicators built by
* deficiencies_011921.do from input/committment_data.xlsx and saved to
* output/cocg_letters_091026.dta. any_letter = a commitment letter was sent;
* cocg_issue = the letter raised AEOI, Inclusive Framework, harmful tax regime,
* Global Forum membership or MCAA participation (c_1 c_5 c_4 c_3 c_6).
merge 1:1 iso3 using "$output/cocg_letters_091026.dta", keep(master match) nogen
foreach v of varlist c_1 c_2 c_3 c_4 c_5 c_6 c_7 {
    replace `v' = 0 if `v' == .
}
egen any_letter = rowmax(c_1 c_2 c_3 c_4 c_5 c_6 c_7)
egen cocg_issue = rowmax(c_1 c_3 c_4 c_5 c_6)
count if distance < .
di as txt "Eligible sample with a running variable: `r(N)'"

lab var distance      "Distance to boundary (Euclidean)"
lab var distance_homi "Distance to boundary (Manhattan)"

graph set window fontface "LM Roman 10"

*===============================================================================
* PART 1 - main-text figures (within-bandwidth local linear)
*===============================================================================
foreach c in distance {   // 2026-09-12: Euclidean only (Manhattan twins not in the draft)
    if "`c'" == "distance" local sfx euc
    else                   local sfx md
    local k ""      // no running-variable subtitles on any figure (author, 2026-09-10 evening)
   
    *---------------------------------------------------------------------------
    * First stage: selected (fs_1) and grey or blacklisted (fs_2)
    *---------------------------------------------------------------------------
    rdrobust reviewed `c', p(1) kernel(triangular) masspoints(off)   // first stage of the fuzzy design: actual review
    local est_selected_`sfx' : display "First stage: " %4.2f e(tau_cl) " [" %4.2f e(ci_l_rb) ", " %4.2f e(ci_r_rb) "]"
    local bandwidth = e(h_l)
    cap drop rdplot*
    rdplot reviewed `c' if abs(`c') <= `bandwidth', hide genvars p(1)
    twoway (lfitci reviewed `c' if `c' < 0  & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
           (lfitci reviewed `c' if `c' >= 0 & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
           (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <= `bandwidth'), xline(0) ///
           ytitle(Pr(Reviewed by EU)) xtitle(Distance to cutoff) ///
           yscale(range(-.25 1.25)) ylabel(-.25(.25)1.25) ///
           legend(off) scheme(modern)  scale(1.3) ///
           text(1.15 -`bandwidth' "`est_selected_`sfx''", place(e) size(small) box fcolor(white) lcolor(white) margin(vsmall)) ///
           name(s1`c', replace)
    graph export "`G'/fs_1_fuzzy_`sfx'.png", width(3000) replace
    if "$ographs" != "" graph export "$ographs/fs_1_fuzzy_`sfx'_091226.png", width(3000) replace

    rdrobust both `c', p(1) kernel(triangular) masspoints(off) fuzzy(reviewed)
    local est_both_`sfx' : display "Fuzzy RD: " %4.2f e(tau_cl) " [" %4.2f e(ci_l_rb) ", " %4.2f e(ci_r_rb) "]"
    local bandwidth = e(h_l)
    cap drop rdplot*
    rdplot both `c' if abs(`c') <= `bandwidth', hide genvars p(1)
    twoway (lfitci both `c' if `c' < 0  & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(red) alcolor(%0) fcolor(red%30)) ///
           (lfitci both `c' if `c' >= 0 & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(red) alcolor(%0) fcolor(red%30)) ///
           (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <= `bandwidth', mcolor(cranberry)), xline(0) ///
           ytitle(Pr(Grey or blacklisted by EU)) xtitle(Distance to cutoff) ///
           yscale(range(-.25 1.25)) ylabel(-.25(.25)1.25) ///
           legend(off) scheme(modern)  scale(1.3) ///
           text(1.15 -`bandwidth' "`est_both_`sfx''", place(e) size(small) box fcolor(white) lcolor(white) margin(vsmall)) ///
           name(s2`c', replace)
    graph export "`G'/fs_2_fuzzy_`sfx'.png", width(3000) replace
    if "$ographs" != "" graph export "$ographs/fs_2_fuzzy_`sfx'_091226.png", width(3000) replace

    * third first-stage panel (author, 2026-09-10): COCG raised an issue in its commitment letter
    rdrobust cocg_issue `c', p(1) kernel(triangular) masspoints(off) fuzzy(reviewed)
    local bandwidth = e(h_l)
    local est_cocg_issue_`sfx' : display "Fuzzy RD: " %4.2f e(tau_cl) " [" %4.2f e(ci_l_rb) ", " %4.2f e(ci_r_rb) "]"
    cap drop rdplot*
    rdplot cocg_issue `c' if abs(`c') <= `bandwidth', hide genvars p(1)
    twoway (lfitci cocg_issue `c' if `c' < 0  & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(dkorange) alcolor(%0) fcolor(orange%30)) ///
           (lfitci cocg_issue `c' if `c' >= 0 & abs(`c') <= `bandwidth', level(95) estopts(robust) lcolor(dkorange) alcolor(%0) fcolor(orange%30)) ///
           (scatter rdplot_mean_y rdplot_mean_x if abs(rdplot_mean_x) <= `bandwidth', mcolor(dkorange)), xline(0) ///
           ytitle(Pr(COCG raised an issue)) xtitle(Distance to cutoff) ///
           yscale(range(-.25 1.25)) ylabel(-.25(.25)1.25) ///
           legend(off) scheme(modern) subtitle(`k') scale(1.3) ///
           text(1.15 -`bandwidth' "`est_cocg_issue_`sfx''", place(e) size(small) box fcolor(white) lcolor(white) margin(vsmall)) ///
           name(s3`c', replace)
    graph export "`G'/fs_3_fuzzy_`sfx'.png", width(3000) replace
    if "$ographs" != "" graph export "$ographs/fs_3_fuzzy_`sfx'_091226.png", width(3000) replace

    *---------------------------------------------------------------------------
    * Aggregate outcomes (as final_graphs_042822.do, paper versions)
    *---------------------------------------------------------------------------
    local yt_tax_transparency_now "Tax transparency (mean)"
    local yt_fair_taxation_now    "Fair taxation (mean)"
    local yt_anti_beps_now        "Anti-BEPS (mean)"
    local yt_if_part_now          "Pr(member of Inclusive Framework)"
    local yt_ifp_20820            "Pr(member of Inclusive Framework)"

    foreach y in tax_transparency_now fair_taxation_now anti_beps_now {   // 2026-09-12: IF panels not in the draft   // ifp_20820 = IF membership Jan 2017 (Figure A11a), added 2026-09-10
        cap drop w
            rdrobust `y' `c', p(1) kernel(triangular) masspoints(off) fuzzy(reviewed)
    local est_`y'_`sfx' : display "Fuzzy RD: " %4.2f e(tau_cl) " [" %4.2f e(ci_l_rb) ", " %4.2f e(ci_r_rb) "]"
        local bandwidth = e(h_l)
        gen w = .
        replace w = (1 - abs(`c' / `bandwidth')) if `c' < 0  & `c' >= -`bandwidth'
        replace w = (1 - abs(`c' / `bandwidth')) if `c' >= 0 & `c' <=  `bandwidth'
        cap drop rdplot*
        if "`y'" == "fair_taxation_now" local bs binselect(qsmv)
        else                            local bs
        rdplot `y' `c' if abs(`c') <= `bandwidth', hide genvars p(1) `bs'

        if inlist("`y'", "if_part_now", "ifp_20820") local wt
        else                      local wt "[aw = w]"

        twoway (lfitci `y' `c' if `c' < 0  & abs(`c') <= `bandwidth' `wt', level(95) estopts(robust) lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
               (lfitci `y' `c' if `c' >= 0 & abs(`c') <= `bandwidth' `wt', level(95) estopts(robust) lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
               (scatter rdplot_mean_y rdplot_mean_x, mcolor(blue%75) mlcolor(%0)), xline(0) ///
               ytitle(`yt_`y'') xtitle(Distance to cutoff) ///
               yscale(range(0 1.3)) ylabel(0(.2)1) xscale(range(-20 20)) ///
               legend(off) scheme(modern)  scale(1.3) ///
               text(1.25 -19 "`est_`y'_`sfx''", place(e) size(small) box fcolor(white) lcolor(white) margin(vsmall)) ///
               name(g_`y'_`sfx', replace)
        graph export "`G'/`y'_fuzzy_`sfx'.png", replace width(2000)
        if "$ographs" != "" graph export "$ographs/`y'_fuzzy_`sfx'_091226.png", replace width(2000)
    }
}

*===============================================================================
* PART 2 - appendix figures: full-support rdplot, global polynomial (order 4)
*===============================================================================
