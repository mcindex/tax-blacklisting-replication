* D11_aeoi_ontrack.do  |  DATA: AEOI effectiveness outcome (A.v) added to the RD analysis file; tax transparency mean recomputed
* 2026-09-15 (author): new outcome under (A) Tax transparency, item (v): aeoi_ontrack = 1 if the Global Forum's
*   overall AEOI rating is "On Track" (OECD AEOI ratings table, Datawrapper chart ZAIre v71, published 2026-07-08);
*   0 if rated Partially Compliant / Non-Compliant, Not yet reviewed, No data, or absent from the table.
*   This is the EU's [future] criterion 1.1b ("largely compliant" rating on CRS implementation).
*   tax_transparency_now = mean of (i)-(v) [was (i)-(iv); the old mean is kept as tax_transparency4_now].
* Inputs : $output/regready_042822_gdp2026_frozen20260820.dta   (frozen, PRI-fixed analysis file; NOT modified)
*          $output/aeoi_ontrack_091526.dta                       (python/aeoi_ratings_091526.py)
* Output : $output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta  (read by the RD scripts from 2026-09-15:
*          T03, F04, F05, A_tab_wild_bootstrap, P_fig_coefplot_boot, A_tab_global_poly, A_fig_donuts, P_tab_data_section)
********************************************************************************

use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
isid iso3

* the stored mean must be the mean of the four components (guards against a silent definition change)
egen double _tt4 = rowmean(aeoi_2020_now per_EU_now eoi_now maa_now)
assert reldif(_tt4, tax_transparency_now) < 1e-6 | (missing(_tt4) & missing(tax_transparency_now))
drop _tt4

merge 1:1 iso3 using "$output/aeoi_ontrack_091526.dta", keepusing(aeoi_ontrack aeoi_rated aeoi_overall_rating) keep(master match) generate(_m_aeoi)   // the frozen file already carries a _merge variable
assert _m_aeoi == 3   // every analysis jurisdiction is in the coded file (absent from the OECD table = 0 there)
drop _m_aeoi
assert inlist(aeoi_ontrack, 0, 1)

rename tax_transparency_now tax_transparency4_now
lab var tax_transparency4_now "Tax transparency mean of (i)-(iv) (before 2026-09-15)"
egen tax_transparency_now = rowmean(aeoi_2020_now per_EU_now eoi_now maa_now aeoi_ontrack)
lab var tax_transparency_now "Tax transparency mean of (i)-(v), incl. AEOI rated On Track"
lab var aeoi_ontrack         "AEOI overall rating On Track (Global Forum, Jul 2026); 0 otherwise incl. not rated"

di as res _n "D11: AEOI On Track and the recomputed transparency mean"
tab aeoi_overall_rating, missing
sum aeoi_ontrack tax_transparency4_now tax_transparency_now
corr tax_transparency4_now tax_transparency_now

save "$output/regready_042822_gdp2026_frozen20260820_aeoi091526.dta", replace
