* T03_main_rd.do  |  TABLE 3 (t:main_rd, online appendix) fuzzy RD, rule-eligible sample + rr_rvcompare_fuzzy; estimates read by F05
* 2026-09-15: rewritten for legibility (formatting programs adapfmt / starstr replaced by inline expressions; output unchanged). Backup do/old/replication_rr_pre_legibility_091526/
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; body = do/rr_table3_fuzzy_091226.do (built 2026-09-12 night), estimates identical to that run
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Copied unchanged from do/rr_table3_sharp_euc_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_table3_fuzzy_091226.do
*
* FUZZY-RD VARIANT (author, 2026-09-12 night) of rr_table3_sharp_euc_090926.do: same code, with
*   - sample = all non-LDC jurisdictions plus Vanuatu, EXCLUDING the five EU tax
*     transparency agreement jurisdictions (reviewed regardless of score);
*   - review instrumented by crossing the boundary: rdrobust ..., fuzzy(reviewed);
*     the four discretionary reviews (MHL, NIU, NRU, PLW) stay in as non-compliers.
* -> tables/rr_table3_fuzzy_euc.tex (+ Overleaf rr_table3_fuzzy_091226.tex), output/rr_table3_fuzzy_euc_estimates.csv, graphs/rr_rvcompare_fuzzy.png
* Adopted for the R&R on 2026-09-13; the sharp versions stay in ../do/ and in Overleaf under the _091026 names.
********************************************************************************
********************************************************************************
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* rr_table3_sharp_euc_090926.do
*
* Revised Table 3 (author specification, 2026-09-09):
*   - sample: rule-eligible jurisdictions = non-LDC plus Vanuatu (the one LDC
*     the COCG reviewed); crossing the boundary predicts review perfectly here,
*     so the reduced form is a SHARP RD estimate of the effect of review
*   - running variables: EUCLIDEAN distance to the selection boundary
*     (`distance') and the stability-factors distance (`z_distance')
*   - reduced form only (no fuzzy columns), without / with log GDP pc 2015
*   - conventional coefficient, robust bias-corrected 95% CI, MSE-optimal
*     bandwidth, masspoints(off) -- the R&R reporting convention
* plus the running-variable comparison plot (Euclidean vs SF, 95% robust CIs,
* markers only) restricted to the outcomes that moved relative to the
* published table or differ across running variables.
*
* Input : output/regready_042822_gdp2026_frozen20260820.dta (PRI-fixed)
* Output: tables/rr_table3_sharp_euc.tex, output/rr_table3_fuzzy_euc_estimates.csv,
*         graphs/rr_rvcompare_sharp.png
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global tables  "$project\tables"
    global graphs  "$project\graphs"
}
cap graph set window fontface "LM Roman 10"
local ci_table = 95
local ci_fig   = 95   // 2026-09-12: was 90 (author: 95% CIs everywhere)
local frozen "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta"
confirm file "`frozen'"

* Number formatting used in the table below (written inline where needed):
*   adaptive decimals, as estout's b(a2): 2 decimals for |x| >= 1 (or x = 0), otherwise enough
*   decimals to show 2 significant digits:
*     local d = cond(abs(x) >= 1 | x == 0, 2, max(2, 1 - floor(log10(abs(x)))))
*   stars: *** p < .01, ** p < .05, * p < .10


