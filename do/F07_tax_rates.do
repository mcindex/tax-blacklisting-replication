* F07_tax_rates.do  |  FIGURE 7 (fig:ctr) statutory/EATR event studies
* Copied unchanged from do/new_etr.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
* 2026-10-28: random-number state for the wild bootstraps of Figure 7(a)-(b).
* The published figure came from the 2026-09-13 run, in which this file had no seed and inherited
* the stream left by the no-LDC F06 run before it. This is that state (c(rngstate) at the start of
* this file, recovered by replaying the session: output/run_seed_replay.do in the project folder).
* Setting it here reproduces the published confidence intervals exactly, whatever ran before.
set rngstate XAAe6a30a03bbbbca5b6480f80c72b571b6fce64619fc918e6ec62e5686aade1024e2cc8753d9ee3af4a6c15943aada08e2f3b1a0f4b6eec7d628067466fe4d843bd68bb07022ef606e3bba5f87c654730cc00b2edecfefa65c4c7b74542ae9d443c0d8d904813b1f38f15a0b81b67f3ac3bdfc5fef0e1719606fc35e860788b00fef1f41711e4cccb9c745a5a6286d1a635d5c6a7057a83bb1c1e52a422fba3f54c3107afcc1e995065818e4fef01f8b933050e51526af6e9b7132b5f2d3766421896ac743b6b4842e3beacce6f11fad72b1e3efc4a8ca0271670c3a2b0e1b2b6063b50cb2d93b6040b11ce49bc8a7448b6e20dced673d070159f0694e1ad67cf101bcaf4f57faa4a9f0a158456bf99c8497d54e26d1e0daab0cc0d8f791ceb20ebf483c1370ebc6f6da23aef2e06eb6301fbffafa8733029bb0fa73905aac7ac122c7dc8cd3da65ecb4566fac6361edfd563c9da7ddb3c50be7db98cb57be2831b26366383287172e41c752df61d8dbc0a5bd28770a3c00816a3fde1c4706627c0856a3dd5711368efdac8183cf1b1b9a02bc5fbe98d8959702bbaf257eb113309b0b061000e6f05157d25f5c07fe41ec6bb7f3ab0be2a7ed77a29f2a95dc46c410d705733014cecc98de960d021033a3af1623e85f6aecfb024c96d00832d0b1349482504f03a42860adf404080cb1f20b4f0f580017c03cbddb566a1f0107bdbc1f05badcf3f03c63b3370c4f4f8ad443fdcb838a6700052f5bc9b172fca254a4c8f2169d92ad8d15405d16ea1daf0d8f6c9015826fdf824d3e24ca92811a0ad4ff37c5a809f7a7f2d5bd927cd57ab6635ed011081ff2527adf27fc18dd2d5ec30cfbf1a80f1d09090490adbfd616dad46bb4e66a2200f84ce274ccb118e2488dff2d706033d8d74aea57c880778e36350a4bc95c09e4f7ef7951f82bb8713c9479c61e0737221edab2acd508bd8b0b83a2c96ae1ac111922c0f9bdc8a67dd08e266dc030a4a93ee2817e821e30f1ccc25356b7efbae365f10661b6d99f652ad1a685dbfb7857d952a0353c5761a36b464c7a1cd320b923a985384b72dd381148e5621b5edb4e58ab01fd7c1908d2e3765a386433d2a2f9bdf7eda4140db38572a0576b90f969d19cb58b5484e3e0c95c715c6c9b9946de8f6db8ed8afe24f347531d686c1823834d8f6d81bf12295671719bdc78d83ef4f8ba8e6364858b4886d40a209930d6cdaa37e817c16d1b05e932158b7a3d47858768bb8f7f1261ada52cfad94ac7258a198eb37944f8202e724d60099e76743ea842e9e5919ce9bcbcb6b48868b0df0dd083afecc786ba8786021234ed43553ca70a1a5699e946492f8850cd47fd84e4cde64744887c2bf8d8f0c9c779c5727c9a827de2c233263a7e9071c35b15b6234f8af6ce3c214592325ced04d7ec699acd55308c87210e5b506b04ffa7fbe74670303f08d7e49cba5d646ee7b3e3fd4a0da0212e724b7060b2479c41dbc5b1e72bfa76d2fa173913d8f8ae193080caee31524530f2ea7882d505d9ad87831c900fa307696969a892b426e4217ac21f301cad65e228a8867567fdf99b75e7b25c61cd9b76d58ae156bfb308e229015596bf89f076749c84931d2ce2829ca036700fc1b378770baf3fee9a304b5195e4a0f5df49769b67198373bcd9368049ced59158a330598442c963aeb77e800f5191ee1dd95cf3fb404413ea781d7b5f86ba7ca6ea1ae71b6f5e44d0792b727382721a216d4502b72255a76b3f0aa19ecad3d2141bdfd380130225c95ce54860c863c776fb38f945177cc05901f54ae6571189b9301c77249e03d9a91e1405c09082b68857e277db807138941f704c50ab8397efff960e35f4097256c9727a686888b380c49078ee97b9e5731d8306ccdbc754fdf98698eddff150825511c68d9f739ca14ae0bffa2d098b7779f56dfe3581e901c7f8a6a18c4448ed0ddac9e59f7ec83ceefee395b97efa5893a69cc2fcb59834ec60e47e96cbfd9484cfec375ef55186ae7fe14ad5127236aee2f11f312e1b5d38a208142e78ed42fe1c9b3a45fa676575ced8aa38be81928ce5085abe7a4f828f54bbea597f47a25a0fd9ff4b2aac0e61424ad7fd1327ea670656dc543ac98eb754d8267d3132f7b85265863acae85a5c2286988f2a28bc8cc39f2b730fd549cb1084e427d9eb6c176b87ad53a63ecc81284e70112d4ce65443319de6de148eb052e49be171d520030f32cc4d549e99cf3f58e857a187728df3a4d26b13acb79bef514eecf924a8b4918dfcc1c9b0464579d44773a2cdaaa59d2beb6cb8c07c8e319e521ce34affe570e577486a9410f08ff7898808fb5e957e0bf2a553a433d7e291b36b9e87d7699ddf5d8d4caf89a4842d50e6cd16d7a09df73eaaadebdff60cc35c379ef5089dba416f5c0590b134590248cf4771762a6f56513cfcab759f0e388efbcd17ea6107e45425fff11811acd486c5fece49c8cf78a34b9a4e5a186a6c77e725c7684526659f65d904cabd934b532d7a5f317693dfedbefa12078a7b308f09168be36118cb74849d0e10d598b4da2cba0d174bc32223f7d3973edd947f0d024b4bd365ad7e800269818ac85a5cdc93f6d726abf95548f47cbf4e90800ab93c19b4073c1e1b47a69d504a53abe18391965eeed788cd3833f659e995241b2999d18b854378cbb27f1401e61dbef5b65457522a4363fc66b582753c9385ed4628f29531306fd98282340e5cddbef08961bf97e3166ae21abc535d6102467d0b5e1229bb47304262b70227c9a2a1920dd5307f38c0f2d56f8de0824e6f847e205d4387ab4851b537e53a90f54294f1d78c0370d9b674f653cd3ee42a369b05600c4721bd55fefc53735dd3155ef5783d6aea2b0e69ba99fdc3b625be65f9e4322fab23f680c33de4eba67c777c324d30d9b86cb437e80b08e9fdc0124cd0d63c874bc0a1a9ddbeda7409eaa4612b4672489a6d7371c5c8fd2a1dbc01083aa97382cc8d265de844bda2d00b872336f98adc5d949ed8d15786c3ff1b3c2c3b161f7900a389e61ef695a1555180caec8f0bb24c73a7d09baa014418f72c8db4bb8f6b17fed6530fcf47e1fa8f00511466f36df70257179c2565d4adb986737aec23e19085ae371cff38608bbba63ea48bebaf6400fe88e89482d15e24856ec95c4387a11d665f686dfc2c234973d3ea5abb8acb909196a1bb7acf0f4b59f9b7955b1d10c40c3a7a6d549711119091bfe39f297ba96cb5dec093320f4877ea00f62d6589dbca38241b0b83834331ffe3475a4a74904beed78c5cd5a388b4c8c348f7dddacec3ce48af29092551b87b32fb234196005462c9d3f398eff1c8a65676de7736d1493dca15d0c7e3e93b59c2d49402e7ef34f50bb34022d0a8c60e34925f007d0b71a745c1447fc0199924bfda58963cf7e3cd65a0d77f2cb204b3910db1113142a7afcc1aa55da86f25afbedc56312bf4b62b05ee6952259d75f8b4748ebeb98e5d7a17d5795d03c941c2d9360cde910001000000e40bbd

