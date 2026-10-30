* A_tab_wild_bootstrap.do  |  APPENDIX t:main_rd_iv_bs wild-bootstrap inference for the fuzzy RD (rd_regs_bot_091326)
* 2026-09-15: rewritten for legibility (programs runboot / bt_fmt / bt_stars replaced by inline code; output unchanged). Backup do/old/replication_rr_pre_legibility_091526/
* 2026-09-14 (author): table layout matches Table 3 (T03_main_rd.do) -- one row per outcome, coefficient and
*   [95% CI] side by side, written with file write instead of esttab (esttab stacked the CI under the estimate).
*   CI = boottest's inverted bootstrap-t 95% CI (r(CI)), stars from the wild-bootstrap p-value (were esttab's
*   t-based stars and b +/- 1.96 se, which disagree with each other in small-cluster cells). The bootstrap SE and
*   the boottest CI are both posted to the estimates file (se_boot, ci_bt_lo, ci_bt_hi); the coefficient plot
*   (P_fig_coefplot_boot.do) now uses the same CI. Bootstrap seeded (set seed 20260914). Cells whose bootstrap
*   variance is zero (outcome deterministic given review inside the bandwidth) would show 'n/a' for the CI.
*   Backup: do/old/replication_rr_pre091326/A_tab_wild_bootstrap_20260914.do
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; within-bandwidth 2SLS (review instrumented by the above-cutoff
* indicator, ivreg2) with the WRE wild bootstrap of boottest; was the sharp reduced form (OLS)
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/rd_regressions_042722_boottest.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************
* This file conducts the main RD analysis in the paper *
********************************************************

* Loading sample
* 2026-09-10 (R&R): frozen PRI-fixed file, rule-eligible sample (non-LDC + Vanuatu), z-frontier running variable
use "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", clear
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions

* COCG deficiency letters (author, 2026-09-10): from deficiencies_011921.do -> output/cocg_letters_091026.dta
merge 1:1 iso3 using "$output/cocg_letters_091026.dta", keep(master match) nogen
foreach v of varlist c_1 c_2 c_3 c_4 c_5 c_6 c_7 {
    replace `v' = 0 if `v' == .
}
egen any_letter = rowmax(c_1 c_2 c_3 c_4 c_5 c_6 c_7)
egen cocg_issue = rowmax(c_1 c_3 c_4 c_5 c_6)
lab var any_letter "\hspace{.4cm} Letter sent by COCG"
lab var cocg_issue "\hspace{.4cm} COCG raised an issue"
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
gen z_frontier_above = z_frontier >= 0 if z_frontier < .
lab var z_frontier "Stability factors cutoff (frontier)"
global covariates "lngdppcn_2015"   // 2026-09-10: was undefined in this file (controls silently dropped); ldc no longer usable after the restriction

foreach d in distance z_frontier {   // 2026-09-10: was z_distance distance distance_homi
	gen      `d'_times_above = `d'*`d'_above
}



***************
* Regressions *
***************

* Global preps (implementing controls or fuzzy RD depending on where we are
* in the loop)
global cv   "covs($covariates)" 
global ncv  ""
global iv    "fuzzy(reviewed)"   // 2026-09-13: actual review
global rf    ""
global cvr   "$covariates"
global ncvr  ""

foreach atype in iv {
	di "  ${`atype'} "
}

global outcomes_rf_now = "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either any_letter cocg_issue numstandard_now"
global outcomes_iv_now = "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either any_letter cocg_issue numstandard_now"

