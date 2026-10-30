* F02_selection_bars.do  |  FIGURE 2 (fig:selection) stacked bars of the listing process
* Copied unchanged from do/rr_table1_bar_082726.do on 2026-09-12 for the R&R replication package
* (replication_rr/). Edit THIS copy from now on; the original stays in do/ for the project pipeline.
********************************************************************************
********************************************************************************
* rr_table1_bar_082726.do
*
* Stacked-bar version of paper Table 1 ("Number of jurisdictions reviewed and
* listed by the EU, 2016-2022", label t:juris in itax_rr_1.tex).
*
* One bar per Table-1 column (the five stages of the EU process:
* ranked -> selected -> deficiencies -> greylisted -> blacklisted), stacked by
* jurisdiction category. EU Member States are DROPPED (their row is all zeros,
* so no column total changes). Remaining categories, bottom to top:
*   1. Other non-EU jurisdictions            (blue,   #0072B2 / 0 114 178)
*   2. Jurisdictions w/ EU transparency agmt (green,  #009E73 / 0 158 115)
*   3. Least Developed Countries             (orange, #E69F00 / 230 159 0)
* LDCs sit on top so the single persisting LDC (Vanuatu, reviewed despite the
* LDC exemption because it was expected to graduate) reads as a thin cap on
* every post-ranking bar; explained in the paper's table/figure note, not
* annotated on the graph itself.
* Palette is Okabe-Ito, colourblind-safe (validated: worst adjacent-pair CVD
* dE 11.4, all checks pass).
*
* Source of numbers: Table 1 is hardcoded in the tex, so values are input
* directly here (no upstream dataset).
*
* Produces: graphs/rr_table1_stackedbar_082726.png (+ .pdf)
********************************************************************************

* Standalone guard: define paths if master.do section 1 has not been run
if "$project" == "" {
    global project "`c(pwd)'"                 // 2026-10-28: standalone use = run from the package folder
    global graphs  "$project\graphs"
    global do      "$project\do"
}
graph set window fontface "LM Roman 10"

clear

* cat: 1 = Other non-EU (160), 2 = EU transparency agreement (5), 3 = LDC (48)
input stage cat n
1 1 141
1 2   5
1 3  48
2 1  86
2 2   5
2 3   1
3 1  68
3 2   3
3 3   1
4 1  67
4 2   4
4 3   1
5 1  29
5 2   0
5 3   1
end

* Stack bounds and totals
bysort stage (cat): gen y1  = sum(n)
gen y0  = y1 - n
gen mid = (y0 + y1)/2
bysort stage (cat): egen tot  = total(n)
bysort stage (cat): gen  last = _n == _N          // one row per stage, at stack top
gen ytop = tot

drop if n == 0                                     // zero-height segments draw stray lines

* In-bar labels: blue segments (all large) in white; the one large orange segment (48)
gen inlab_w = cat == 1
gen inlab_d = cat == 3 & n >= 20

#delimit ;
twoway
    (rbar y0 y1 stage if cat == 1, barwidth(.66) color("0 114 178")
        lcolor(white) lwidth(vthin))
    (rbar y0 y1 stage if cat == 2, barwidth(.66) color("0 158 115")
        lcolor(white) lwidth(vthin))
    (rbar y0 y1 stage if cat == 3, barwidth(.66) color("230 159 0")
        lwidth(none))
    (scatter mid stage if inlab_w, msymbol(none) mlabel(n) mlabpos(0)
        mlabcolor(white) mlabsize(small))
    (scatter mid stage if inlab_d, msymbol(none) mlabel(n) mlabpos(0)
        mlabcolor(gs3) mlabsize(small))
    (scatter ytop stage if last,   msymbol(none) mlabel(tot) mlabpos(12)
        mlabcolor(gs3) mlabsize(small) mlabgap(1.2))
    ,
    ylabel(0(50)200, angle(0) labsize(small) labcolor(gs4)
        glcolor(gs15) glwidth(vthin) glpattern(solid) tlcolor(gs10))
    yscale(range(0 212) lcolor(gs10))
    ytitle("Number of jurisdictions", size(small) color(gs4))
    xlabel(1 `" "Ranked in" "scoreboard" "'
           2 `" "Selected for review" "by Code of" "Conduct Group" "'
           3 `" "Deficiencies raised" "by Code of" "Conduct Group"'
           4 `" "Ever" "greylisted" "by 2022"  "'
           5 `" "Ever" "blacklisted" "by 2022" "'
           , labsize(small) labcolor(gs4) noticks nogrid labgap(2))
    xscale(range(0.5 5.5) lcolor(gs10))
    xtitle("")
    legend(order(3 "Least Developed Countries"
                 2 "EU transparency-agreement jurisdictions"
                 1 "Other non-EU jurisdictions")
           cols(3) size(small) color(gs4) region(lcolor(none))
           symxsize(3) keygap(1) colgap(4) position(6) bmargin(t=2))
    graphregion(color(white) margin(t=4))
    plotregion(margin(t=2))
    xsize(7.5) ysize(4.5)
    ;
#delimit cr

graph export "$graphs/rr_table1_stackedbar_082726.png", replace width(2200)
graph export "$graphs/rr_table1_stackedbar_082726.pdf", replace
if "$ographs" != "" graph export "$ographs/rr_table1_stackedbar_082726.pdf", replace   // Overleaf (2026-09-12)

di "rr_table1_bar_082726.do completed"
