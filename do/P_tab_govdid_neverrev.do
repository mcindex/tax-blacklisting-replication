* P_tab_govdid_neverrev.do  |  PENDING appendix table: listing DiDs with never-reviewed controls (t:govdid_neverrev_prov)
* Copied unchanged from do/rr_A2_neverrev_table_091226.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_A2_neverrev_table_091226.do
*
* Appendix table (provisional, author request 2026-09-12): governance DiDs with
* NEVER-REVIEWED jurisdictions as the control group -- treated = ever greylisted
* / ever blacklisted, full sample and within the RD bandwidth (|Euclidean
* distance| <= 20) -- next to the review design's bandwidth column. Reads the
* estimates posted by rr_A2_govdid_all_082526.do (specs bw20, glR, glRb, blR,
* blRb in output/rr_A2_govdid_results.dta); no estimation here. Layout as
* Table 4 (column numbers, one stacked header per column).
*
* -> tables/rr_A2_govdid_neverrev.tex (+ Overleaf rr_A2_govdid_neverrev_091226.tex)
* Requires 13d (rr_A2_govdid_all_082526.do) run after 2026-09-12 14:00.
********************************************************************************
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global output  "$project\output"
    global tables  "$project\tables"
}
use "$output/rr_A2_govdid_results.dta", clear
keep if inlist(spec, "bw20", "glR", "glRb", "blR", "blRb")
gen byte col = .
replace col = 1 if spec == "bw20"
replace col = 2 if spec == "glR"
replace col = 3 if spec == "glRb"
replace col = 4 if spec == "blR"
replace col = 5 if spec == "blRb"
assert col != .
gen byte row = .
replace row = 1 if outcome == "inclusive"
replace row = 2 if outcome == "cbcr"
replace row = 3 if outcome == "maa"
replace row = 4 if outcome == "map"
assert row != .
local lab1 "(1) IF membership"
local lab2 "(2) CbC-MCAA signature"
local lab3 "(3) MAA convention signature"
local lab4 "(4) MAP profile publication"

tempname fh
file open `fh' using "$tables/rr_A2_govdid_neverrev.tex", write replace text
file write `fh' "\begin{adjustbox}{max width=\textwidth}" _n
file write `fh' "\begin{tabular}{l*{5}{c}}" _n
file write `fh' "\toprule" _n
file write `fh' " & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} \\" _n
file write `fh' " & \multicolumn{1}{c}{\shortstack{Reviewed \\ Bandwidth \\ $|d| \leq 20$}} & \multicolumn{1}{c}{\shortstack{Greylisted \\ Full sample}} & \multicolumn{1}{c}{\shortstack{Greylisted \\ Bandwidth \\ $|d| \leq 20$}} & \multicolumn{1}{c}{\shortstack{Blacklisted \\ Full sample}} & \multicolumn{1}{c}{\shortstack{Blacklisted \\ Bandwidth \\ $|d| \leq 20$}} \\" _n
file write `fh' "\midrule" _n
file write `fh' "\multicolumn{6}{l}{\emph{Average treatment effect on the treated (controls: jurisdictions never reviewed)}} \\" _n
forvalues r = 1/4 {
    local l1 "`lab`r''"
    local l2 ""
    forvalues c = 1/5 {
        qui sum att if row == `r' & col == `c'
        local b : display %5.3f r(mean)
        qui sum se if row == `r' & col == `c'
        local s : display %5.3f r(mean)
        qui levelsof stars if row == `r' & col == `c', local(st) clean
        local l1 "`l1' & `b'`st'"
        local l2 "`l2' & (`s')"
    }
    file write `fh' "`l1' \\" _n
    file write `fh' "`l2' \\" _n
}
file write `fh' "\midrule" _n
file write `fh' "\multicolumn{6}{l}{\emph{Average pre-treatment event-study coefficient (window) $=0$, \$p\$-value}} \\" _n   // 2026-09-15: pt_p from F06 is now the Pre_avg test (option 2)
forvalues r = 1/4 {
    local l1 "\hspace{.4cm} Outcome (`r')"
    forvalues c = 1/5 {
        qui sum pt_p if row == `r' & col == `c'
        local p : display %5.3f r(mean)
        local l1 "`l1' & `p'"
    }
    file write `fh' "`l1' \\" _n
}
file write `fh' "\midrule" _n
local lt "Treated jurisdictions"
local lc "Control jurisdictions"
forvalues c = 1/5 {
    qui sum n_treat if row == 1 & col == `c'
    local lt "`lt' & `=r(mean)'"
    qui sum n_ctrl if row == 1 & col == `c'
    local lc "`lc' & `=r(mean)'"
}
file write `fh' "`lt' \\" _n
file write `fh' "`lc' \\" _n
file write `fh' "\bottomrule" _n "\end{tabular}" _n "\end{adjustbox}" _n
file close `fh'
type "$tables/rr_A2_govdid_neverrev.tex"
if "$otables" != "" copy "$tables/rr_A2_govdid_neverrev.tex" "$otables/rr_A2_govdid_neverrev_091226.tex", replace
