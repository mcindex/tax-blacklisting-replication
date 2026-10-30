********************************************************************************
* master_rr.do
*
* Replication package for Matt Collin, "The impact of tax blacklisting",
* International Tax and Public Finance (accepted 2026).
*
* HOW TO RUN
*   Open Stata in this folder and type   do master_rr.do
*   or in batch mode:                    StataMP-64 -e do master_rr.do
*   Every script is called from this file in the order in which its exhibit
*   appears in the paper.  Script names point at the exhibit they produce:
*       D..   data construction (Part 1; see run_data below)
*       T.. / F..  main-text tables and figures
*       A_..  online-appendix exhibits (named by their LaTeX label)
*       P_..  further online-appendix exhibits added during the revision
*   README.md maps every table and figure of the published paper to its
*   script and output file.
*
* PARTS AND TOGGLES (section 2 below)
*   run_data     Part 1 rebuilds the intermediate data from the raw inputs in
*                input/.  Default 0: the analysis starts from the checkpoint
*                files shipped in output/.  Part 1 also needs the Tax Justice
*                Network files listed in README.md (not redistributed).
*   wb_refresh   1 = pull the World Bank series live (wbopendata) instead of
*                the frozen copies in output/ (results then depend on the
*                Bank's current vintage).  Default 0.
*   fdi_accepted_sample  1 = drop North Macedonia and State of Palestine from
*                the FDI panel, reproducing the published FDI exhibits exactly
*                (see README.md).  Default 0.
*   run_main     Part 2: main-text exhibits                (default 1)
*   run_appendix Part 3: online-appendix exhibits          (default 1)
*   run_pending  Part 4: further online-appendix exhibits  (default 1)
*
* DATA NOT INCLUDED
*   The corporate tax rate files of the RSIT ITI database (International Tax
*   Institutions; input/ITI_CITR_ct_R2.dta and input/ITI_CITR_cit_R2.dta) are
*   free for research on request from the RSIT (see README.md).
*   Without them the six scripts that read them are skipped (see section 3).
*
* OUTPUT LOCATIONS
*   exhibits/graphs, exhibits/tables  the exhibits under the names the paper
*                                     uses (shipped as the package produces
*                                     them; a run overwrites them, so
*                                     git status exhibits/ shows any change)
*   graphs/ tables/                   working copies
*   output/                           checkpoint and intermediate data
*
* REQUIRED PACKAGES (ssc unless noted)
*   rdrobust, rddensity, lpdensity (rdpackages.github.io); csdid, drdid;
*   reghdfe, ftools; did2s; did_multiplegt_dyn; coefplot; estout; boottest;
*   ivreg2; erepost; binscatter; listtab; mmerge; egenmore;
*   wbopendata (only with wb_refresh 1); carryforward.
*   Font "LM Roman 10" installed for the graphs.
*   Shipped in ado/ (no install needed): graph scheme "modern" (ado/s/), kountry
*   with the package's country-name list (ado/k/), dropmiss 2.5 (ado/d/, Stata
*   Journal dm89_1; used by D08).
********************************************************************************

clear all
set more off
set maxvar 10000

*-------------------------------------------------------------------------------
* 1. Directories (run from the package folder)
*-------------------------------------------------------------------------------
global root     "`c(pwd)'"
global input    "$root\input"
global project  "$root"
global do       "$root\do"
global python   "$root\python"
global output   "$root\output"
global graphs   "$root\graphs"
global tables   "$root\tables"
global overleaf "$root\exhibits"
global ographs  "$overleaf\graphs"
global otables  "$overleaf\tables"

adopath ++ "$root\ado"
cd "$root"

cap graph set window fontface "LM Roman 10"

*-------------------------------------------------------------------------------
* 2. Toggles
*-------------------------------------------------------------------------------
global run_data     0
global wb_refresh   0   // 2026-09-15: 1 = replace the frozen World Bank GDP-per-capita vintage with a fresh pull
                        //   (needs run_data 1: D05 pulls the series, D06 freezes it, D07 re-applies the PRI fix)
                        //   2026-10-30: 1 also makes D05 and F10 pull their World Bank series live instead of
                        //   reading the frozen copies in output/wb_frozen_*.dta
global fdi_accepted_sample 0   // 2026-10-29: 1 = drop North Macedonia and State of Palestine from the UNCTAD
                                //   FDI panel (T05), reproducing the FDI exhibits of the accepted paper exactly;
                                //   0 = corrected sample including both (see README, Verification)
global run_main     1
global run_appendix 1
global run_pending  1

* globals read by F06_T04_governance_did.do (leave empty for the full run)
global A2_redraw   ""
global A2_drop_ldc ""
global A2_sfx      ""

