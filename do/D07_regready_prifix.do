* D07_regready_prifix.do  |  Puerto Rico running variable set to missing in the frozen file
* Copied unchanged from do/rr_prifix_090926.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_prifix_090926.do
*
* Puerto Rico's running variable (R&R fix, 2026-09-09).
*
* In the Commission's September 2016 scoreboard Puerto Rico has NO score for
* strength of ties (x) or financial activity (y) - both are ".." because its
* trade, FDI and BoP data are subsumed in the United States' - and only a
* stability-factors score (z = 30.8; status "No Data"). It could therefore
* never satisfy the all-three-thresholds rule and was not selected for
* review. rd1_042822.do nevertheless computes a distance for single-score
* jurisdictions from the one score available (l.409-411), which for PRI gives
* distance_homi = 70 - 30.8 = +39.2: deep on the "selected" side, the only
* non-reviewed non-LDC jurisdiction with a positive running variable, and the
* lone "control" of the top-third review design in rr_A2_govdid_all_082526.
*
* The single-score rule is right for the other eleven order == 1 jurisdictions
* (their one score is x or y, and the EU's selection follows it: COK, FRO,
* GGY, MSR, SMR, TCA, VGB selected; FLK, GIB, SXM not; NIU auto-included). It
* is wrong only when the sole score is z, because the stability indicator was
* never a stand-alone selection criterion. Rule applied here:
*     order == 1 & x == . & y == .   ->   running variables set to missing
* which affects exactly one row (PRI). All RD running variables, the "above"
* indicators and the nearest-boundary dummies are cleared; the outcome,
* covariate and listing variables are untouched.
*
* Applied to the frozen R&R analysis file only (the original pipeline's
* regready.dta / rd_sample_032522.dta are left as they were; rd1_042822.do
* needs the same rule if the pipeline is ever re-run). Idempotent.
*
* Input/output: output/regready_042822_gdp2026_frozen20260820.dta (in place)
* Archive     : output/regready_042822_gdp2026_frozen20260820_prePRIfix.dta
********************************************************************************

if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
}

local f "$output/regready_042822_gdp2026_frozen20260820.dta"
use "`f'", clear

cap confirm variable pri_nodata_fix
if _rc == 0 {
    di as txt "PRI fix already applied to `f' - nothing to do"
    exit
}

* Archive the untouched file once
cap confirm file "$output/regready_042822_gdp2026_frozen20260820_prePRIfix.dta"
if _rc {
    save "$output/regready_042822_gdp2026_frozen20260820_prePRIfix.dta"
}

gen byte pri_nodata_fix = order == 1 & x == . & y == .
qui count if pri_nodata_fix
assert r(N) == 1
assert iso3 == "PRI" if pri_nodata_fix
assert selected == 0 & reviewed == 0 if pri_nodata_fix
assert distance_homi > 39 & distance_homi < 40 if pri_nodata_fix

* Clear every running-variable-derived field for that row
unab dv : *distance* *_above *_boundary above sector
foreach v of local dv {
    replace `v' = . if pri_nodata_fix
}
di as txt "Cleared `: word count `dv'' variables for PRI"
label var pri_nodata_fix "Running variable set to missing: only a stability-factors score (PRI)"

* Nobody else changed
assert distance_homi != . if order >= 1 & !pri_nodata_fix & status != "No Data"
qui count if distance_homi != .
di as txt "Jurisdictions with a running variable: `r(N)' (was `=r(N)+1')"

save "`f'", replace
di as txt "Saved `f'"