********************************************************************************
* EU States
import excel "$input\eu_states.xlsx", sheet("Sheet1") firstrow clear
kountry country, from(other) stuck
rename _ISO3N_ numcode
kountry numcode, from(iso3n) to(iso3c) m
drop NAMES_STD MARKER numcode
rename _ISO3C_ iso3
replace iso3 = "CZE" if country == "Czechia"
assert iso3 != ""
tempfile e
save    `e', replace

* Profits 
import excel "$input\Profit shifting - Nov 2024.xlsx", sheet("Sheet1") firstrow clear
keep if counterpart =="World"
reshape wide value, i(iso3 year) j(indicator) string
keep iso3 year valueshifted_profits valuetax_gain_share_of_CITrev
tempfile profits
save    `profits', replace

* EATR by industry 
use "$input\ITI_CITR_cit_R2.dta", clear
drop country industry_desc EMTR
reshape wide EATR_cit, i(iso3 year) j(industry) string
tempfile iear 
save    `iear', replace 


use "$input\ITI_CITR_ct_R2.dta", clear

mmerge iso3 using `e', type(n:1) unmatched(master)
gen eu = _merge == 3 

mmerge iso3 using  "$output\regready.dta", type(n:1) ukeep(selected reviewed) unmatched(master)
mmerge iso3 using "$output\BL_firstyear.dta", type(n:1) unmatched(master) 
replace year_bl = 0 if year_bl == .
replace year_gl = 0 if year_gl == .

