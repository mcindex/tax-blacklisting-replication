* P_tab_balance_eligible.do  |  PENDING appendix balance table on the fuzzy-design sample (Euclidean, z-frontier; rr_balance_elig_*_091326)
* 2026-09-15: trimmed to the two balance tables in the online appendix (distance, z_frontier)
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* Copied unchanged from do/rr_balance_sharp_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_balance_sharp_090926.do
*
* Covariate balance at the cutoff on the rule-eligible sample (non-LDC plus
* Vanuatu), for the Euclidean and stability-factors running variables --
* the sharp-RD sample of rr_table3_sharp_euc_090926.do. Same test as
* balance_tests_062922.do (Tables A2/A3 of the paper): local-linear RD of each
* pre-determined covariate on the running variable, CER-optimal bandwidth,
* conventional estimate, p-value and 95% CI. Run on the eligible sample AND on
* the full sample, so the two can be compared (the LDC composition jump at the
* boundary shows up in the full-sample rows for governance and income).
*
* Input : output/regready_042822_gdp2026_frozen20260820.dta (PRI-fixed)
* Output: tables/rr_balance_sharp_distance.tex, tables/rr_balance_sharp_z_distance.tex
*         output/rr_balance_elig_2026.csv (both samples, both cutoffs)
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global tables  "$project\tables"
}
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // z-frontier design: stability score among jurisdictions clearing the other two thresholds (2026-09-10)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs

global balancelist "x y z fa*5y trade_both*5y fdi_out_gdp_5y fdi_in_gdp_5y bop*gdp_5y ufdi_in_gdp_5y ufdi_out_gdp_5y cc_est*5y rq_est*5y lngdppcn_2015 cit2015 lnfsi18 SecrecyScore18"
lab var x                               "{\bf EU selection indicators}:Economic ties (percentile)"
lab var y                               "{\bf EU selection indicators}:Financial activity (percentile)"
lab var z                               "{\bf EU selection indicators}:Stability factors (percentile)"
lab var fa_EMP_5y                       "{\bf EU selection indicators}:EU affiliates (employment)\(^{*}\)"
lab var fa_ENT_5y                       "{\bf EU selection indicators}:EU affiliates (entities)\(^{*}\)"
lab var fa_TUR_5y                       "{\bf EU selection indicators}:EU affiliates (turnover)\(^{*}\)"
lab var trade_both_goods_gdp_5y         "{\bf EU selection indicators}:Tot trade w EU (goods)\(^{*\dag\#}\)"
lab var trade_both_services_gdp_5y      "{\bf EU selection indicators}:Tot trade w EU (srvcs)\(^{*\dag\#}\)"
lab var fdi_out_gdp_5y                  "{\bf EU selection indicators}:EU FDI in country\(^{*\dagger\#}\)"
lab var fdi_in_gdp_5y                   "{\bf EU selection indicators}:Country FDI in EU\(^{*\dagger\#}\)"
lab var bop_dividends_paid_gdp_5y       "{\bf EU selection indicators}:Dividends paid\(^{*\ddagger\#}\)"
lab var bop_dividends_received_gdp_5y   "{\bf EU selection indicators}:Dividends received\(^{*\ddagger\#}\)"
lab var bop_interest_paid_gdp_5y        "{\bf EU selection indicators}:Interest paid\(^{*\ddagger\#}\)"
lab var bop_interest_received_gdp_5y    "{\bf EU selection indicators}:Interest received\(^{*\ddagger\#}\)"
lab var bop_royalties_paid_gdp_5y       "{\bf EU selection indicators}:Royalties paid\(^{*\ddagger\#}\)"
lab var bop_royalties_received_gdp_5y   "{\bf EU selection indicators}:Royalties received\(^{*\ddagger\#}\)"
lab var ufdi_out_gdp_5y                 "{\bf EU selection indicators}:FDI outward stock\(^{*\S}\)"
lab var ufdi_in_gdp_5y                  "{\bf EU selection indicators}:FDI inward stock\(^{*\S}\)"
lab var cc_est_5y                       "{\bf EU selection indicators}:Control of corruption\(^{*\P}\)"
lab var rq_est_5y                       "{\bf EU selection indicators}:Regulatory quality\(^{*\P}\)"
lab var lngdppcn_2015                   "{\bf Other covariates}:Log(Per capita GDP) 2015"
lab var cit2015                         "{\bf Other covariates}:CIT rate (2015)"
lab var lnfsi18                         "{\bf Other covariates}:Log(FSI) (2018)"
lab var SecrecyScore18                  "{\bf Other covariates}:FSI Secrecy Score (2018)"

postfile B str12 cutoff str8 sample str32 var double h b p lo hi int neff ///
    using "$output/rr_balance_elig_2026.dta", replace
