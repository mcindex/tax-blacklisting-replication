* T01_worked_example.do  |  TABLE 1 (t:example) worked example of the selection rule
* Copied unchanged from do/rr_B4_example_090826.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_B4_example_090826.do
*
* Worked example for Section 2 of the ITAX revision (rr_plan.md item B4,
* Referee 1 main comment 1: "a 3-country example in a table when describing
* how ranks were given to jurisdictions on the three indicators").
*
* The EU scoreboard published a *percentage score* per indicator (rank within
* the indicator divided by the number of ranked jurisdictions, x100; lower =
* higher risk). A jurisdiction was selected for review if its score was at or
* below the cutoff on ALL three indicators: strength of ties <= 60, financial
* activity <= 40, stability factors <= 70. The paper's multidimensional running
* variable (distance_homi) is the Manhattan distance to the selection boundary,
* positive inside the selection space.
*
* Four illustrative jurisdictions (drop one if the table must have three rows):
*   CYM  Cayman Islands      clears all three cutoffs by a wide margin  -> selected
*   VNM  Viet Nam            clears all three, stability by 0.3 points  -> selected
*   CIV  Cote d'Ivoire       misses stability by 0.7 points             -> not selected
*   RUS  Russian Federation  misses stability by 10 points, others fine -> not selected
*
* Input : output/rd_sample_032522.dta (x, y, z, distance_homi, selected, status)
* Output: tables/rr_B4_worked_example.tex  (booktabs tabular, main text)
*         output/rr_B4_worked_example.csv  (the numbers)
********************************************************************************

* Standalone guard: define paths if master.do section 1 has not been run
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global tables  "$project\tables"
}

local x1 60
local y1 40
local z1 70

* Show the distance-to-boundary column? The table sits in Section 2, before the
* running variable is defined, so the default is NO (author decision 2026-09-08).
* The distances are still written to the CSV and quoted in Section 3's text.
local show_distance 0

use country iso3 x y z distance_homi selected status using ///
    "$output/rd_sample_032522.dta", clear

* Jurisdictions, in display order, with LaTeX-safe display names
local isos  CYM VNM CIV RUS
local n_CYM "Cayman Islands"
local n_VNM "Viet Nam"
local n_CIV "C\^{o}te d'Ivoire"
local n_RUS "Russian Federation"

gen byte keepme = 0
foreach c of local isos {
    replace keepme = 1 if iso3 == "`c'"
}
keep if keepme
assert _N == `: word count `isos''

* Sanity checks: the selection rule reproduces the EU's choice for these rows
gen byte rule = (x <= `x1') & (y <= `y1') & (z <= `z1')
assert rule == selected
* Manhattan distance for single-face cases = signed gap on the binding criterion
gen double gap = min(`x1' - x, `y1' - y, `z1' - z)
assert abs(gap - distance_homi) < 0.01

*-------------------------------------------------------------------------------
* CSV of the numbers
*-------------------------------------------------------------------------------
gen order = .
local i = 1
foreach c of local isos {
    replace order = `i' if iso3 == "`c'"
    local ++i
}
sort order
export delimited country iso3 x y z distance_homi selected status ///
    using "$output/rr_B4_worked_example.csv", replace

*-------------------------------------------------------------------------------
* LaTeX table
*-------------------------------------------------------------------------------
tempname fh
file open `fh' using "$tables/rr_B4_worked_example.tex", write replace text

file write `fh' "\begin{table}[ht!]" _n   // 2026-09-15: [ht!] and the two citations in the note = the author's hand edits to the Overleaf copy, folded in
file write `fh' "\centering" _n
* Note the escaped backquote: an unescaped ` would start macro expansion in Stata
file write `fh' "\caption{Example of EU's scoreboard \`percentage scores' and selection outcomes for four countries\label{t:example}}" _n
if `show_distance' {
    file write `fh' "\begin{tabular}{lcccrc}" _n
    file write `fh' "\toprule" _n
    file write `fh' " & Strength of ties & Financial activity & Stability factors & Distance to & Selected \\" _n
    file write `fh' "Jurisdiction & (cutoff `x1') & (cutoff `y1') & (cutoff `z1') & boundary & for review \\" _n
}
else {
    file write `fh' "\begin{tabular}{lcccc}" _n
    file write `fh' "\toprule" _n
    file write `fh' " & Strength of ties & Financial activity & Stability factors & Selected \\" _n
    file write `fh' "Jurisdiction & (cutoff `x1') & (cutoff `y1') & (cutoff `z1') & for review \\" _n
}
file write `fh' "\midrule" _n

foreach c of local isos {
    qui levelsof x if iso3 == "`c'", local(vx) clean
    qui levelsof y if iso3 == "`c'", local(vy) clean
    qui levelsof z if iso3 == "`c'", local(vz) clean
    qui levelsof distance_homi if iso3 == "`c'", local(vd) clean
    qui levelsof selected if iso3 == "`c'", local(vs) clean

    local sx : di %4.1f `vx'
    local sy : di %4.1f `vy'
    local sz : di %4.1f `vz'
    local sd : di %5.1f `vd'
    if `vd' > 0 local sd "+`=strtrim("`sd'")'"
    else        local sd "`=strtrim("`sd'")'"

    * Bold any score that fails its cutoff (criterion not met)
    if `vx' > `x1' local sx "\textbf{`sx'}"
    if `vy' > `y1' local sy "\textbf{`sy'}"
    if `vz' > `z1' local sz "\textbf{`sz'}"

    local sel = cond(`vs' == 1, "Yes", "No")

    if `show_distance' file write `fh' "`n_`c'' & `sx' & `sy' & `sz' & `sd' & `sel' \\" _n
    else               file write `fh' "`n_`c'' & `sx' & `sy' & `sz' & `sel' \\" _n
}

file write `fh' "\bottomrule" _n
file write `fh' "\end{tabular}" _n
file write `fh' "\begin{flushleft}\footnotesize" _n
file write `fh' "{\bf Note:} Percentage scores from the European Commission's September 2016 scoreboard \cite{europeancommission2016scoreboard}: within each indicator, a jurisdiction's rank divided by the number of ranked jurisdictions, times 100, so that lower scores indicate greater risk. A jurisdiction was selected for review if its score was at or below the cutoff on all three indicators \cite{europeancommission2017methodology}; scores that miss their cutoff are in bold."
if `show_distance' file write `fh' " Distance to boundary is the multidimensional running variable used in Section~\ref{subsec:emp}: the smallest change in percentage-score points needed to move the jurisdiction across the selection boundary, positive for jurisdictions inside the selection space."
file write `fh' _n
file write `fh' "\end{flushleft}" _n
file write `fh' "\end{table}" _n
file close `fh'

di as txt _n "Wrote $tables/rr_B4_worked_example.tex"
type "$tables/rr_B4_worked_example.tex"

if "$otables" != "" copy "$tables/rr_B4_worked_example.tex" "$otables/rr_B4_worked_example.tex", replace   // Overleaf (2026-09-12)