*-------------------------------------------------------------------------------
* 3. Package check and country-name fixes
*-------------------------------------------------------------------------------
foreach p in rdrobust rddensity lpdensity csdid drdid reghdfe ftools did2s ///
             did_multiplegt_dyn coefplot esttab boottest ivreg2 erepost   ///
             binscatter listtab mmerge kountry wbopendata carryforward dropmiss {
    cap which `p'
    if _rc di as error "Package `p' not found -- install before running"
}
* 2026-10-28: kountry (SSC) and dropmiss 2.5 (SJ8-4 dm89_1; D08 needs its obs option) ship in ado/ and are found
* first via the adopath above. ado/k/k_other_extras.ado is a fixed list of the 59 non-standard country names the
* package needs. It replaces do/kountry_fixes.do, whose -kountryadd ... add- appended to the user's own
* PLUS/k/k_other_extras files on every run until kountry hit Stata's size limit and silently ignored them.
* Never run -kountryadd- with this package: it would write to the user's PLUS folder, not to ado/.

* 2026-10-30: the corporate tax rate files of the RSIT ITI database (International Tax Institutions;
* ITI_CITR_ct_R2.dta, ITI_CITR_cit_R2.dta) are not redistributed with the package; they are free for
* research on request from the RSIT (see README, Data).
* Without them in input/, the six scripts that read them are skipped and everything else still runs.
global have_iti 1
foreach f in ITI_CITR_ct_R2 ITI_CITR_cit_R2 {
    cap confirm file "$input/`f'.dta"
    if _rc {
        global have_iti 0
        di as error "input/`f'.dta not found: skipping F07, T05b, F10, P_fig7_oecd_robustness,"
        di as error "  P_fig_ctr_gl_cohorts and P_tab_data_section (see README, Data, for how to obtain it)"
    }
}

di as res _n "master_rr.do started " c(current_date) " " c(current_time)

*-------------------------------------------------------------------------------
* PART 1. DATA CONSTRUCTION (provenance; run_data = 1 to rebuild)
*-------------------------------------------------------------------------------
if $run_data {
    do "$do/D01_if_membership.do"             // IF membership timeline
    do "$do/D02_map_mli_maa.do"               // MAP profiles, MLI, MAA
    do "$do/D03_eu_lists_F03.do"              // EU scoreboard + list panel to 2022; Figure 3
    do "$do/D04_harmful_regimes_2021.do"      // harm.dta (2021 vintage, read by D05)
    do "$do/D05_rd_sample.do"                 // RD sample [World Bank series frozen; live with wb_refresh 1]
    do "$do/A_tab_global_poly.do"             // l.130 writes regready_042822.dta (rest = appendix table)
    do "$do/D06_regready_frozen_gdp.do"       // freezes the World Bank GDP-pc vintage -> regready_042822_gdp2026_frozen20260820.dta (overwrites only if wb_refresh = 1)
    do "$do/D07_regready_prifix.do"           // Puerto Rico running variable -> missing
    do "$do/D08_harmful_regimes_2022.do"      // harm_043022.dta, oecd_review_043022.dta
    do "$do/D09_eu_lists_2026.do"             // list panel to Feb 2026
    do "$do/D10_bis_deposits.do"              // BIS deposits quarterly panel
    * python: python/aeoi_ratings_091526.py (OECD AEOI ratings -> output/aeoi_ontrack_091526.dta; 2026-09-15)
    * python: python/econ_data_extract_2026.py (BIS/UNCTAD 2026 extracts),
    *         python/map_wayback_scrape.py + map_wayback_to_iso3.py (MAP profile dates)
}

*-------------------------------------------------------------------------------
* PART 2. MAIN TEXT
*-------------------------------------------------------------------------------
* 2026-09-15 (author): AEOI "On Track" rating added as tax transparency outcome (v); builds the RD analysis file
* regready_042822_gdp2026_frozen20260820_aeoi091526.dta read by T03 F04 F05 A_tab_wild_bootstrap P_fig_coefplot_boot
* A_tab_global_poly A_fig_donuts P_tab_data_section (input output/aeoi_ontrack_091526.dta from python/aeoi_ratings_091526.py)
do "$do/D11_aeoi_ontrack.do"