mat drop _all
foreach cutoff in distance z_frontier {   // 2026-09-15: z_distance dropped (its table is not in the appendix)
    foreach samp in elig full {
        local cond = cond("`samp'" == "elig", "if elig", "")
        local rows ""
        foreach var of varlist $balancelist {
            capture rdrobust `var' `cutoff' `cond', p(1) bwselect(cerrd) masspoints(off)   // masspoints(off) added 2026-09-10 to match every other rdrobust call in the R&R files
            if _rc == 0 {
                local ef = e(N_h_l) + e(N_h_r)
                mat K_`cutoff'_`samp' = nullmat(K_`cutoff'_`samp') \ (e(h_l), e(tau_cl), e(pv_cl), e(ci_l_cl), e(ci_r_cl), `ef')
                post B ("`cutoff'") ("`samp'") ("`var'") (e(h_l)) (e(tau_cl)) (e(pv_cl)) (e(ci_l_cl)) (e(ci_r_cl)) (`ef')
            }
            else {
                mat K_`cutoff'_`samp' = nullmat(K_`cutoff'_`samp') \ (., ., ., ., ., .)
                post B ("`cutoff'") ("`samp'") ("`var'") (.) (.) (.) (.) (.) (.)
                di as err "`cutoff' `samp' `var': rdrobust failed (rc = " _rc ")"
            }
            local this : variable label `var'
            local rows `"`rows' "`this'""'
        }
        mat rownames K_`cutoff'_`samp' = `rows'
        mat colnames K_`cutoff'_`samp' = "Bandwidth" "RD Estimator" "P-value" "Left CI" "Right CI" "Effective \# Obs"
    }
}
postclose B

local ttl_distance   "Euclidean distance to the selection boundary"
local ttl_z_distance "stability factors cutoff"
local ttl_z_frontier "stability factors cutoff, jurisdictions clearing the ties and financial thresholds"
foreach cutoff in distance z_frontier {   // 2026-09-15: z_distance dropped (its table is not in the appendix)
    * 2026-09-15: esttab escapes underscores in title()/prehead(), so the labels came out as t:balance\_elig\_... (unreferenceable);
    * labels are now underscore-free: t:balanceEligDistance, t:balanceEligZdistance, t:balanceEligZfrontier
    local lbl = "t:balanceElig" + upper(substr(subinstr("`cutoff'", "_", "", .), 1, 1)) + substr(subinstr("`cutoff'", "_", "", .), 2, .)
    esttab matrix(K_`cutoff'_elig, fmt(2 3 %9.3g 3 3 %9.0gc)) using "$tables/rr_balance_elig_`cutoff'.tex" ///
        , replace booktabs wrap compress nomtitle ///
        title(Balance tests, rule-eligible jurisdictions, \emph{`ttl_`cutoff''}\label{`lbl'}) ///
        prehead(\begin{table}[htbp]\centering ///
            \caption{Balance tests on the rule-eligible sample: \emph{`ttl_`cutoff''}\label{`lbl'}} ///
            \begin{adjustbox}{width=1\textwidth} ///
            \begin{tabular}{l*{6}{c}} ///
            \toprule ///
            ) ///
        postfoot(\bottomrule \end{tabular} \end{adjustbox} \begin{minipage}{0.95\textwidth} \footnotesize ///
            {\bf Notes:} Balance tests for pre-determined covariates on the sample of jurisdictions eligible for rule-based selection (all non-LDC jurisdictions plus Vanuatu, excluding the five jurisdictions reviewed under EU tax transparency agreements). ///
            Each row is a separate local linear regression discontinuity estimate of the covariate at the cutoff ///
            \citeN{calonico2014robust,calonico2018effect,calonico2019regression} with CER-optimal bandwidth; conventional estimate, p-value and 95\% CI. \\ ///
            \(^{*}\) Average over 2011--2016 \quad \(^{\dag}\) Source: Eurostat \quad \(^{\#}\) as \% of GDP \quad \(^{\ddagger}\) Source: IMF \quad \(^{\S}\) Source: UNCTAD \quad \(^{\P}\) Source: World Bank ///
            \end{minipage} \end{table})
    di as res "Wrote $tables/rr_balance_elig_`cutoff'.tex"
    if "$otables" != "" copy "$tables/rr_balance_elig_`cutoff'.tex" "$otables/rr_balance_elig_`cutoff'_091326.tex", replace   // Overleaf copy (author, 2026-09-10)
}

use "$output/rr_balance_elig_2026.dta", clear
export delimited using "$output/rr_balance_elig_2026.csv", replace
* Summary: how many covariates reject at 10% / 5%, by cutoff and sample
gen byte r10 = p < .10 if p != .
gen byte r05 = p < .05 if p != .
table cutoff sample, statistic(sum r10) statistic(sum r05) statistic(count p)
list cutoff sample var b p neff if p < .10, noobs sepby(cutoff sample)
