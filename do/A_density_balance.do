* A_density_balance.do  |  APPENDIX f:density histograms/density tests (_091326), legacy balance/plot blocks disabled
* 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* 2026-09-12: all confidence levels 90 -> 95 (author: 95% CIs everywhere, stars 10/5/1%). Backup in do/old, suffix _pre091226b
* Copied unchanged from do/balance_tests_062922.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* Loading RD sample
* 2026-09-10 (R&R): frozen PRI-fixed file; eligible-sample and z-frontier running
* variables added so the existing loops run unchanged on the new design.
use "$output/regready_042822_gdp2026_frozen20260820.dta", clear
gen byte elig = (status != "LDC" | iso3 == "VUT") & status != "EU Tax Transparency Agreement"   // 2026-09-13: fuzzy design adopted (author decision) -- sample excludes the five EU tax transparency agreement jurisdictions
gen distance_e   = distance   if elig
gen z_frontier_f = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .)   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
gen z_frontier   = z_distance if (x_distance >= 0 | x_distance == .) & (y_distance >= 0 | y_distance == .) & elig   // 2026-09-13 (coherence review fix): explicit -- Stata's missing sorts high, so jurisdictions lacking a ties or financial score count as clearing it (the EU rule); 102 obs
lab var distance_e   "Distance to boundary, eligible sample"
lab var z_frontier_f "Stability factors, frontier, full sample"
lab var z_frontier   "Stability factors, frontier, eligible sample"

*****************
* DENSITY TESTS * 
*****************
foreach cutoff in distance_e z_frontier {   // 2026-09-12: only the two panels in the appendix   // 2026-09-10: was distance distance_homi z_distance
	qui sum `cutoff'	
	local k = round(min(sqrt(`r(N)'), 10*ln(`r(N)')/ln(10)))  // Calculating number of bins if we run a histogram over the whole distribution
	local lower =  0 - `r(min)'
	local higher = `r(max)' - 0 
	local perlower  = (`lower')/ (`lower' + `higher') 
	local perlowerk = round(`perlower'* `k')
	local perhigher  = (`higher')/ (`lower' + `higher') 
	local perhigherk = round(`perhigher'* `k')
	
	* Setting points for p-value text
	global midway = (`higher' / 2) - 10
	if inlist("`cutoff'", "z_distance", "z_frontier", "z_frontier_f") {
		global midpoint = 0.035
	}
	else {
		global midpoint = 0.025
	}
	
	di `midpoint' 
	di `midway'

	twoway (histogram `cutoff' if `cutoff' < 0, frequency fcolor(blue) lcolor(black) bin(`perlowerk')) ///
		   (histogram `cutoff' if `cutoff' >=0, frequency fcolor(red) lcolor(black)  bin(`perhigherk'))  /// 
			,scheme(modern) xline(0)												  ///
			 xtitle(Distance) 														  ///
			 ytitle(Number of observations) 										  ///
			 yscale(lcolor(black)) ylabel(, tlcolor(black)) 						  ///
			 xscale(lcolor(black)) xlabel(, tlcolor(black)) 						  ///
			 plotregion(lcolor(black)) 												  ///
			 legend(off)
    graph export "$graphs\histogram_`cutoff'_091326.png" , replace width(2000)
	graph export "$ographs\histogram_`cutoff'_091326.png", replace width(2000)		
	

	rddensity `cutoff', 	///
			  plot 	///
			  graph_opt(		    ///
			  ytitle(Density) 			///
			  xtitle(Distance) ///
			  yscale(lcolor(black)) ylabel(, tlcolor(black)) 	///
			  xscale(lcolor(black)) xlabel(, tlcolor(black)) 						  ///
			  plotregion(lcolor(black)) ///
			  legend(off) scheme(modern) ) nohistogram
	global pval: di %3.2f e(pv_q)
	graph play "$do\densitydo.grec"
	graph export "$graphs\densitytest_`cutoff'_091326.png" , replace width(2000)
	graph export "$ographs\densitytest_`cutoff'_091326.png", replace width(2000)
	
	
}