if $run_main {
    do "$do/T01_worked_example.do"            // Table 1  (t:example)
    do "$do/F02_selection_bars.do"            // Figure 2 (fig:selection)
    do "$do/F03_list_evolution.do"           // Figure 3 (glbl), lists to Feb 2026 (reads D09's EU_BL_full_list_2026.dta)
    do "$do/A_fig_deficiency_letters.do"      // builds cocg_letters_091026.dta for T03 (+ appendix f:deficiency figures)
    do "$do/F04_first_stage_rd_plots.do"      // Figure 4 (f:fsg) [fuzzy: *_fuzzy_euc_091226.png]
    do "$do/T03_main_rd.do"                   // Table 3 (t:main_rd, appendix) [fuzzy: rr_table3_fuzzy_091226.tex] + rr_rvcompare_fuzzy
    do "$do/F05_main_rd_coefplot.do"          // Figure 5 (fig:main_rd) [rr_t3_coefplot_fuzzy_091226.pdf]
    do "$do/F06_T04_governance_did.do"        // Figure 6 (fig:did_gov) + Table 4 (rr_A2_govdid_table)  ~10 min
    if $have_iti do "$do/F07_tax_rates.do"    // Figure 7 (fig:ctr) [needs ITI]
    do "$do/F08_shifted_profits.do"           // Figure 8 (f:zucmanblack)
    do "$do/T05_econ_did_2026.do"             // Table 5 estimates (t:didextended, written by T05b) + f:event_economic  ~12 min
    if $have_iti do "$do/T05b_taxrate_econ_did_table.do"   // 2026-09-14: tax-rate DiDs + combined main-text table t:didextended (after F07, T05) [needs ITI]
    do "$do/F09_T06_harmful_regimes.do"       // Figure 9 (f:rev) + Table 6 (t:rev) [fuzzy: *_fuzzy_euc_091226]
    if $have_iti do "$do/F10_targeting.do"    // Figure 10 (f:targeting) [needs ITI; World Bank GNI frozen; live with wb_refresh 1]
}

*-------------------------------------------------------------------------------
* PART 3. ONLINE APPENDIX
*-------------------------------------------------------------------------------
if $run_appendix {
    do "$do/A_tab_first_stage.do"             // rd_fs_091326.tex (first stage on actual review)
    * 2026-09-15 (author): Manhattan-distance version of Table A6 (cols 1-3) and its coefficient plot (referee 1, comment 2a)
    global T3_rv "manhattan"
    do "$do/T03_main_rd.do"                   // rr_table3_fuzzy_manhattan_091526.tex
    do "$do/F05_main_rd_coefplot.do"          // rr_t3_coefplot_fuzzy_manhattan_091526.pdf
    global T3_rv ""
    do "$do/A_density_balance.do"             // f:density (_091326); balance tables / RD balance plots disabled
    do "$do/A_tab_wild_bootstrap.do"          // t:main_rd_iv_bs (rd_regs_bot_091426.tex since 2026-09-14: coef + [95% CI] side by side, boottest CI, seeded; 2SLS + WRE bootstrap)
    do "$do/A_fig_placebo.do"                 // f:placebo (_091326)
    do "$do/A_tab_global_poly.do"             // t:rob (rd_robu_091326.tex; 2SLS global polynomials)
    * f:cbcr_did (cbcr222.do) dropped from the appendix 2026-09-12 (covered by Figure 6)
    do "$do/A_fig_effort_havens_hrm.do"       // f:risky, f:haventest, f:effort
    * f:iftime (A_fig_if_over_time.do, A_fig_if_before_after.do) dropped from the appendix 2026-09-12 (IF result rests on the DiD); scripts not included in this package
    do "$do/A_tab_country_list.do"            // t:list (countrylist_091326.tex)
    do "$do/A_fig_donuts.do"                  // f:donuts (two figures, _091326, fuzzy)
    * 2026-09-13 (coherence review fix): appendix variant of Table 4 / Figure 6 with LDCs dropped (t:govdid_noldc_prov, f:govdid_noldc_prov)  ~10 min
    global A2_drop_ldc "1"
    global A2_sfx      "_noldc"
    do "$do/F06_T04_governance_did.do"        // rr_A2_govdid_table_noldc_091126.tex, rr_A2_es_main_4panel_noldc_091126.pdf
    global A2_drop_ldc ""
    global A2_sfx      ""
}

*-------------------------------------------------------------------------------
* PART 4. FURTHER ONLINE-APPENDIX EXHIBITS (P_ scripts, added during the revision)
*-------------------------------------------------------------------------------
if $run_pending {
    do "$do/P_tab_balance_eligible.do"        // balance on the fuzzy-design sample (rr_balance_elig_*_091326)
    * P_tab_twfe_compare.do (TWFE vs csdid, review design) dropped 2026-09-15: not in the draft or the appendix; the script is not included in this package
    do "$do/P_tab_govdid_neverrev.do"        // listing DiDs with never-reviewed controls (reads F06 results)
    do "$do/P_fig_coefplot_boot.do"           // wild-bootstrap coefficient plot (_091326; reads A_tab_wild_bootstrap)
    if $have_iti do "$do/P_fig7_oecd_robustness.do"   // Figure 7 with OECD CTS [needs ITI]
    if $have_iti do "$do/P_fig_ctr_gl_cohorts.do"     // 2026-09-15: f:ctr_cohorts, greylisting effect on tax rates by cohort (group ATTs) [needs ITI]
    if $have_iti do "$do/P_tab_data_section.do"       // data-section descriptives [needs ITI]
}

* PART 5 (legacy economic-outcome chain) removed 2026-09-12 -- see the header note.

di as res _n "master_rr.do finished " c(current_date) " " c(current_time)
