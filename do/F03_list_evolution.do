* F03_list_evolution.do  |  FIGURE 3 (glbl) grey/blacklist counts at every Council revision, Dec 2017 - Feb 2026
* Copied unchanged from do/rr_fig3_lists_2026_091226.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_fig3_lists_2026_091226.do
*
* Figure 3 (glbl) extended to the latest Council revision (17 Feb 2026):
* number of jurisdictions on the EU blacklist and greylist at each revision,
* as in blacklist_data_032522.do (Figure time_blgl_032522.png, to Feb 2022),
* drawn from the extended list file of blacklist_update_090926.do. Two dashed
* vertical markers (author, 2026-09-12) show where the paper's outcome data
* end: governance outcomes (RD snapshots and the governance DiD panel) at
* Feb 2022, economic outcomes at Dec 2024 (FDI; deposits run to 2026q1, see
* the figure note).
*
* -> graphs/time_blgl_2026.png (+ Overleaf time_blgl_2026_091226.{png,pdf})
*    output/rr_fig3_list_counts_2026.csv
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global graphs  "$project\graphs"
}
cap graph set window fontface "LM Roman 10"

use "$output/EU_BL_full_list_2026.dta", clear
gen num_BL = List == "BL"
gen num_GL = List == "GL"
collapse (sum) num_BL num_GL, by(Date)
format Date %tdCCYY-NN
export delimited using "$output/rr_fig3_list_counts_2026.csv", replace
list, clean noobs

* axis: 1 Jan of each year 2018-2026; markers: 24 Feb 2022 (last revision used
* for the governance outcomes) and 31 Dec 2024 (last FDI year)
local xl
forvalues y = 2018/2026 {
    local xl `xl' `=td(01jan`y')'
}
local gov  = td(24feb2022)
local econ = td(31dec2024)
qui sum num_GL
local ytop = r(max)

twoway (line num_BL Date, lcolor(black) lwidth(medthick))                     ///
       (line num_GL Date, lcolor(blue) sort lwidth(medthick))                 ///
       , ytitle(Number of jurisdictions) xtitle("")                           ///
         xlabel(`xl', format(%tdCCYY) labsize(small))                         ///
         xline(`gov'  , lpattern(dash) lcolor(gs8))                           ///
         xline(`econ' , lpattern(dash) lcolor(gs8))                           ///
         text(`ytop' `gov'  "Governance outcomes" "measured to here", place(w) size(vsmall) color(gs6) just(right)) ///
         text(`ytop' `econ' "Economic outcomes"   "measured to here", place(w) size(vsmall) color(gs6) just(right)) ///
         legend(order(1 "Blacklist" 2 "Greylist") position(6) rows(1))         ///
         scheme(modern) xsize(8) scale(1.3)
graph export "$graphs/time_blgl_2026.png", replace width(3000)
if "$ographs" != "" graph export "$ographs/time_blgl_2026_091226.png", replace width(3000)
if "$ographs" != "" graph export "$ographs/time_blgl_2026_091226.pdf", replace
