* F10_targeting.do  |  FIGURE 10 (f:targeting) probability of review/listing [World Bank GNI frozen; live with wb_refresh 1]
* 2026-09-12 (author): no image exported that is not in the draft/online appendix; presentation versions off
* Copied unchanged from do/probbab2.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* ETRs 
use "$input\ITI_CITR_ct_R2.dta", clear
keep if year == 2016
drop country 
tempfile et 
save    `et', replace

* Loading other data
import excel "$input\Profit shifting - Nov 2024.xlsx", sheet("Sheet1") firstrow clear
keep if counterpart =="World"
gen profits_net = value
replace profits_net = -1*value if indicator == "profits_shifted"
collapse (sum) profits_net, by(iso3 year)
keep if year == 2016
tempfile sp
save    `sp', replace 

use "$output\shifted_profits.dta", clear
keep if year == 2016
tempfile sp2
save    `sp2', replace 

import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if iso3 == "" & strpos(lower(country), "czech") > 0
replace iso3 = "MKD" if iso3 == "" & strpos(lower(country), "macedonia") > 0
drop if iso3 == ""
tempfile e
save    `e', replace

*
* 2026-10-30: World Bank GNI read from a frozen copy of the 2026-10-30 pull (do/freeze_wb_vintages.do),
* which reproduces the published figure; global wb_refresh 1 pulls it live instead.
if "$wb_refresh" == "1" {
    wbopendata, indicator(ny.gnp.pcap.cd; ny.gnp.mktp.pp.kd) clear long
    keep if year == 2016
}
else use "$output/wb_frozen_f10_gnp2016_103026.dta", clear

rename countrycode iso3

gen lngnppc = ln( ny_gnp_pcap_cd)

mmerge iso3 using `sp', type(1:1) 
mmerge iso3 using `sp2', type(1:1) 
mmerge iso3 using `et', type(1:1) 
mmerge iso3 using  "$output\regready.dta", type(1:1) ukeep(selected  gdppcn_2015 fdi_2015 fdi_unctad_2015 lngdppcn_2015 status z_distance distance distance_homi) 
mmerge iso3 using `e', type(1:1)
gen europe = _merge == 3

mmerge iso3 using "$output\BL_firstyear.dta", type(n:1) unmatched(master) ukeep(year_*)

replace status = "EU" if europe == 1
replace selected = 0 if selected == .
mmerge iso3 using "$output/fsi20.dta", type(1:1) unmatched(master)

gen ever_gl = year_gl != .
gen ever_bl = year_bl != .
gen ln_sp = ln( profits_net*1000000000 ) 
gen ln_sp2 = ln(Art*1000000000) 


keep if europe == 0

* 2026-09-10 (R&R, R2 minor / rr_plan A9): binned means overlaid on the local
* polynomial fits - 15 quantile bins of each x variable, mean of x and of the
* three outcomes within bin.
foreach x in lngdppcn_2015 EMTR_ct ln_sp lnfsi20 {
    cap drop bin_`x' bx_`x' bsel_`x' bgl_`x' bbl_`x'
    xtile bin_`x' = `x' if `x' < ., nq(15)
    egen bx_`x'   = mean(`x'),       by(bin_`x')
    egen bsel_`x' = mean(selected),  by(bin_`x')
    egen bgl_`x'  = mean(ever_gl),   by(bin_`x')
    egen bbl_`x'  = mean(ever_bl),   by(bin_`x')
    replace bx_`x' = . if bin_`x' == .
}
local bins_lngdppcn_2015 "(scatter bsel_lngdppcn_2015 bx_lngdppcn_2015, msymbol(O) mcolor(blue)) (scatter bgl_lngdppcn_2015 bx_lngdppcn_2015, msymbol(D) mcolor(green)) (scatter bbl_lngdppcn_2015 bx_lngdppcn_2015, msymbol(S) mcolor(black))"
local bins_EMTR_ct       "(scatter bsel_EMTR_ct bx_EMTR_ct, msymbol(O) mcolor(blue)) (scatter bgl_EMTR_ct bx_EMTR_ct, msymbol(D) mcolor(green)) (scatter bbl_EMTR_ct bx_EMTR_ct, msymbol(S) mcolor(black))"
local bins_ln_sp         "(scatter bsel_ln_sp bx_ln_sp, msymbol(O) mcolor(blue)) (scatter bgl_ln_sp bx_ln_sp, msymbol(D) mcolor(green)) (scatter bbl_ln_sp bx_ln_sp, msymbol(S) mcolor(black))"
local bins_lnfsi20       "(scatter bsel_lnfsi20 bx_lnfsi20, msymbol(O) mcolor(blue)) (scatter bgl_lnfsi20 bx_lnfsi20, msymbol(D) mcolor(green)) (scatter bbl_lnfsi20 bx_lnfsi20, msymbol(S) mcolor(black))"