egen c = group(iso3)
tsset c year 

mmerge iso3 year using `iear', type(1:1) unmatched(master)
mmerge iso3 year using `profits', type(1:1) unmatched(master)
gen pmatch = _merge == 3
bys iso3: egen opm = max(pmatch)
*drop if eu == 1


replace year_gl = 0 if year_gl == .
replace year_bl = 0 if year_bl == . 

replace selected = 0 if selected == . 
*gen lnfsi = ln(FSIValue)
replace reviewed = 0 if reviewed == .

gen year_rv = 2017 if reviewed == 1
replace year_rv = 0 if reviewed == 0 


*drop if eu == 1

*keep if selected == 1


* Effects of EATR by industry 

*foreach letter in A B C D E F G H I J K L M N O P Q R S {
*	csdid EATR_cit`letter' selected eu, ivar(c) time(year) gvar(year_bl) method(dripw)   saverif(_rif_) replace notyet
*	preserve
*			use _rif_, clear
*			csdid_stats simple, estore(ea_bl_`letter') wboot
*	restore 
	
*}


* 2026-09-13 (coherence review fix) (H4): haven split on the union of the three lists (rr_A2_haven_lists.dta, built by F06 which runs first), as every other DiD split; was the Johannesen-Zucman list alone
mmerge iso3 using "$output\rr_A2_haven_lists.dta", type(n:1) unmatched(master) ukeep(union)
gen haven = union == 1


keep if year >=2010

global ifgl = "if selected == 1"
global ifbl = "if selected == 1"
global ifrv = "if eu == 0"


