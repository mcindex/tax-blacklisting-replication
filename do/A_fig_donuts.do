* A_fig_donuts.do  |  APPENDIX f:donuts donut fuzzy RD (two figures, _091326)
* 2026-09-15: rewritten for legibility (matrix program a1mat replaced by an annotated inline loop; output unchanged). Backup do/old/replication_rr_pre_legibility_091526/
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* Copied unchanged from do/rr_A1_donut_081926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_A1_donut_081926.do
* R&R item A1 (rr_plan.md): donut-RD robustness for anticipatory behavior
* near the cutoff (Referee 2, comment #2).
*
* Logic: unselected jurisdictions just below the cutoff may reform
* pre-emptively (threat-of-listing channel), contaminating the control group
* and attenuating the RD estimates. The donut test drops observations within
* 1 and then 2 points of the cutoff -- where anticipation should be strongest
* -- and re-runs the headline specifications. (A 3-point donut was tried and
* dropped: SEs blow up, esp. for the SF design where it removes 12 of 28
* in-bandwidth countries. See do/old/rr_A1_donut_081926_20260819_v3_donut3.do)
*
* Two bandwidth treatments per donut:
*   (a) "auto":  MSE-optimal bandwidth re-selected on the donut sample
*                (standard practice, cf. Barreca et al. 2011). Specs where
*                the selected bandwidth leaves too few observations fail and
*                are dropped (logged as missing in the CSV).
*   (b) "fixed": h and b held at the values selected in the baseline
*                (donut = 0) spec, so the estimation window is identical to
*                the baseline with the donut hole cut out. Feasible for all
*                specs (min baseline h = 6.23 > 3). Isolates the effect of
*                dropping near-cutoff countries from bandwidth re-selection.
*
* Running variables: distance_homi (multidimensional cutoff, Manhattan)
*                    distance      (multidimensional cutoff, Euclidean)
*                    z_distance    (stability-factors cutoff)
* Outcomes: mean outcomes for (A) tax transparency, (B) fair taxation,
*           (C) anti-BEPS; number of minimum standards; participation in IF.
* Specs: reduced form and fuzzy RD, with baseline covariates (ldc, log GDP
*        pc 2015), mirroring the covariate columns of Table 3
*        (rd_regressions_042722.do).
*
* Inputs:  $output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta  (see note 2 below)
* Outputs: $graphs/rr_A1_donut_MD.png              (distance_homi, auto bw)
*          $graphs/rr_A1_donut_MDeuclid.png        (distance, auto bw)
*          $graphs/rr_A1_donut_SF.png              (z_distance, auto bw)
*          $graphs/rr_A1_donut_MD_fixedh.png       (fixed baseline bw)
*          $graphs/rr_A1_donut_MDeuclid_fixedh.png (fixed baseline bw)
*          $graphs/rr_A1_donut_SF_fixedh.png       (fixed baseline bw)
*          $output/rr_A1_donut_estimates.csv (bw_method = auto/fixed;
*              fixed rows exist for donut 1/2 only -- donut 0 is shared)
*
* Notes: a 1-2 point donut is a modest share of the MD bandwidth (~15) but a
* large share of the SF bandwidth (~6.15, 28 jurisdictions), so expect the SF
* estimates to lose precision quickly under bandwidth re-selection.
********************************************************************************

********************************************************************************
* REVISED 2026-08-20 (previous version: do/old/rr_A1_donut_081926_20260820.do)
*
* 1. REPORTING CONVENTION. Originally this file reported e(tau_bc) with
*    e(se_tau_rb), mirroring the submitted Table 3. The R&R adopts the
*    conventional presentation instead, so estimates are now reported as
*         coefficient = e(tau_cl)      (conventional local-linear estimate)
*         interval    = robust bias-corrected 95% CI
*                     = e(tau_bc) +/- invnormal(.975)*e(se_tau_rb)
*    matching tables/rd_regs042822_combined_RR_TABLE.tex (which uses 95% CIs;
*    the plots used 90% per author decision 2026-08-20; 95% since 2026-09-12).
*    NOTE: robust intervals are centred on the BIAS-CORRECTED estimate, so the
*    plotted marker (tau_cl) is deliberately NOT at the centre of its whiskers.
*    This is the Calonico-Cattaneo-Farrell-Titiunik convention, not an error,
*    and must be stated in the figure note. Both p-values and both point
*    estimates are kept in the CSV so either presentation can be recovered.
*
* 2. FROZEN DATA. Reads the frozen World Bank vintage rather than the live
*    pipeline output, because lngdppcn_2015 (used by every spec here via
*    covs($covariates)) is pulled from the WB API at rd1_042822.do:31 and
*    therefore moves between runs. See master.do §13c.
*
* 3. PLOTS ARE NO LONGER BUILT VIA erepost. The old code ran a shell OLS and
*    swapped in the rdrobust numbers so coefplot could read stored estimates;
*    that trick fails SILENTLY when erepost is unavailable (it is exactly how
*    the main Table 3 output was corrupted -- see replicate.md). Plots are now
*    built from explicit matrices of (coef, ci_lo, ci_hi), which also allows
*    the off-centre robust interval above.
********************************************************************************

use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
* 2026-09-10 (R&R): rule-eligible sample, reduced form only, Euclidean + z-frontier running variables
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
lab var z_frontier "Stability factors cutoff (frontier)"

* Baseline spec pieces (identical to rd_regressions_042722.do)
global covariates "lngdppcn_2015"   // 2026-09-10: ldc dropped (Vanuatu-only after the restriction)
global iv "fuzzy(reviewed)"   // 2026-09-13: actual review
global rf ""

* Outcomes for the donut test (order fixed: o1-o5 below depend on it)
global A1_outcomes "tax_transparency_now fair_taxation_now anti_beps_now numstandard_now if_part_now"

* Above-cutoff dummies (dropped before regready_042822.dta was saved)
capture drop *_above
foreach d in z_distance distance distance_homi z_frontier {
    gen     `d'_above = `d' >= 0
    replace `d'_above = . if `d' == .
}


***************
* Estimation  *
***************

* Log every estimate to a CSV for the write-up / response letter
tempfile results
* coef_cl / se_cl / pval_cl : conventional estimate, SE and p-value (reported)
* coef_bc / se_rb / pval_rb : bias-corrected estimate with robust SE and
*                             p-value (the old convention; retained so the
*                             previous presentation can be recovered)
* ci95_lo_rb / ci95_hi_rb   : robust bias-corrected 95% CI, centred on coef_bc
postfile A1post str16 rv str4 spec byte donut str5 bw_method str24 outcome ///
    double(coef_cl se_cl pval_cl coef_bc se_rb pval_rb ci95_lo_rb ci95_hi_rb bw_h n_eff) ///
    using `results'

* Store-and-post helper is inlined below; est name prefixes:
*   A1_  = auto bandwidth (donut 0 doubles as the fixed-h baseline)
*   A1f_ = fixed baseline bandwidth (donut 1/2 only)

foreach dtype in distance z_frontier {   // 2026-09-10: was distance_homi distance z_distance
    foreach atype in iv {   // 2026-09-13: fuzzy(reviewed) (was rf = sharp reduced form since 2026-09-10)
        local c = 1
        foreach var of varlist $A1_outcomes {
            local h0 = .
            local b0 = .
            foreach k in 0 1 2 {												// k is the donut width, we do 1 and 2 units in each case

                * ---- (a) automatic bandwidth, re-selected on donut sample ----
                di as text _n "A1 donut: `var' | `dtype' | `atype' | dropping |RV| < `k' | auto bw"
                capture rdrobust `var' `dtype' if abs(`dtype') >= `k', ///
                    c(0) ${`atype'} covs($covariates) all masspoints(off)

                if _rc == 0 {
                    * Conventional coefficient (reported) alongside the
                    * bias-corrected estimate and robust 90% CI
                    local bcl = e(tau_cl)
                    local scl = e(se_tau_cl)
                    local pcl = e(pv_cl)
                    local bbc = e(tau_bc)
                    local srb = e(se_tau_rb)
                    local prb = e(pv_rb)
                    local lo  = `bbc' - invnormal(.975) * `srb'
                    local hi  = `bbc' + invnormal(.975) * `srb'
                    local h   = e(h_l)
                    local nef = e(N_h_l) + e(N_h_r)
                    if `k' == 0 {
                        local h0 = e(h_l)		// baseline bandwidths, reused
                        local b0 = e(b_l)		// by the fixed-h runs below
                    }
                    post A1post ("`dtype'") ("`atype'") (`k') ("auto") ("`var'") ///
                        (`bcl') (`scl') (`pcl') (`bbc') (`srb') (`prb') ///
                        (`lo') (`hi') (`h') (`nef')
                }
                else {
                    di as error "   -> rdrobust failed (rc = " _rc "), skipping"
                    post A1post ("`dtype'") ("`atype'") (`k') ("auto") ("`var'") ///
                        (.) (.) (.) (.) (.) (.) (.) (.) (.) (.)
                }

                * ---- (b) bandwidth fixed at the baseline (donut 0) values ----
                if `k' > 0 & `h0' < . {
                    di as text "A1 donut: `var' | `dtype' | `atype' | dropping |RV| < `k' | fixed bw h = " %5.3f `h0'
                    capture rdrobust `var' `dtype' if abs(`dtype') >= `k', ///
                        c(0) ${`atype'} covs($covariates) all masspoints(off) ///
                        h(`h0') b(`b0')

                    if _rc == 0 {
                        local bcl = e(tau_cl)
                        local scl = e(se_tau_cl)
                        local pcl = e(pv_cl)
                        local bbc = e(tau_bc)
                        local srb = e(se_tau_rb)
                        local prb = e(pv_rb)
                        local lo  = `bbc' - invnormal(.975) * `srb'
                        local hi  = `bbc' + invnormal(.975) * `srb'
                        local nef = e(N_h_l) + e(N_h_r)
                        post A1post ("`dtype'") ("`atype'") (`k') ("fixed") ("`var'") ///
                            (`bcl') (`scl') (`pcl') (`bbc') (`srb') (`prb') ///
                            (`lo') (`hi') (`h0') (`nef')
                    }
                    else {
                        di as error "   -> rdrobust (fixed h) failed (rc = " _rc "), skipping"
                        post A1post ("`dtype'") ("`atype'") (`k') ("fixed") ("`var'") ///
                            (.) (.) (.) (.) (.) (.) (.) (.) (.) (.)
                    }
                }
            }
            local c = `c' + 1
        }
    }
}
* Countries excluded by each donut (for the legend). Computed here, while the
* analysis sample is still in memory -- the plots below run off the results file.
foreach dtype in distance z_frontier {   // 2026-09-10: was distance_homi distance z_distance
    forvalues k = 1/2 {
        qui count if abs(`dtype') < `k' & !missing(`dtype')
        global ndrop_`dtype'_`k' = r(N)
    }
}

postclose A1post

**********************
* Export results     *
**********************

use `results', clear
export delimited using "$output/rr_A1_donut_estimates_091326.csv", replace
save "$output/rr_A1_donut_estimates_091326.dta", replace

*************
* Coefplots *
*************


* One style per donut size
local st0 msymbol(O) mcolor(navy)     ciopts(color(navy))
local st1 msymbol(D) mcolor(maroon)   ciopts(color(maroon))
local st2 msymbol(S) mcolor(midgreen) ciopts(color(midgreen))

* Titles and file suffixes per running variable
local ttl_distance_homi "Multidimensional cutoff (MD)"
local ttl_distance      "Distance to the selection boundary (Euclidean)"   // 2026-09-13 (coherence review fix)
local ttl_z_frontier    "Stability factors cutoff (frontier)"
local fn_z_frontier     "SFfront"
local ttl_z_distance    "Stability factors cutoff (SF)"
local fn_distance_homi  "MD"
local fn_distance       "MDeuclid"
local fn_z_distance     "SF"

foreach dtype in distance z_frontier {   // 2026-09-10: was distance_homi distance z_distance

    local n1 ${ndrop_`dtype'_1}
    local n2 ${ndrop_`dtype'_2}

    * One figure per bandwidth treatment: a = auto, f = fixed at baseline h.
    * The donut-0 (baseline) estimates are shared between the two.
    foreach vr in a f {

        if "`vr'" == "a" {
            local fsuf ""
            local tsuf ""
            local mm   "auto"
        }
        else {
            local fsuf "_fixedh"
            local tsuf ", baseline bandwidth held fixed"
            local mm   "fixed"
        }

        * One 5 x 3 matrix per donut size (Miv0, Miv1, Miv2): coefficient, CI lower, CI upper.
        * Rows are the five outcomes in $A1_outcomes order; missing rows stay missing and are not drawn.
        * Donut 0 is the shared baseline and always comes from the auto-bandwidth rows.
        foreach k in 0 1 2 {
            local bwm = cond(`k' == 0, "auto", "`mm'")
            matrix Miv`k' = J(5,3,.)
            local c = 1
            foreach v of global A1_outcomes {
                local sel rv=="`dtype'" & spec=="iv" & donut==`k' & bw_method=="`bwm'" & outcome=="`v'"
                qui count if `sel' & !missing(coef_cl)
                if r(N) > 0 {
                    qui summarize coef_cl    if `sel', meanonly
                    matrix Miv`k'[`c',1] = r(mean)
                    qui summarize ci95_lo_rb if `sel', meanonly
                    matrix Miv`k'[`c',2] = r(mean)
                    qui summarize ci95_hi_rb if `sel', meanonly
                    matrix Miv`k'[`c',3] = r(mean)
                }
                local c = `c' + 1
            }
            matrix rownames Miv`k' = o1 o2 o3 o4 o5
            matrix colnames Miv`k' = b ll ul
        }

        * CI bounds must be passed as explicit matrix[,col] references --
        * ci((ll ul)) using column NAMES is silently ignored and the whiskers
        * simply do not draw.
        coefplot (matrix(Miv0[,1]), ci((Miv0[,2] Miv0[,3])) `st0')               ///
                 (matrix(Miv1[,1]), ci((Miv1[,2] Miv1[,3])) `st1')               ///
                 (matrix(Miv2[,1]), ci((Miv2[,2] Miv2[,3])) `st2'),              ///
                 bylabel("Fuzzy RD")                                         ///
            ||, drop(_cons) xline(0, lpattern(dash) lcolor(gs8))                 ///
            order(o1 o2 o3 o4 o5)                                                ///
            coeflabel(                                                           ///
                o1 = `" "(A) Tax transparency" "(mean outcome)" "'               ///
                o2 = `" "(B) Fair taxation" "(mean outcome)" "'                  ///
                o3 = `" "(C) Anti-BEPS" "(mean outcome)" "'                      ///
                o4 = `" "Number of minimum" "standards" "'                       ///
                o5 = "Participation in IF"                                       ///
                )                                                                ///
            legend(order(2 "Baseline"                                            ///
                   4 "Donut: drop |RV| < 1 (`n1' countries dropped)"             ///
                   6 "Donut: drop |RV| < 2 (`n2' countries dropped)")            ///
                   rows(1) position(6))                                          ///
            byopts(xrescale title("`ttl_`dtype''`tsuf'", size(medium)))          ///
            scheme(modern) xsize(7)                                              ///
            graphregion(fcolor(white) lcolor(white))                             ///   2026-09-14 (author): white background (was "250 250 250", off-white in the PDF)
            plotregion(fcolor(white) lcolor(white))
        graph export "$graphs/rr_A1_donut_`fn_`dtype''`fsuf'_091326.png", replace width(2400)
        graph export "$graphs/rr_A1_donut_`fn_`dtype''`fsuf'_091326.pdf", replace
        if "$ographs" != "" graph export "$ographs/rr_A1_donut_`fn_`dtype''`fsuf'_091326.pdf", replace
    }
}

di "rr_A1_donut_081926.do completed."
