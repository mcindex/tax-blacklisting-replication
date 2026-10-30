* A_tab_first_stage.do  |  APPENDIX table rd_fs_091326 first stage of the fuzzy design (actual EU review on each threshold)
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/first_stage_042722.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* Simple graph showing effectiveness of different thresholds
* 2026-09-10 (R&R): frozen PRI-fixed file, rule-eligible sample (non-LDC + Vanuatu), z-frontier running variable
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
keep if (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen z_frontier = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
gen z_frontier_above = z_frontier >= 0 if z_frontier < .
lab var z_frontier "Stability factors cutoff (frontier)"
cap drop ever_either   // 2026-09-10: already in the frozen file
egen ever_either = rowmax(ever_bl ever_gl)

replace both = ever_either
est drop _all
replace selected = reviewed

foreach c in x_distance y_distance z_distance distance z_frontier  {   // 2026-09-10: was ... z_distance distance_homi distance
	rdrobust selected `c', c(0) all masspoints(off)
			assert e(h_l) < 72
				assert  e(b_l)  < 72

	est sto `c'
}

* Writing to latex

esttab x_distance y_distance z_distance distance z_frontier 																///
	   using "$otables/rd_fs_091326.tex", replace 								///
	   title("First stage: impact of crossing each threshold on EU review of jurisdictions\label{t:select}") ///
	   booktabs 																///
	   label																    ///
	   keep(Robust) 															///
	   se 																		///
	   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
	   nonotes  																/// 
	   coeflabels(Robust "Robust RD estimate") 									///
	   mgroups("{\bf EU selection criteria}"  									///
	           "{\bf \shortstack{Constructed\\running variables}}" 				///
			   , pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(})   ///
			    span erepeat(\cmidrule(lr){@span})) 							///
	   mtitles("\shortstack{strength\\of ties}" 								///
	           "\shortstack{financial\\activity}" 								///
			   "\shortstack{stability\\factors}"  								///
			   "\shortstack{distance to\\selection boundary}" 								///
			   "\shortstack{stability factors\\(frontier) $ ^{\dagger} $}") 									///
       postfoot(																///
	             \bottomrule \end{tabular}										///
				 \begin{minipage}{0.95\textwidth} \footnotesize					///
				{\bf Notes:} Outcome is $ = 1 $ if the jurisdiction was reviewed ///
			             by the EU (the first stage of the fuzzy RD design). Sample: jurisdictions ///
						 eligible for rule-based selection (all non-LDC jurisdictions plus  ///
						 Vanuatu, excluding the five jurisdictions reviewed under EU tax ///
						 transparency agreements) that were assigned a score. Each column    ///
						 indicates a separate running variable. Robust bias-corrected local-linear estimate with robust standard error, MSE-optimal bandwidth. 			///
						 \\ $ ^{*} p<0.10,  ^{**} p<0.05,  ^{***} p<0.01 $  ///
						 \\ $ ^{\dagger} $ = stability factors score, restricted ///
						 to jurisdictions clearing the strength-of-ties and   ///
						 financial-activity thresholds. ///						
             \end{minipage} \end{table}) 

if "$otables" != "" copy "$otables/rd_fs_091326.tex" "$tables/rd_fs_091326.tex", replace