local lab1  "\hspace{.3cm} \emph{Mean outcome}"
local lab2  "\hspace{.4cm} (i) CRS commitment by 2023"
local lab3  "\hspace{.4cm} (ii) \% of EU countries covered by AEOI"
local lab4  "\hspace{.4cm} (iii) Largely compliant on EOIR"
local lab5  "\hspace{.4cm} (iv) Signed up to MAA"
local lab6  "\hspace{.4cm} (v) AEOI rated On Track"   // 2026-09-15 (author): new outcome (D11_aeoi_ontrack.do); rows 6+ shifted down by one
local lab7  "\hspace{.3cm} \emph{Mean outcome}"
local lab8  "\hspace{.3cm} (i) Reviewed w/ no harmful regimes"
local lab9  "\hspace{.3cm} \emph{Mean outcome}"
local lab10 "\hspace{.4cm} (i) Signed up to CbCR"
local lab11 "\hspace{.4cm} (ii) Signed up to MLI"
local lab12 "\hspace{.4cm} (iii) Published MAP profile"
local lab13 "\hspace{.4cm}  Participation in IF"
local lab14 "\hspace{.4cm}  Signed up to global deal"
local lab15 "\hspace{.4cm} Signed up to Global Forum"
local lab16 "\hspace{.4cm} Ever greylisted"
local lab17 "\hspace{.4cm} Ever blacklisted"
local lab18 "\hspace{.4cm} Ever grey or blacklisted"
local lab19 "\hspace{.4cm} Letter sent by COCG"
local lab20 "\hspace{.4cm} COCG raised an issue (AEOI, IF, harmful regime, GF, MCAA)"
local lab21 "\hspace{.4cm} Number of minimum standards"
local head1  "\emph{{\bf (A) Tax transparency: }}"
local head7  "\midrule \emph{{\bf (B) Fair taxation: }}"
local head9  "\midrule \emph{{\bf (C) Anti-BEPS: }}"
local head13 "\midrule \emph{{\bf Intermediate outcomes: }}"
local head19 "\midrule \emph{{\bf COCG deficiency letters: }}"
local head21 "\midrule \emph{{\bf Other outcomes: }}"
global T3_outcomes "tax_transparency_now aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack fair_taxation_now harm_now anti_beps_now cbcr_s_now mil_signed_now map_now if_part_now global_deal_now gf_now ever_gl ever_bl ever_either any_letter cocg_issue numstandard_now"
local NR = 21   // 2026-09-10: + COCG letter rows; 2026-09-15: + AEOI On Track (row 6)
* 2026-09-10: five columns - (1) distance (2) + log GDP pc (3) + nearest-face
* dummies (author, balance response) (4) z-frontier (5) z-frontier + log GDP pc
local NC = 5
local colspec1 "EU,rf,none"
local colspec2 "EU,rf,lngdppcn_2015"
local colspec3 "EU,rf,face"
local colspec4 "ZF,rf,none"
local colspec5 "ZF,rf,lngdppcn_2015"
local dt1 distance
local dt2 distance
local dt3 distance
local dt4 z_frontier
local dt5 z_frontier
local cv1 ""
local cv2 "lngdppcn_2015"
local cv3 "face_x face_y"
local cv4 ""
local cv5 "lngdppcn_2015"
* 2026-09-15 (author): Manhattan version of Table A6 for the appendix (referee 1, comment 2a). With global T3_rv = "manhattan"
* columns (1)-(3) are re-estimated on the Manhattan distance (distance_homi; same 141 jurisdictions, same side of the
* cutoff for every one); the frontier columns (4)-(5) do not depend on the metric and are left out. Default ("")
* = the Euclidean Table A6, unchanged. Outputs: tables/rr_table3_fuzzy_manhattan.tex (Overleaf _091526),
* output/rr_table3_fuzzy_manhattan_estimates.csv (read by F05 with the same global).
local sfx ""
if "$T3_rv" == "manhattan" {
    local NC = 3
    local colspec1 "MH,rf,none"
    local colspec2 "MH,rf,lngdppcn_2015"
    local colspec3 "MH,rf,face"
    local dt1 distance_homi
    local dt2 distance_homi
    local dt3 distance_homi
    local sfx "_manhattan"
}

********************************************************************************
* 1. ESTIMATION: (1) Euclidean (2) Euclidean + cv (3) SF (4) SF + cv
********************************************************************************
use "`frozen'", clear
gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // fuzzy-design sample
keep if elig

* z-frontier design (author, 2026-09-10): stability score among jurisdictions clearing the other two thresholds
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs

