********************************************************************************
* D06_regready_frozen_gdp.do
* Freeze the World Bank GDP-per-capita vintage in the RD analysis file
*   output/regready_042822.dta  ->  output/regready_042822_gdp2026_frozen20260820.dta
********************************************************************************
*
* WHY. lngdppcn_2015 (the RD covariate) is pulled live from the World Bank API
* in D05_rd_sample.do (wbopendata), and the Bank revises history, so every
* rebuild would silently change the covariate. The analysis file is therefore
* frozen once, and every exhibit reads the frozen copy.
*
* DEFAULT: the frozen file is never overwritten.
* TO UPDATE THE VINTAGE: set global wb_refresh 1 in master_rr.do and run Part 1
* (run_data 1): D05 pulls the current World Bank series, A_tab_global_poly
* writes regready_042822.dta, this file replaces the frozen copy (the previous
* one is kept with a _replaced_<date> suffix), and D07 re-applies the Puerto
* Rico fix. The file name keeps its 20260820 stamp so no downstream path changes.
*
* Inputs : output/regready_042822.dta
* Outputs: output/regready_042822_gdp2026_frozen20260820.dta
*          output/lngdppcn_vintage20260820.dta (the GDP-per-capita columns only)
*
* CHANGE LOG
*   2026-09-15  Trimmed to the freezing step (author: not needed for the results, keep for replication,
*               switched off by default). The legacy Table 3 variants (reporting conventions x GDP
*               vintages, rd_regs042822_combined_*_TABLE.tex, rr_table3_estimator_comparison.csv) are no
*               longer produced; the full former version is in do/old/replication_rr_pre_legibility_091526/.
*   2026-09-12  Copied from do/rr_table3_conventional_082026.do for the R&R replication package.
********************************************************************************

local frozen "$output/regready_042822_gdp2026_frozen20260820.dta"

capture confirm file "`frozen'"
local frozen_exists = (_rc == 0)

if `frozen_exists' & "$wb_refresh" != "1" {
    di as txt "Frozen vintage already exists, leaving untouched: `frozen'"
    di as txt "(set global wb_refresh 1 to replace it with the vintage in regready_042822.dta)"
}
else {
    * keep the previous frozen copy, if any
    if `frozen_exists' {
        local stamp = string(date(c(current_date), "DMY"), "%tdCCYYNNDD")
        copy "`frozen'" "$output/regready_042822_gdp2026_frozen20260820_replaced_`stamp'.dta", replace
        di as res "Previous frozen vintage kept as regready_042822_gdp2026_frozen20260820_replaced_`stamp'.dta"
    }
    di as res "Freezing the current World Bank vintage -> `frozen'"
    copy "$output/regready_042822.dta" "`frozen'", replace

    * Also archive just the GDP-per-capita columns, so a future rebuild can
    * merge them back in by iso3 instead of calling the World Bank API.
    use "$output/regready_042822.dta", clear
    keep iso3 gdppcn_* lngdppcn_*
    lab data "GDP per capita (WB ny.gdp.pcap.cd), frozen by D06_regready_frozen_gdp.do"
    save "$output/lngdppcn_vintage20260820.dta", replace
}