twoway (lpolyci selected lngdppcn_2015, lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
	   (lpolyci ever_gl lngdppcn_2015, lcolor(green%30) fcolor(green%30) alcolor(%0)) ///
	   (lpolyci ever_bl lngdppcn_2015, lcolor(black) fcolor(black%50) alcolor(%0)) ///
	   `bins_lngdppcn_2015' ///
 , legend(order(2 "Reviewed" 4 "Greylisted" 6 "Blacklisted") position(6) rows(1)) ///
   scheme(Modern)  ///
   xlabel(6.90 "1,000" 9.2103 "10,000" 11.512925 "100,000")	///
   xtitle("GNI per capita, 2015 (USD)") ///
   ytitle(Probability) ///
   name(g1, replace) scale(1.2) xsize(13) ysize(10)  ylabel(0(.5)1)
cap graph export "$ographs\t1_091026.png", replace width(3000)
graph export "$graphs\t1_091026.png", replace width(3000)
	
	
twoway (lpolyci selected EMTR_ct, lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
	   (lpolyci ever_gl EMTR_ct, lcolor(green%30) fcolor(green%30) alcolor(%0)) ///
	   (lpolyci ever_bl EMTR_ct, lcolor(black) fcolor(black%50) alcolor(%0)) ///
	   `bins_EMTR_ct' ///
 , legend(order(2 "Reviewed" 4 "Greylisted" 6 "Blacklisted") position(6) rows(1)) ///
   scheme(Modern)  xtitle("Effective average tax rate") ///
   ytitle(Probability) yline(0) /// 
   name(g2, replace) scale(1.2) xsize(13)   ylabel(0(.5)1)  ysize(10)
   cap graph export "$ographs\t2_091026.png", replace width(3000)
   graph export "$graphs\t2_091026.png", replace width(3000)
	

 twoway (lpolyci selected ln_sp, lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
	   (lpolyci ever_gl ln_sp, lcolor(green%30) fcolor(green%30) alcolor(%0)) ///
	   (lpolyci ever_bl ln_sp, lcolor(black) fcolor(black%50) alcolor(%0)) ///
	   `bins_ln_sp' ///
 , legend(order(2 "Reviewed" 4 "Greylisted" 6 "Blacklisted") position(6) rows(1)) ///
   scheme(Modern) ////
      xlabel(16.118096 "10m" 18.420681 "100m" 20.7232 "1b" 23.0258 "10b" 25.328436 "100b")	///
	     xtitle("Shifted profits, billions") ///
   ytitle(Probability) yline(0) /// 
    name(g3, replace) scale(1.2) xsize(13) ysize(10) ylabel(0(.5)1) yscale(range(0 1))
   cap graph export "$ographs\t3_091026.png", replace width(3000)
   graph export "$graphs\t3_091026.png", replace width(3000)
	

 twoway (lpolyci selected lnfsi20, lcolor(blue) fcolor(blue%30) alcolor(%0)) ///
	   (lpolyci ever_gl lnfsi20, lcolor(green%30) fcolor(green%30) alcolor(%0)) ///
	   (lpolyci ever_bl lnfsi20, lcolor(black) fcolor(black%50) alcolor(%0)) ///
	   `bins_lnfsi20' ///
 , legend(order(2 "Reviewed" 4 "Greylisted" 6 "Blacklisted") position(6) rows(1)) ///
 scheme(Modern) ///
   xlabel(2.9957323 "20" 5.2983 "200" 7.6 "2,000")	///
	     xtitle("Financial Secrecy Index Score") ///
   ytitle(Probability) yline(0) /// 
    name(g4, replace) scale(1.2) xsize(13) ysize(10)  ylabel(0(.5)1)
 cap graph export "$ographs\t4_091026.png", replace width(3000)
 graph export "$graphs\t4_091026.png", replace width(3000)
 
grc1leg g1 g2 g3 g4 , legendfrom(g1) cols(2) ycommon
		 
* [off 2026-09-12] graph export "$ographs\targeting_091026.png", replace width(3000) 
