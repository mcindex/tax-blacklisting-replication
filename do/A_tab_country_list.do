* A_tab_country_list.do  |  APPENDIX t:list jurisdictions within the bandwidth (countrylist_091326)
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* Copied unchanged from do/rank.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
use "$output/haveninfo_091026.dta", clear   // 2026-09-13 (coherence review fix): the file A_fig_effort_havens_hrm.do builds (BVI->VGB recoded); was the 2021 haveninfo.dta


mmerge iso3 using "$output/fsi20.dta", type(1:1) unmatched(master)

* 2026-09-10 (R&R): Euclidean distance from the frozen PRI-fixed file; eligible sample = non-LDC plus Vanuatu
cap drop distance
mmerge iso3 using "$output/regready_042822_gdp2026_frozen20260820.dta", type(1:1) ukeep(distance) unmatched(master)

keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions; 2026-09-10: was drop if status == "LDC"

keep if distance !=.
sort distance iso3   // 2026-09-15: iso3 breaks ties (Belize and Peru share a distance), so the row order is reproducible

keep if abs(distance) <= 20   // 20 = max MSE bandwidth in the revised Table 3

* br country distance_homi FSIrank_20 SecrecyScore20 EU_blacklist oldlist sink blacklisted greylisted 

tostring  oldlist haven sink , replace
foreach var of varlist oldlist haven sink {
    replace `var' = "X" if `var' == "1"
	replace `var' = "" if `var' == "0" | `var' == "."
	
}
replace country = "C\^{o}te d'Ivoire" if strpos(country, "te d'Ivoire") > 0   // 2026-09-15: encoding-proof match (batch mode printed "C?te"); LaTeX accent as in T01
*replace distance_cutoff = round(distance_cutoff,.1)
format distance  %9.3gc
listtab country distance FSIrank_20 SecrecyScore20 oldlist haven sink  ///
		using "$otables\countrylist_091326.tex", rstyle(tabular) replace  ///
		head("\begin{tabular}{rrrrrrr}" "\toprule"										///
		    `"Jurisdiction&\shortstack{Distance \\ to \\ cutoff}&\shortstack{FSI \\ Rank \\ (2020)}&\shortstack{Secrecy \\ Score \\ (2020)}&\shortstack{2015 \\ EU Blacklist}&Tax haven* & Sink OFC**\\"' ///
			"\midrule") foot("\bottomrule" "\end{tabular}")
			
			
			use "$output/fsi20.dta", clear
if "$otables" != "" copy "$otables\countrylist_091326.tex" "$tables\countrylist_091326.tex", replace