* Nearest face of the selection boundary (2026-09-10; replaces the pipeline's
* x/y/z_boundary, which picks the smallest |distance| and misclassifies
* single-failure jurisdictions). Positive = risky side. Missing scores count
* as cleared with infinite slack.
gen sx = cond(x_distance < 0, -x_distance, 0)
gen sy = cond(y_distance < 0, -y_distance, 0)
gen sz = cond(z_distance < 0, -z_distance, 0)
gen kx = cond(x_distance == ., 1e9, x_distance)
gen ky = cond(y_distance == ., 1e9, y_distance)
gen kz = cond(z_distance == ., 1e9, z_distance)
gen byte nface = .
* unselected side: the threshold with the largest shortfall
replace nface = 1 if sz > 0 & sz >= sx & sz >= sy
replace nface = 2 if nface == . & sx > 0 & sx >= sy
replace nface = 3 if nface == . & sy > 0
* selected side: the threshold with the least slack
replace nface = 1 if nface == . & kz <= kx & kz <= ky & distance != .
replace nface = 2 if nface == . & kx <  kz & kx <= ky & distance != .
replace nface = 3 if nface == . & distance != .
lab def nface 1 "stability" 2 "ties" 3 "financial"
lab val nface nface
gen byte face_x = nface == 2 if nface != .
gen byte face_y = nface == 3 if nface != .
tab nface if distance != ., missing
tab nface x_boundary if distance != .   // compare with the pipeline's classifier

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
qui count if distance != .
di as txt "Rule-eligible sample: `r(N)' jurisdictions with a Euclidean running variable"
qui count if distance > 0 & distance != . & reviewed == 0
di as txt "unreviewed jurisdictions above the cutoff: `r(N)' (fuzzy design: non-compliers allowed)"
* 2026-09-13: two-sided check -- reviewed jurisdictions below the cutoff are the discretionary reviews
* (MHL, NIU, NRU, PLW; scoreboard "Not Selected", IMF-2008 offshore financial centres), kept as non-compliers
qui count if distance < 0 & distance != . & reviewed == 1
di as txt "reviewed jurisdictions below the cutoff: `r(N)'"
list iso3 distance reviewed if distance < 0 & distance != . & reviewed == 1, noobs clean
list iso3 distance reviewed if distance > 0 & distance != . & reviewed == 0, noobs clean
qui count if distance != . & status == "EU Tax Transparency Agreement"
assert r(N) == 0   // agreement jurisdictions are out of the sample