gen selected_fill = .
* 2026-09-10: log coefficient, bootstrap SE and p-value for the coefficient-plot version (rr_t3_coefplot_boot_091026.do)
tempname BP
postfile `BP' str16 rv str4 ctype str24 outcome double(b se_boot p_boot h neff ci_bt_lo ci_bt_hi nobs) using "$output/rr_boot_estimates_091326.dta", replace   // 2026-09-14: + boottest CI, rdrobust sample size
* 2026-09-14: table matrices (rows = outcomes in $outcomes_iv_now order; columns = distance ncv, distance cv, z_frontier ncv, z_frontier cv)
local NR : word count $outcomes_iv_now
matrix TB_B  = J(`NR', 4, .)
matrix TB_SE = J(`NR', 4, .)
matrix TB_P  = J(`NR', 4, .)
matrix TB_LO = J(`NR', 4, .)   // boottest inverted 95% CI (bootstrap-t), coherent with the bootstrap p-value
matrix TB_HI = J(`NR', 4, .)
matrix TB_N  = J(1, 4, .)
matrix TB_EF = J(1, 4, .)
matrix TB_BW = J(1, 4, .)
est drop _all
set seed 20260914   // 2026-09-14: the WRE wild bootstrap was unseeded, so CIs/p-values changed from run to run
foreach dtype in distance z_frontier  {   // 2026-09-10: sharp reduced form on the eligible sample; was z_distance distance distance_homi							// Foreach distance measure
	foreach atype in iv {													// 2026-09-13: fuzzy RD (was rf = sharp reduced form since 2026-09-10)
		foreach ctype in ncv cv {											// Covariates vs no covariates
			local ef = 0
			local bwsum = 0   // 2026-09-13 (coherence review fix): running sum of bandwidths for the Avg Bandwidth row (BW1)
			local c = 1 
			foreach var of varlist ${outcomes_`atype'_now} {							// Loading outcome list of interest
				
				* Running RD Robust 
				di "Running rdrobust for variable: `var', distance measure `dtype' and `atype' regression with `ctype'"
				capture rdrobust `var' `dtype', c(0)  ${`atype'}  ${`ctype'} all masspoints(off)
				
				assert e(h_l) < 72
				assert  e(b_l)  < 72
				
				if _rc == 0 {
				
				* Capturing number of effecive observations
				local rdN = e(N_l) + e(N_r)   // 2026-09-14: rdrobust sample size for the Observations row
				local ef = `ef' +  e(N_h_l) + e(N_h_r)
				local neff = e(N_h_l) + e(N_h_r)   // 2026-09-10: for the postfile log
				local efo = `ef' / `c'
				local efo2 = round(`efo',1)
				
				* Capturing coefficient
				local b = e(tau_cl)   // 2026-09-10: conventional coefficient (paper's reporting convention); was e(tau_bc)
				
				cap drop w
				local bw = e(h_l)		// Using symmetrical bandwidth so this is enough
				local bias = e(tau_bc)  -  e(tau_cl)
				
				* Generating triangular weights
				gen w = . 
				replace w = (1-abs(`dtype' / `bw')) if `dtype' < 0 & `dtype' >= -`bw'     // 2026-09-10: was z_distance regardless of dtype
				replace w = (1-abs(`dtype' / `bw')) if `dtype' >= 0 & `dtype' <= `bw'
				
				local ci_lo = .   // 2026-09-14: boottest CI, filled in the iv branch
				local ci_hi = .
				if "`atype'" == "rf" {
					qui replace selected_fill = `dtype'_above
					reg `var' selected_fill `dtype' `dtype'_times_above  ${`ctype'r} if abs(`dtype')<=`bw', cluster(iso3)   // 2026-09-10: was `reg if_part ...' for every outcome
					mat bn	      = e(b)			
					mat bn[1,1]   = `b'
					mat Vn	      = e(V)
					set seed 20260914   // 2026-09-15: same seed before every boottest call
					boottest selected_fill = 0 , nograph   // 2026-09-10: was selected_fill + `bias' = 0 (bias-corrected test)
					local p_boot = r(p)
					local Vb = .
					capture matrix bootV = r(V)
					if _rc == 0 local Vb = bootV[1,1]
				
				}
				else if "`atype'" == "iv" {
					qui replace selected_fill = reviewed   // 2026-09-13: endogenous treatment = actual review
					* 2026-09-13: when every in-bandwidth jurisdiction complies (review = above-cutoff indicator,
					* the case for the narrower bandwidths: nearest non-complier Palau at -8.7), the instrument is
					* collinear with the treatment, ivreg2 reclassifies it as exogenous and boottest's WRE
					* bootstrap fails (Mata conformability error, silently). The 2SLS estimate then equals the
					* OLS of the outcome on review, so run that (identical to the sharp reduced form) and
					* bootstrap it; otherwise run the 2SLS with boottest's WRE bootstrap.
					qui count if abs(`dtype') <= `bw' & !missing(`dtype') & selected_fill != `dtype'_above
					local nnc = r(N)
					if `nnc' == 0 {
						di as txt "   perfect first stage inside h = `bw': OLS on review (= reduced form), wild bootstrap"
						reg `var' selected_fill `dtype' `dtype'_times_above  ${`ctype'r} if abs(`dtype')<=`bw', cluster(iso3)
					}
					else {
						di as txt "   `nnc' non-complier(s) inside h = `bw': 2SLS, WRE wild bootstrap"
						ivreg2 `var' (selected_fill = `dtype'_above) `dtype' `dtype'_times_above  ${`ctype'r} if abs(`dtype')<=`bw', cluster(iso3)   // 2026-09-13: was `ivreg2 if_part ...' for every outcome
					}
					mat bn	      = e(b)
					mat bn[1,1]   = `b'
					mat Vn	      = e(V)
					* Wild bootstrap (WRE) of the review coefficient. boottest can fail silently (a Mata
					* error without an error code), so r() is cleared first with -count-: a silent failure
					* then leaves the p-value and variance missing, and the assert below stops the run.
					set seed 20260914                      // same seed before every boottest call
					qui count
					boottest selected_fill = 0 , nograph
					local p_boot = r(p)
					local ci_lo = .                        // boottest's inverted bootstrap-t 95% CI (may have several rows if disjoint)
					local ci_hi = .
					capture matrix bootCI = r(CI)
					if _rc == 0 {
						local ci_lo = bootCI[1,1]
						local ci_hi = bootCI[rowsof(bootCI),2]
					}
					local Vb = .                           // bootstrap variance (r(V) is a 1x1 matrix)
					capture matrix bootV = r(V)
					if _rc == 0 local Vb = bootV[1,1]
				}
				assert !missing(`Vb') & !missing(`p_boot')   // 2026-09-13: stop rather than post stale bootstrap results
				mat Vn[1,1]   = `Vb'
				local se_boot = sqrt(Vn[1,1])   // 2026-09-10: captured before erepost consumes Vn
				capture erepost b     = bn, rename
				capture erepost V     = Vn, rename
				est sto rd_`dtype'_`atype'_`ctype'_`c'
				local nobs = e(N)   // 2026-09-14: within-bandwidth regression sample (as the old Observations row)
				post `BP' ("`dtype'") ("`ctype'") ("`var'") (`b') (`se_boot') (`p_boot') (`bw') (`neff') (`ci_lo') (`ci_hi') (`nobs')
				* 2026-09-14: fill the table matrices
				local k = cond("`dtype'" == "distance", 0, 2) + cond("`ctype'" == "ncv", 1, 2)
				matrix TB_B[`c', `k']  = `b'
				matrix TB_SE[`c', `k'] = `se_boot'
				matrix TB_P[`c', `k']  = `p_boot'
				matrix TB_LO[`c', `k'] = `ci_lo'
				matrix TB_HI[`c', `k'] = `ci_hi'
				if `c' == 1 matrix TB_N[1, `k'] = `rdN'   // rdrobust sample (all jurisdictions with the running variable), as Table 3
				matrix TB_EF[1, `k'] = `ef' / `c'
				matrix TB_BW[1, `k'] = (`bwsum' + `bw') / `c'
				estadd local EFO = `efo2', replace
				local bwsum = `bwsum' + `bw'
				estadd scalar BW1 = `bwsum' / `c', replace   // 2026-09-13 (coherence review fix): average MSE bandwidth over the outcomes so far (as EFO)
	

				if "`ctype'" == "cv" {
					estadd local BASE = "X", replace 
					
				}
				}
			
				local c = `c' + 1
			}
		}	
	}
}


postclose `BP'
preserve
use "$output/rr_boot_estimates_091326.dta", clear
export delimited using "$output/rr_boot_estimates_091326.csv", replace
restore


**


* Labelling outcomes 
* Listing
lab var selected                "  Selected for review"
lab var greylisted              "\hspace{.4cm} Greylisted in 2017"
lab var blacklisted             "\hspace{.4cm} Blacklisted in 2017"
lab var both                    "\hspace{.4cm} Either grey or blacklisted"
lab var ever_gl 			    "\hspace{.4cm} Ever greylisted"
lab var ever_bl 			    "\hspace{.4cm} Ever blacklisted"
lab var ever_either			    "\hspace{.4cm} Ever grey or blacklisted"

* Tax transparency
lab var tax_transparency_now        "\hspace{.3cm} \emph{Mean outcome}"
lab var aeoi_2020_now               "\hspace{.4cm} (i) CRS commitment by 2023"
lab var per_EU_now    				"\hspace{.4cm} (ii) \% of EU countries covered by AEOI"
lab var eoi_now                     "\hspace{.4cm} (iii) Largely compliant on EOIR"   // 2026-09-13 (coherence review fix): numbering follows the outcome order (eoi, maa), as T03
lab var maa_now                     "\hspace{.4cm} (iv) Signed up to MAA" 
lab var aeoi_ontrack                "\hspace{.4cm} (v) AEOI rated On Track"   // 2026-09-15: + AEOI On Track outcome (v), transparency mean of (i)-(v) (D11_aeoi_ontrack.do)

* Fair taxation
lab var fair_taxation_now			"\hspace{.3cm} \emph{Mean outcome}"
lab var harm_now					"\hspace{.3cm} (i) Reviewed w/ no harmful regimes"			


* Anti-beps
lab var anti_beps_now               "\hspace{.3cm} \emph{Mean outcome}"
lab var cbcr_s_now                  "\hspace{.4cm} (i) Signed up to CbCR"
lab var map_now                     "\hspace{.4cm} (iii) Published MAP profile"
lab var mil_signed_now              "\hspace{.4cm} (ii) Signed up to MLI"

* Other
lab var gf_now 						"\hspace{.4cm} Signed up to Global Forum"
lab var if_part_now                 "\hspace{.4cm}  Participation in IF"
lab var global_deal_now             "\hspace{.4cm}  Signed up to global deal"
lab var numstandard_now             "\hspace{.4cm} Number of minimum standards"




* Table: one row per outcome, coefficient and [95% CI] side by side (layout of Table 3, T03_main_rd.do)
* 2026-09-14 (author): replaces the esttab block (stacked CIs). Written to a NEW dated file, rd_regs_bot_091426.tex,
*   which carries its own adjustbox/tabular (as rr_table3_fuzzy_091226.tex); the appendix should \input it directly
*   instead of \estauto{tables/rd_regs_bot_091326.tex}{6}{c}. The 091326 file is left untouched.
* Columns: (1) distance, no controls; (2) distance + log GDP pc 2015; (3) stability-factors frontier; (4) frontier + control.
* Number formatting used in the table below (written inline where needed):
*   adaptive decimals, as estout's b(a2): 2 decimals for |x| >= 1 (or x = 0), otherwise enough
*   decimals to show 2 significant digits:
*     local d = cond(abs(x) >= 1 | x == 0, 2, max(2, 1 - floor(log10(abs(x)))))
*   stars: *** p < .01, ** p < .05, * p < .10

* Section headings, written before the named outcome (order of $outcomes_iv_now)
local head_tax_transparency_now "\emph{{\bf (A) Tax transparency: }}"
local head_fair_taxation_now    "\midrule \emph{{\bf (B) Fair taxation: }}"
local head_anti_beps_now        "\midrule \emph{{\bf (C) Anti-BEPS: }}"
local head_if_part_now          "\midrule \emph{{\bf Intermediate outcomes: }}"
local head_any_letter           "\midrule \emph{{\bf COCG deficiency letters: }}"
local head_numstandard_now      "\midrule \emph{{\bf Other outcomes: }}"

local z = invnormal(0.975)
local tfile "$tables/rd_regs_bot_091426.tex"
file open tb using "`tfile'", write replace text
file write tb "\begin{adjustbox}{max width=\textwidth}" _n
file write tb "\begin{tabular}{l*{4}{r@{\hspace{3pt}}l}}" _n
file write tb "\toprule" _n
file write tb "&\multicolumn{4}{c}{{\bf Distance to selection boundary}}&\multicolumn{4}{c}{{\bf Stability-factors score (frontier)}}\\" _n
file write tb "\cmidrule(lr){2-5}" _n
file write tb "\cmidrule(lr){6-9}" _n
file write tb "&\multicolumn{2}{c}{(1)}&\multicolumn{2}{c}{(2)}&\multicolumn{2}{c}{(3)}&\multicolumn{2}{c}{(4)}\\" _n
file write tb "&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[95\% CI]}\\" _n
file write tb "\midrule" _n
local r = 0
local n_na = 0
foreach var in $outcomes_iv_now {
    local ++r
    if "`head_`var''" != "" file write tb "`head_`var''&&&&&&&&\\" _n
    local lab : variable label `var'
    file write tb "`lab'"
    forvalues k = 1/4 {
        local b  = TB_B[`r', `k']
        local se = TB_SE[`r', `k']
        local p  = TB_P[`r', `k']
        if missing(`b') {
            file write tb "& & "
        }
        else {
            local d  = cond(abs(`b') >= 1 | `b' == 0, 2, max(2, 1 - floor(log10(abs(`b')))))
            local bs = strtrim(string(`b', "%20.`d'f"))
            if `se' < 1e-8 {   // zero bootstrap variance: the outcome is a deterministic function of review inside the bandwidth
                file write tb "& `bs' & n/a "
                local ++n_na
            }
            else {
                local st = cond(`p' < .01, "***", cond(`p' < .05, "**", cond(`p' < .10, "*", "")))
                * 2026-09-14: boottest's inverted bootstrap-t CI (coherent with the p-value stars; the normal
                * approximation b +/- 1.96 se disagreed with the stars in several small-cluster cells);
                * fall back to the normal approximation only if boottest returned no CI
                local lo = TB_LO[`r', `k']
                local hi = TB_HI[`r', `k']
                if missing(`lo') | missing(`hi') {
                    local lo = `b' - `z' * `se'
                    local hi = `b' + `z' * `se'
                }
                local mx = max(abs(`lo'), abs(`hi'))        // CI bounds share the decimals implied by the wider bound
                local d  = cond(`mx' >= 1 | `mx' == 0, 2, max(2, 1 - floor(log10(`mx'))))
                local los = strtrim(string(`lo', "%20.`d'f"))
                local his = strtrim(string(`hi', "%20.`d'f"))
                file write tb "& `bs'`st' & [`los', `his'] "
            }
        }
    }
    file write tb "\\" _n
}
file write tb "\midrule Log GDP per capita, 2015&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}\\" _n
file write tb "Observations"
forvalues k = 1/4 {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(TB_N[1,`k'], "%9.0gc"))'}"
}
file write tb "\\" _n
file write tb "Avg Effective \# Obs"
forvalues k = 1/4 {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(round(TB_EF[1,`k'], 1), "%9.0gc"))'}"
}
file write tb "\\" _n
file write tb "Avg Bandwidth"
forvalues k = 1/4 {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(TB_BW[1,`k'], "%9.3g"))'}"
}
file write tb "\\" _n
file write tb "\bottomrule" _n
file write tb "\end{tabular}" _n
file write tb "\end{adjustbox}" _n
file close tb
di as txt "Wrote `tfile' (`n_na' cell(s) with zero bootstrap variance shown as n/a)"
if "$otables" != "" copy "`tfile'" "$otables/rd_regs_bot_091426.tex", replace
exit