foreach var of varlist  SCITR_ct EATR_ct EMTR_ct {
	foreach tr in gl bl rv {
		csdid `var' ${if`tr'}, ivar(c) time(year) gvar(year_`tr') method(dripw)   saverif(_rif_) replace notyet
		est sto d_`var'_`tr'
				
		csdid `var'  ${if`tr'}, ivar(c) time(year) gvar(year_`tr') method(dripw)  agg(simple) notyet
		local r_`var'_`tr' = round(_b[ATT],.0001)
				
		* Overall ATT and group ATTs
		preserve
			use _rif_, clear
			* 2026-10-28: no reseed here; the wild bootstrap draws continue the stream set by
			* -set rngstate- at the top of this file, as in the run that made the published figure.
			csdid_stats simple, estore(s_`var'_`tr') wboot
			csdid_stats group , estore(g_`var'_`tr') wboot

			* Overall event 
			csdid_stats event, window(-6 3) wboot estore(e_`var'_`tr')
		restore
	}
}


coefplot (e_SCITR_ct_gl, recast(connected) mcolor("118 118 118") lcolor("118 118 118") ciopts(recast(rcap) lcolor("118 118 118")))	///
		 (e_SCITR_ct_bl, recast(connected) mcolor(black)		 lcolor(black) 		   ciopts(recast(rcap) lcolor(black)))			///
		 (e_SCITR_ct_rv, recast(connected) mcolor("212 17 89") 	 lcolor("212 17 89")   ciopts(recast(rcap) lcolor("212 17 89")))	///
			, vertical  ///
		      keep(T*) /// 
			  xline(6.5, lcolor(black) lpattern(dash)) 						        ///
			  xtitle("Years until first listing/review")				    ///
			  ytitle("Statutory CTR")					///
			  yline(0, lcolor(black) lpattern(solid))								///
			  scheme(Modern)													///
			  ci(95) 	///
			   xlabel(1  "-6" 2  "-5" 3  "-4" 4  "-3" 5  "-2" 6  "-1" 			///
						7  "0" 8 "1" 9 "2" 10 "3" 11 "4") ///
						xsize(8) ysize(8)			 legend(on order(2 "Greylisted" 4 "Blacklisted " 6 "Reviewed") ///
								 position(6) rows(1)) scale(1.3) name(ctr, replace)  ylabel(-.04(0.02)0.06) ///
				ttext(0.045 3 "ATT:  `r_SCITR_ct_gl' ", color("118 118 118") size(vsmall))  ///
				ttext(0.041 3 "ATT:  `r_SCITR_ct_bl' ", color(black) size(vsmall)) ///
				ttext(0.037 3 "ATT:  `r_SCITR_ct_rv' ", color("212 17 89") size(vsmall)) 
				
				
graph export "$ographs\listing_ctr.png", replace width(2000)


coefplot (e_EATR_ct_gl, recast(connected) mcolor("118 118 118") lcolor("118 118 118") ciopts(recast(rcap) lcolor("118 118 118")))	///
		 (e_EATR_ct_bl, recast(connected) mcolor(black)		 lcolor(black) 		   ciopts(recast(rcap) lcolor(black)))			///
		 (e_EATR_ct_rv, recast(connected) mcolor("212 17 89") 	 lcolor("212 17 89")   ciopts(recast(rcap) lcolor("212 17 89")))	///
			, vertical  ///
		      keep(T*) /// 
			  xline(6.5, lcolor(black) lpattern(dash)) 						        ///
			  xtitle("Years until first listing/review")				    ///
			  ytitle("Effective Average CTR")					///
			  yline(0, lcolor(black) lpattern(solid))								///
			  scheme(Modern)													///
			  ci(95) 	///
			   xlabel(1  "-6" 2  "-5" 3  "-4" 4  "-3" 5  "-2" 6  "-1" 			///
						7  "0" 8 "1" 9 "2" 10 "3" 11 "4") ///
						xsize(8) ysize(8)			 legend(on order(2 "Greylisted" 4 "Blacklisted " 6 "Reviewed") ///
								 position(6) rows(1)) scale(1.3) name(eatr, replace)   ylabel(-.04(0.02)0.06) ///
								 	ttext(0.045 3 "ATT:  `r_EATR_ct_gl' ", color("118 118 118") size(vsmall))  ///
				ttext(0.041 3 "ATT:  `r_EATR_ct_bl' ", color(black) size(vsmall)) ///
				ttext(0.037 3 "ATT:  `r_EATR_ct_rv' ", color("212 17 89") size(vsmall)) 
graph export "$ographs\listing_eatr.png", replace width(2000)		


global c1 = "if selected == 1"
global c2 = "if eu == 0"
global c3 = "if haven == 0 & selected == 1"
global c4 = "if haven == 1 & selected == 1"

forvalues i =  1/4 {
	
	
	foreach var of varlist SCITR_ct EATR_ct {
		foreach tr in gl bl {
			csdid `var'  ${c`i'}, ivar(c) time(year) gvar(year_`tr') method(dripw)   saverif(_rif_) replace notyet
			est sto d_`var'_`tr'_`i'
					
			* Overall ATT and group ATTs
			preserve
				use _rif_, clear
				set seed 20260825                      // 2026-09-16: reproducible wild bootstrap (not a paper exhibit)
				csdid_stats simple, estore(s_`var'_`tr'_`i') wboot
				csdid_stats group , estore(g_`var'_`tr'_`i') wboot

				* Overall event 
				csdid_stats event, window(-6 3) wboot estore(e_`var'_`tr'_`i')
			restore
		}
	}
	
}


coefplot s_SCITR_ct_gl_3 s_SCITR_ct_gl_4 ||  s_EATR_ct_gl_3 s_EATR_ct_gl_4  , vertical 


coefplot (e_EMTR_ct_gl, recast(connected) mcolor("118 118 118") lcolor("118 118 118") ciopts(recast(rcap) lcolor("118 118 118")))	///
		 (e_EMTR_ct_bl, recast(connected) mcolor(black)		 lcolor(black) 		   ciopts(recast(rcap) lcolor(black)))			///
		 (e_EMTR_ct_rv, recast(connected) mcolor("212 17 89") 	 lcolor("212 17 89")   ciopts(recast(rcap) lcolor("212 17 89")))	///
			, vertical  ///
		      keep(T*) /// 
			  xline(6.5, lcolor(black) lpattern(dash)) 						        ///
			  xtitle("Years until first listing/review")				    ///
			  ytitle("Statutory CTR")					///
			  yline(0, lcolor(black) lpattern(solid))								///
			  scheme(Modern)													///
			  ci(95) 	///
			   xlabel(1  "-6" 2  "-5" 3  "-4" 4  "-3" 5  "-2" 6  "-1" 			///
						7  "0" 8 "1" 9 "2" 10 "3" 11 "4") ///
						xsize(8) ysize(8)			 legend(on order(2 "Greylisted" 4 "Blacklisted " 6 "Reviewed") ///
								 position(6) rows(1)) scale(1.3) name(emtr, replace) subtitle(Statutory tax rates)
		
