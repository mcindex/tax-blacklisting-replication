* T05b_taxrate_econ_did_table.do  |  MAIN-TEXT TABLE t:didextended (combined): corporate tax rates + economic outcomes
* 2026-09-15 (author): economic panels C-E show greylisting and blacklisting only (first-listing row dropped); control groups stated next to every panel title and the review premise in the notes
* 2026-09-15 (author): FDI panels relabelled "share of GNI" and units stated in the notes (outcomes are fractions: 0.1 = 10 percentage points)
* Built 2026-09-14 (author: "do we have a DiD table for the tax rates result? if not, let's combine with the
* economic DiD table"; table brought back into the main text after Figure fig:ctr).
*
* (1) Corporate tax rate DiDs with the four estimators of Table 5 (CSA, CSA + log income per capita, Gardner
*     did2s, TWFE). Sample and designs are those of F07_tax_rates.do / Figure fig:ctr, so the CSA column
*     reproduces the ATTs printed on the figure:
*       RV  treated = reviewed (from 2017), sample = non-EU jurisdictions
*       GL  treated = first greylisting year, sample = jurisdictions selected for review
*       BL  treated = first blacklisting year, sample = jurisdictions selected for review
*     csdid dripw with not-yet-treated controls (notyet), wild-bootstrap SEs (seeded); TWFE / Gardner on the
*     absorbing indicator year >= first treated year, jurisdiction and year FE, SEs clustered by jurisdiction.
*     Covariate for column (2): log GNI per capita 2010 (World Bank vintage used by T05 for FDI).
* (2) Combined table: tax-rate panels + the economic panels of T05 (read from output/rr_econ_did_2026_estimates.dta,
*     unchanged).
*
* Inputs : input/ITI_CITR_ct_R2.dta, input/eu_states.xlsx, output/regready.dta, output/BL_firstyear.dta,
*          output/wb_gnipc2010_vintage20260909.csv, output/rr_econ_did_2026_estimates.dta (T05)
* Outputs: output/rr_taxrate_did_estimates.{dta,csv}, tables/rr_did_taxecon_2026.tex
*          (+ Overleaf tables/rr_did_taxecon_2026_091426.tex)
* 2026-09-14 (author): Panel F (within-haven deposits) dropped; columns (3)-(4) added = column (1) specification with
*   treated AND control jurisdictions restricted to tax havens / non-havens (union list, rr_A2_haven_lists.dta).
*   Economic-outcome splits are estimated in T05_econ_did_2026.do (samples ext_hv/ext_nh, All_hv/All_nh).
* Requires: reghdfe, did2s, csdid, mmerge, kountry. Run after F06 (haven lists), F07 and T05.
* 2026-09-15: rewritten for legibility (table programs tb_block / tb_cell replaced by an annotated loop over panels;
*   output unchanged). Backup do/old/replication_rr_pre_legibility_091526/
********************************************************************************

cap graph set window fontface "LM Roman 10"

* ==============================================================================
* 1. Sample (as F07_tax_rates.do)
* ==============================================================================
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
assert iso3 != ""
tempfile e
save `e', replace

import delimited "$output/wb_gnipc2010_vintage20260909.csv", clear varnames(1) encoding(utf-8)
keep iso3 ny_gnp_pcap_cd
tempfile gnipc
save `gnipc', replace

use "$input\ITI_CITR_ct_R2.dta", clear
mmerge iso3 using `e', type(n:1) unmatched(master)
gen eu = _merge == 3
mmerge iso3 using "$output\regready.dta", type(n:1) ukeep(selected reviewed) unmatched(master)
mmerge iso3 using "$output\BL_firstyear.dta", type(n:1) unmatched(master)
mmerge iso3 using `gnipc', type(n:1) unmatched(master)
mmerge iso3 using "$output/rr_A2_haven_lists.dta", type(n:1) unmatched(master) ukeep(union)   // 2026-09-14: haven split (union list)
replace union = 0 if union == .
gen lngdppc = ln(ny_gnp_pcap_cd)
replace year_bl  = 0 if year_bl == .
replace year_gl  = 0 if year_gl == .
replace selected = 0 if selected == .
replace reviewed = 0 if reviewed == .
gen year_rv = 2017 if reviewed == 1
replace year_rv = 0 if reviewed == 0
egen c = group(iso3)
keep if year >= 2010
foreach tr in rv gl bl {
    gen byte A_`tr' = year_`tr' > 0 & year >= year_`tr'
}
local if_rv "eu == 0"
local if_gl "selected == 1"
local if_bl "selected == 1"
tempfile tax
save `tax', replace

* ==============================================================================
* 2. Estimation
* ==============================================================================
postfile T str8 part str16 outcome str12 sample str2 tr str8 est double b se int nj long n double pplac ///
    using "$output/rr_taxrate_did_estimates.dta", replace
foreach var in SCITR_ct EATR_ct {
    foreach tr in rv gl bl {
        local TR = upper("`tr'")
        use `tax', clear
        keep if `if_`tr''
        qui count if `var' != .
        local n = r(N)
        qui levelsof iso3 if `var' != ., local(L)
        local nj : word count `L'
        qui reghdfe `var' A_`tr', absorb(i.c i.year) cluster(c)
        post T ("T") ("`var'") ("ITI") ("`TR'") ("DiD") (_b[A_`tr']) (_se[A_`tr']) (`nj') (`n') (.)
        preserve
            keep if `var' != .
            qui did2s `var', first_stage(i.c i.year) second_stage(i.A_`tr') treatment(A_`tr') cluster(c)
            post T ("T") ("`var'") ("ITI") ("`TR'") ("Gardner") (_b[1.A_`tr']) (_se[1.A_`tr']) (`nj') (`n') (.)
        restore
        tempfile cur
        qui save `cur', replace
        qui csdid `var', ivar(c) time(year) gvar(year_`tr') method(dripw) notyet saverif(_tx_) replace
        use _tx_, clear
        set seed 20260909
        qui csdid_stats simple, wboot
        matrix b = e(b)
        matrix V = e(V)
        post T ("T") ("`var'") ("ITI") ("`TR'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
        use `cur', clear
        capture {
            qui csdid `var' lngdppc, ivar(c) time(year) gvar(year_`tr') method(dripw) notyet saverif(_tx_) replace
            use _tx_, clear
            set seed 20260909
            qui csdid_stats simple, wboot
            matrix b = e(b)
            matrix V = e(V)
        }
        if _rc == 0 post T ("T") ("`var'") ("ITI") ("`TR'") ("CSAx") (b[1,1]) (sqrt(V[1,1])) (`nj') (`n') (.)
        else {
            di as err "  CSA with covariates failed (rc = " _rc ") for `var' `TR' -- posted as missing"
            post T ("T") ("`var'") ("ITI") ("`TR'") ("CSAx") (.) (.) (`nj') (`n') (.)
        }
        * 2026-09-14: column (1) specification within tax havens / non-havens (treated and controls restricted)
        foreach hs in hv nh {
            use `tax', clear
            keep if `if_`tr'' & union == cond("`hs'" == "hv", 1, 0)
            qui levelsof iso3 if `var' != ., local(L)
            local njh : word count `L'
            qui count if `var' != .
            local nh = r(N)
            capture {
                qui csdid `var', ivar(c) time(year) gvar(year_`tr') method(dripw) notyet saverif(_tx_) replace
                use _tx_, clear
                set seed 20260909
                qui csdid_stats simple, wboot
                matrix b = e(b)
                matrix V = e(V)
            }
            if _rc == 0 post T ("T") ("`var'") ("ITI_`hs'") ("`TR'") ("CSA") (b[1,1]) (sqrt(V[1,1])) (`njh') (`nh') (.)
            else        post T ("T") ("`var'") ("ITI_`hs'") ("`TR'") ("CSA") (.) (.) (`njh') (`nh') (.)
        }
        di as txt "  `var' `TR': `nj' jurisdictions, `n' obs - done"
    }
}
postclose T
cap erase _tx_.dta

* ==============================================================================
* 3. Combined table
* ==============================================================================
use "$output/rr_taxrate_did_estimates.dta", clear
gen p = 2 * (1 - normal(abs(b / se)))
gen stars = cond(p < .01, "\sym{***}", cond(p < .05, "\sym{**}", cond(p < .10, "\sym{*}", "")))
gen bs  = cond(b == ., "--", strtrim(string(b,  "%9.3f")) + stars)
gen ses = cond(se == ., "", "(" + strtrim(string(se, "%9.3f")) + ")")
export delimited using "$output/rr_taxrate_did_estimates.csv", replace
save "$output/rr_taxrate_did_estimates.dta", replace
list outcome tr est bs ses nj n, noobs sepby(outcome tr)

append using "$output/rr_econ_did_2026_estimates.dta"
replace outcome = "InwardStock" if outcome == "InwardStoc"
* 2026-09-14 (author): blank the non-haven deposits blacklisting cell -- a single treated jurisdiction (KOR) vs 19 controls
replace bs = "--" if part == "B" & outcome == "deposits" & sample == "ext_nh" & tr == "BL" & est == "CSA"
replace ses = ""  if part == "B" & outcome == "deposits" & sample == "ext_nh" & tr == "BL" & est == "CSA"

file open TB using "$tables/rr_did_taxecon_2026.tex", write replace
file write TB "\begin{table}[p]" _n
file write TB "\centering" _n
file write TB "\caption{Impact of EU review and listing on corporate tax rates and economic outcomes: difference-in-differences estimates\label{t:didextended}}" _n
file write TB "{\scriptsize\setlength{\heavyrulewidth}{1.5pt}\setlength{\lightrulewidth}{1pt}\setlength{\cmidrulewidth}{0.5pt}%" _n
file write TB "\renewcommand{\arraystretch}{1.1}%" _n
file write TB "\begin{adjustbox}{max width=\textwidth, max totalheight=0.71\textheight}" _n
file write TB "\begin{tabular}{l*{6}{c}}" _n
file write TB "\toprule" _n
file write TB " & \multicolumn{4}{c}{Callaway--Sant'Anna} & Gardner & TWFE \\" _n
file write TB "\cmidrule(lr){2-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}" _n
file write TB " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write TB " & & + log income p.c. & Tax havens & Non-havens & & \\" _n
file write TB "\midrule" _n
* Panels of the table: part | outcome | sample | treatments | title
local npanel = 5
local panel_1_part "T"
local panel_1_outcome "SCITR_ct"
local panel_1_sample "ITI"
local panel_1_trs "RV GL BL"
local panel_1_title "Panel A: Statutory corporate income tax rate, 2010--2020 \normalfont\emph{(listing rows: controls are reviewed jurisdictions not yet listed)}"
local panel_2_part "T"
local panel_2_outcome "EATR_ct"
local panel_2_sample "ITI"
local panel_2_trs "RV GL BL"
local panel_2_title "Panel B: Effective average tax rate, 2010--2020 \normalfont\emph{(listing rows: controls are reviewed jurisdictions not yet listed)}"
local panel_3_part "B"
local panel_3_outcome "deposits"
local panel_3_sample "ext"
local panel_3_trs "GL BL"
local panel_3_title "Panel C: Log foreign-held deposits, 2015q1--2026q1 \normalfont\emph{(controls: never-listed jurisdictions)}"
local panel_4_part "C_new"
local panel_4_outcome "InwardStock"
local panel_4_sample "All"
local panel_4_trs "GL BL"
local panel_4_title "Panel D: Inward FDI stock, share of GNI, 2012--2024 \normalfont\emph{(controls: never-listed jurisdictions)}"
local panel_5_part "D_new"
local panel_5_outcome "InwardFlow"
local panel_5_sample "All"
local panel_5_trs "GL BL"
local panel_5_title "Panel E: Inward FDI flow, share of GNI, 2012--2024 \normalfont\emph{(controls: never-listed jurisdictions)}"

forvalues pn = 1/`npanel' {
    local part    "`panel_`pn'_part'"
    local outcome "`panel_`pn'_outcome'"
    local sample  "`panel_`pn'_sample'"
    local trs     "`panel_`pn'_trs'"
    file write TB "\multicolumn{7}{l}{\textbf{`panel_`pn'_title'}} \\[2pt]" _n

    * Under each treatment: coefficient row, SE row, and one "observations / jurisdictions" row;
    * treatments separated by a thin rule
    local ntr : word count `trs'
    local k = 0
    foreach tr of local trs {
        local k = `k' + 1
        if "`tr'" == "RV" local lab "Reviewed"
        if "`tr'" == "BT" local lab "First listing"
        if "`tr'" == "GL" local lab "First greylisting"
        if "`tr'" == "BL" local lab "First blacklisting"
        local row "`lab'"
        local srow ""
        local orow "\hspace{1em}\textit{Obs. / jurisdictions}"

        * Columns: CSA, CSA + controls, CSA within havens, CSA within non-havens, Gardner, TWFE.
        * The haven columns are CSA rows posted with sample "<sample>_hv" / "<sample>_nh".
        foreach e in CSA CSAx CSAhv CSAnh Gardner DiD {
            local est_name "`e'"
            local sample_name "`sample'"
            if "`e'" == "CSAhv" {
                local est_name "CSA"
                local sample_name "`sample'_hv"
            }
            if "`e'" == "CSAnh" {
                local est_name "CSA"
                local sample_name "`sample'_nh"
            }
            local cell `"part == "`part'" & outcome == "`outcome'" & sample == "`sample_name'" & tr == "`tr'" & est == "`est_name'""'
            qui levelsof bs  if `cell', local(v) clean
            qui levelsof ses if `cell', local(s) clean
            qui sum n  if `cell'
            local nobs = cond(r(N) > 0, strtrim(string(r(mean), "%9.0fc")), "")
            qui sum nj if `cell'
            local njur = cond(r(N) > 0, strtrim(string(r(mean), "%9.0f")), "")
            local row  "`row' & `v'"
            local srow "`srow' & `s'"
            local orow "`orow' & `nobs' / `njur'"
        }
        file write TB "`row' \\" _n
        file write TB "`srow' \\" _n
        file write TB "`orow' \\" _n
        if `k' < `ntr' file write TB "\cmidrule(lr){1-7}" _n
    }
    if `pn' < `npanel' file write TB "\midrule" _n
}
file write TB "\bottomrule" _n
file write TB "\end{tabular}" _n
file write TB "\end{adjustbox}}" _n
file write TB "\begin{flushleft}\scriptsize" _n
file write TB "{\bf Notes:} Each cell is a separate difference-in-differences estimate with jurisdiction and period fixed effects; column (2) adds log GNI (GDP) per capita as a pre-treatment covariate; columns (3) and (4) repeat column (1) with both treated and control jurisdictions restricted to tax havens (union of the lists of \citeN{johannesen2014end}, the 2015 EU list and the sink offshore financial centres of \citeN{garcia2017uncovering}, EU havens included) and to all other jurisdictions (--: not reported; in Panel C, column (4), a single blacklisted non-haven jurisdiction is in the deposits sample). Panels A--B (RSIT ITI corporate tax rates, \citeN{wamser2025iti}) use the designs of Figure \ref{fig:ctr}: \emph{reviewed} compares jurisdictions selected for the 2017 screening with non-EU jurisdictions never reviewed (treatment from 2017); \emph{first greylisting} and \emph{first blacklisting} are estimated among reviewed jurisdictions, with not-yet or never listed reviewed jurisdictions as controls; column (1) therefore reproduces the ATTs shown in Figure \ref{fig:ctr}. Panels C--E extend Table 5 of the submitted version with the BIS Locational Banking Statistics vintage of September 2026 (to 2026q1), the UNCTAD FDI vintage of August 2026 (to 2024) and EU list revisions through 17 February 2026; \emph{first greylisting} excludes jurisdictions only ever blacklisted, \emph{first blacklisting} excludes jurisdictions only ever greylisted, and controls are all never-listed jurisdictions. Because almost every listed jurisdiction was reviewed first, these estimates combine review and listing; they are read as listing effects on the premise that review alone did not move deposits or FDI, and no review design is estimated for the economic outcomes; deposits are winsorised at the 99th percentile and FDI at the 99th percentile within year (missing values left missing). Tax rates and FDI are measured as fractions, so a coefficient of 0.01 is one percentage point (of the tax rate, or of GNI). TWFE and Gardner (2021) use an absorbing indicator equal to one from the first treated period onward; Callaway--Sant'Anna (CSA) is doubly robust.  Standard errors clustered by jurisdiction; CSA standard errors from a wild bootstrap. \$^{*}p<0.10\$, \$^{**}p<0.05\$, \$^{***}p<0.01\$." _n
file write TB "\end{flushleft}" _n
file write TB "\end{table}" _n
file close TB
type "$tables/rr_did_taxecon_2026.tex"
if "$otables" != "" copy "$tables/rr_did_taxecon_2026.tex" "$otables/rr_did_taxecon_2026_091426.tex", replace
