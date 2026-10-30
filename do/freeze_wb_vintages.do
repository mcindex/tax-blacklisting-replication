* freeze_wb_vintages.do  |  2026-10-30: one-off provenance script, not called by master_rr.do
* Freezes the World Bank series that D05_rd_sample.do and F10_targeting.do used to pull live (wbopendata),
* so the package no longer depends on the Bank's current vintage. Run once from the package folder after
* master_rr.do has set the globals; its outputs ship in output/.
*
* (1) D05: the four 2010-2018 series as pulled in March 2022, recovered from the shipped RD sample
*     (output/rd_sample_032522.dta). D05 merges them unmatched(master), so the 209 sample jurisdictions
*     are all it ever used. Stored in wbopendata's wide layout (countrycode yr2010-yr2018).
* (2) F10: GNI per capita (current US$) and GNI (PPP) for 2016, pulled live on the date in the file name;
*     this vintage reproduces the published Figure 10 (2026-10-29 rerun, byte-identical).

* (1) D05 series, 2022 vintage
foreach s in pov gdppc gdppcn fdi {
    local vars ""
    forvalues t = 2010/2018 {
        local vars `vars' `s'_`t'
    }
    use iso3 `vars' using "$output/rd_sample_032522.dta", clear
    rename iso3 countrycode
    rename `s'_* yr*

    save "$output/wb_frozen_d05_`s'_032522.dta", replace
}

* (2) F10 series, current vintage
wbopendata, indicator(ny.gnp.pcap.cd; ny.gnp.mktp.pp.kd) clear long
keep if year == 2016
save "$output/wb_frozen_f10_gnp2016_103026.dta", replace
