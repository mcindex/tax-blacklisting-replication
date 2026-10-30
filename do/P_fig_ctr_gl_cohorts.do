********************************************************************************
* P_fig_ctr_gl_cohorts.do
* ONLINE APPENDIX figure f:ctr_cohorts: greylisting effect on corporate tax rates
* by greylisting cohort (group ATTs), statutory CIT rate and EATR.
********************************************************************************
*
* Design as Table 5 panels A-B, column (1) and Figure 7 (a)-(b): reviewed
* jurisdictions (selected == 1), annual RSIT ITI rates from 2010, treatment =
* first greylisting year, Callaway-Sant'Anna (doubly robust) with not-yet-
* greylisted controls, wild-bootstrap SEs (seed 20260909). The "All cohorts"
* point is csdid's group-weighted average; the overall ATT in Table 5 is the
* simple aggregation (0.018 statutory, 0.016 EATR).
* The two jurisdictions first greylisted in 2022 fall after the ITI data end
* (2020) and enter as not-yet-treated controls.
*
* Inputs : input/ITI_CITR_ct_R2.dta, output/regready.dta, output/BL_firstyear.dta
* Outputs: output/rr_ctr_gl_cohorts.csv, graphs/rr_ctr_gl_cohorts.png,
*          Overleaf graphs/rr_ctr_gl_cohorts_091526.pdf
* 2026-09-15: added (author).
********************************************************************************

*--- 1. Sample (as T05b_taxrate_econ_did_table.do, greylisting design) -----------
use "$input\ITI_CITR_ct_R2.dta", clear
mmerge iso3 using "$output\regready.dta", type(n:1) ukeep(selected reviewed) unmatched(master)
mmerge iso3 using "$output\BL_firstyear.dta", type(n:1) unmatched(master)
replace year_gl  = 0 if year_gl == .
replace selected = 0 if selected == .
egen c = group(iso3)
keep if year >= 2010
keep if selected == 1

* cohort sizes (jurisdictions), for the axis labels
preserve
    bysort iso3: keep if _n == 1
    foreach g in 2017 2018 2019 {
        qui count if year_gl == `g'
        local n_`g' = r(N)
    }
    qui count if year_gl > 0 & year_gl <= 2020
    local n_all = r(N)
restore
tempfile tax
save `tax'

*--- 2. Group ATTs, statutory CIT rate and EATR ------------------------------------
tempfile resf
postfile res str10 outcome str10 cohort double(att se) using `resf'
foreach var in SCITR_ct EATR_ct {
    use `tax', clear
    di as res _n "=== `var' ==="
    qui csdid `var', ivar(c) time(year) gvar(year_gl) method(dripw) notyet saverif(_rif_ctr) replace
    use _rif_ctr, clear
    set seed 20260909
    csdid_stats group, wboot estore(grp_`var')
    matrix b = e(b)
    matrix V = e(V)
    local names : colnames b
    local k = 1
    foreach nm of local names {
        local bb = b[1,`k']
        local ss = sqrt(V[`k',`k'])
        post res ("`var'") ("`nm'") (`bb') (`ss')
        local k = `k' + 1
    }
}
postclose res
cap erase _rif_ctr.dta
use `resf', clear
list, noobs sepby(outcome)
export delimited using "$output/rr_ctr_gl_cohorts.csv", replace

*--- 3. Figure ------------------------------------------------------------------
local grey "118 118 118"
coefplot (grp_SCITR_ct, label("Statutory CIT rate") msymbol(O) mcolor(black) offset(-0.12) ciopts(recast(rcap) lcolor(black)))     ///
         (grp_EATR_ct,  label("EATR")               msymbol(D) mcolor("`grey'") offset(0.12) ciopts(recast(rcap) lcolor("`grey'"))), ///
    vertical keep(GAverage G2017 G2018 G2019) order(GAverage G2017 G2018 G2019) ci(95)                                            ///
    coeflabels(GAverage = "All cohorts (`n_all')" G2017 = "2017 (`n_2017')" G2018 = "2018 (`n_2018')" G2019 = "2019 (`n_2019')")  ///
    xline(1.5, lcolor(gs10) lpattern(dash)) yline(0, lcolor(black))                                                               ///
    xtitle("Year first greylisted (number of jurisdictions)") ytitle("Effect on tax rate (fraction)")                              ///
    legend(order(2 "Statutory CIT rate" 4 "EATR") rows(1) position(6)) scheme(Modern) xsize(8) ysize(5) scale(1.1)                ///
    name(ctr_cohorts, replace)
graph export "$graphs/rr_ctr_gl_cohorts.png", replace width(2000)
if "$ographs" != "" graph export "$ographs/rr_ctr_gl_cohorts_091526.pdf", replace