foreach m in TAUCL PVCL TAUBC SERB PVRB CILT CIRT CILF CIRF HL NEFF {
    matrix `m' = J(`NR',`NC',.)
}
foreach m in FOBS FEFO FBW FBWMX FBWMN {
    matrix `m' = J(1,`NC',.)
}
local zT = invnormal(1 - (100 - `ci_table')/200)
local zF = invnormal(1 - (100 - `ci_fig')/200)

forvalues col = 1/`NC' {
    local dtype `dt`col''
    local cv    `cv`col''
    {
        local ef = 0
        local bw = 0
        local c  = 1
        local maxbw = 0
        local minbw = 100
        local cvopt = cond("`cv'" == "", "", "covs(`cv')")
        foreach var of global T3_outcomes {
            capture rdrobust `var' `dtype', c(0) `cvopt' all masspoints(off) fuzzy(reviewed)
            if _rc == 0 {
                matrix TAUCL[`c',`col'] = e(tau_cl)
                matrix PVCL[`c',`col']  = e(pv_cl)
                matrix TAUBC[`c',`col'] = e(tau_bc)
                matrix SERB[`c',`col']  = e(se_tau_rb)
                matrix PVRB[`c',`col']  = e(pv_rb)
                matrix HL[`c',`col']    = e(h_l)
                matrix NEFF[`c',`col']  = e(N_h_l) + e(N_h_r)
                matrix CILT[`c',`col']  = e(tau_bc) - `zT'*e(se_tau_rb)
                matrix CIRT[`c',`col']  = e(tau_bc) + `zT'*e(se_tau_rb)
                matrix CILF[`c',`col']  = e(tau_bc) - `zF'*e(se_tau_rb)
                matrix CIRF[`c',`col']  = e(tau_bc) + `zF'*e(se_tau_rb)
                local ef  = `ef' + e(N_h_l) + e(N_h_r)
                local bw  = `bw' + e(h_l)
                local maxbw = round(max(`maxbw', e(h_l)))
                local minbw = round(min(`minbw', e(h_l)))
                matrix FEFO[1,`col']  = round(`ef' / `c', 1)
                matrix FBW[1,`col']   = `bw' / `c'
                matrix FBWMX[1,`col'] = `maxbw'
                matrix FBWMN[1,`col'] = `minbw'
                matrix FOBS[1,`col']  = e(N_l) + e(N_r)
            }
            else {
                di as err "col `col' `var': rdrobust failed (rc = " _rc ")"
            }
            local c = `c' + 1
        }
        di as txt "col `col' (`colspec`col'') done"
    }
}

********************************************************************************
* 2. TABLE
********************************************************************************
local tfile "$tables/rr_table3_fuzzy_euc.tex"
if "`sfx'" != "" local tfile "$tables/rr_table3_fuzzy`sfx'.tex"   // 2026-09-15: Manhattan version
file open tb using "`tfile'", write replace text
file write tb "\begin{adjustbox}{max width=\textwidth}" _n   // fit to text width (author, 2026-09-11)
if "`sfx'" != "" {   // 2026-09-15: Manhattan version, three columns
file write tb "\begin{tabular}{l*{3}{r@{\hspace{3pt}}l}}" _n
file write tb "\toprule" _n
file write tb "&\multicolumn{6}{c}{{\bf Manhattan distance to selection boundary}}\\" _n
file write tb "\cmidrule(lr){2-7}" _n
file write tb "&\multicolumn{2}{c}{(1)}&\multicolumn{2}{c}{(2)}&\multicolumn{2}{c}{(3)}\\" _n
file write tb "&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}\\" _n
}
else {
file write tb "\begin{tabular}{l*{5}{r@{\hspace{3pt}}l}}" _n
file write tb "\toprule" _n
file write tb "&\multicolumn{6}{c}{{\bf Distance to selection boundary}}&\multicolumn{4}{c}{{\bf Stability-factors score (frontier)}}\\" _n
file write tb "\cmidrule(lr){2-7}" _n
file write tb "\cmidrule(lr){8-11}" _n
file write tb "&\multicolumn{2}{c}{(1)}&\multicolumn{2}{c}{(2)}&\multicolumn{2}{c}{(3)}&\multicolumn{2}{c}{(4)}&\multicolumn{2}{c}{(5)}\\" _n
file write tb "&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}&\multicolumn{1}{c}{Coef.}&\multicolumn{1}{c}{[`ci_table'\% CI]}\\" _n
}
file write tb "\midrule" _n
local amps = 2 * `NC'   // 2026-09-15: one empty cell pair per column (was 10 ampersands for five columns)
local empt : display _dup(`amps') "&"
forvalues r = 1/`NR' {
    if "`head`r''" != "" {
        file write tb "`head`r''`empt'\\" _n
    }
    file write tb "`lab`r''"
    forvalues k = 1/`NC' {
        local b  = TAUCL[`r',`k']
        local p  = PVRB[`r',`k']
        local lo = CILT[`r',`k']
        local hi = CIRT[`r',`k']
        if missing(`b') {
            file write tb "& & "
        }
        else {
            * coefficient: adaptive decimals, then stars from the robust p-value
            local d  = cond(abs(`b') >= 1 | `b' == 0, 2, max(2, 1 - floor(log10(abs(`b')))))
            local bs = strtrim(string(`b', "%20.`d'f"))
            local st = cond(`p' < .01, "***", cond(`p' < .05, "**", cond(`p' < .10, "*", "")))
            * CI bounds share the decimals implied by the wider bound
            local mx = max(abs(`lo'), abs(`hi'))
            local d  = cond(`mx' >= 1 | `mx' == 0, 2, max(2, 1 - floor(log10(`mx'))))
            local los = strtrim(string(`lo', "%20.`d'f"))
            local his = strtrim(string(`hi', "%20.`d'f"))
            file write tb "& `bs'`st' & [`los', `his'] "
        }
    }
    file write tb "\\" _n
}
if "`sfx'" != "" {   // 2026-09-15: Manhattan version, three columns
file write tb "\midrule Log GDP per capita, 2015&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}&\multicolumn{2}{c}{}\\" _n
file write tb "Nearest-face dummies&\multicolumn{2}{c}{}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}\\" _n
}
else {
file write tb "\midrule Log GDP per capita, 2015&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}\\" _n
file write tb "Nearest-face dummies&\multicolumn{2}{c}{}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{X}&\multicolumn{2}{c}{}&\multicolumn{2}{c}{}\\" _n
}
file write tb "Observations"
forvalues k = 1/`NC' {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(FOBS[1,`k'], "%9.0gc"))'}"
}
file write tb "\\" _n
file write tb "Avg Effective \# Obs"
forvalues k = 1/`NC' {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(FEFO[1,`k'], "%9.0gc"))'}"
}
file write tb "\\" _n
file write tb "Avg Bandwidth"
forvalues k = 1/`NC' {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(FBW[1,`k'], "%9.3g"))'}"
}
file write tb "\\" _n
file write tb "Max Bandwidth"
forvalues k = 1/`NC' {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(FBWMX[1,`k'], "%9.3g"))'}"
}
file write tb "\\" _n
file write tb "Min Bandwidth"
forvalues k = 1/`NC' {
    file write tb "&\multicolumn{2}{c}{`=strtrim(string(FBWMN[1,`k'], "%9.3g"))'}"
}
file write tb "\\" _n
file write tb "\bottomrule" _n
file write tb "\end{tabular}" _n
file write tb "\end{adjustbox}" _n
file close tb
di as res "Wrote `tfile'"
if "$otables" != "" & "`sfx'" == "" copy "`tfile'" "$otables/rr_table3_fuzzy_091226.tex", replace
if "$otables" != "" & "`sfx'" != "" copy "`tfile'" "$otables/rr_table3_fuzzy`sfx'_091526.tex", replace   // 2026-09-15: new appendix table

********************************************************************************
* 3. CSV
********************************************************************************
local ccsv "$output/rr_table3_fuzzy_euc_estimates.csv"
if "`sfx'" != "" local ccsv "$output/rr_table3_fuzzy`sfx'_estimates.csv"   // 2026-09-15: Manhattan version
file open cc using "`ccsv'", write replace text
file write cc "col,rv,spec,covariates,outcome,tau_cl,pv_cl,tau_bc,se_rb,pv_rb,ci95_lo,ci95_hi,ci90_lo,ci90_hi,bw_h,n_eff" _n
forvalues k = 1/`NC' {
    local r = 1
    foreach var of global T3_outcomes {
        file write cc "`k',`colspec`k'',`var',"                          ///
            (TAUCL[`r',`k']) "," (PVCL[`r',`k'])  "," (TAUBC[`r',`k']) "," ///
            (SERB[`r',`k'])  "," (PVRB[`r',`k'])  ","                      ///
            (CILT[`r',`k'])  "," (CIRT[`r',`k'])  ","                      ///
            (CILF[`r',`k'])  "," (CIRF[`r',`k'])  ","                      ///
            (HL[`r',`k'])    "," (NEFF[`r',`k'])  _n
        local r = `r' + 1
    }
}
file close cc
di as res "Wrote `ccsv'"
if "`sfx'" != "" exit   // 2026-09-15: Manhattan version stops here (the comparison figure below uses the frontier columns)

********************************************************************************
* 4. FIGURE: Euclidean vs SF, outcomes that changed, no controls | controls
********************************************************************************
* rows in $T3_outcomes: 4 EOIR, 7 fair taxation, 12 MAP, 13 IF, 14 global deal, 21 min. standards (19-20 = COCG letters); 2026-09-15: +1 from row 6 (AEOI On Track)
local fig_rows  "7 4 13 14 12 21"
local fig_names "ft eo if gd mp ns"
local fig_lab_ft "Fair taxation (mean)"
local fig_lab_eo "Largely compliant on EOIR"
local fig_lab_if "Inclusive Framework participation"
local fig_lab_gd "Signed up to global deal"
local fig_lab_mp "Published MAP profile"
local fig_lab_ns "Number of minimum standards"
local col_EU "black"
local col_SF "gs9"
local sym_EU "O"
local sym_SF "D"
local coeflab ""
foreach nm of local fig_names {
    local coeflab `"`coeflab' `nm' = "`fig_lab_`nm''""'
}
foreach k in 1 2 4 5 {
    matrix F`k' = J(6, 3, .)
    local i = 1
    foreach r of local fig_rows {
        matrix F`k'[`i',1] = TAUCL[`r',`k']
        matrix F`k'[`i',2] = CILF[`r',`k']
        matrix F`k'[`i',3] = CIRF[`r',`k']
        local i = `i' + 1
    }
    matrix rownames F`k' = `fig_names'
    matrix colnames F`k' = b lo hi
}
coefplot                                                                   ///
    (matrix(F1[,1]), ci((F1[,2] F1[,3])) label("Distance to selection boundary")       ///
        msymbol(`sym_EU') mcolor(`col_EU') ciopts(recast(rcap) lcolor(`col_EU')) ///
        mlabel(string(@b, "%9.2f")) mlabposition(12) mlabsize(vsmall) mlabcolor(`col_EU') mlabgap(*0.6)) ///
    (matrix(F4[,1]), ci((F4[,2] F4[,3])) label("Stability factors (frontier)")        ///
        msymbol(`sym_SF') mcolor(`col_SF') ciopts(recast(rcap) lcolor(`col_SF')) ///
        mlabel(string(@b, "%9.2f")) mlabposition(6) mlabsize(vsmall) mlabcolor(`col_SF') mlabgap(*0.6)) ///
    , bylabel("No controls")                                               ///
  ||                                                                       ///
    (matrix(F2[,1]), ci((F2[,2] F2[,3]))                                   ///
        msymbol(`sym_EU') mcolor(`col_EU') ciopts(recast(rcap) lcolor(`col_EU')) ///
        mlabel(string(@b, "%9.2f")) mlabposition(12) mlabsize(vsmall) mlabcolor(`col_EU') mlabgap(*0.6)) ///
    (matrix(F5[,1]), ci((F5[,2] F5[,3]))                                   ///
        msymbol(`sym_SF') mcolor(`col_SF') ciopts(recast(rcap) lcolor(`col_SF')) ///
        mlabel(string(@b, "%9.2f")) mlabposition(6) mlabsize(vsmall) mlabcolor(`col_SF') mlabgap(*0.6)) ///
    , bylabel("With log GDP per capita")                                   ///
  ||, coeflabels(`coeflab', labsize(small))                                ///
    xline(-1.5 -1 -0.5 0.5 1 1.5 2 2.5 3 3.5 4 4.5, lcolor(gs12) lpattern(shortdash) lwidth(thin)) ///
    xline(0, lcolor(black)) xlabel(-2(1)4, grid glcolor(gs8) glpattern(dot))   ///
    xtitle("Fuzzy RD estimate (`ci_fig'% robust bias-corrected CI)", size(small)) ///
    scheme(Modern)                                                         ///
    byopts(rows(1) legend(position(6) rows(1) size(small)))                ///
    xsize(9) ysize(5) scale(1.15) name(rvcmp_fuzzy, replace)
* [off 2026-09-12] graph export "$graphs/rr_rvcompare_fuzzy.png", replace width(2400)
* [off 2026-09-12] if "$ographs" != "" graph export "$ographs/rr_rvcompare_sharp_091026.png", replace width(2400)
di as res "Wrote $graphs/rr_rvcompare_fuzzy.png"
