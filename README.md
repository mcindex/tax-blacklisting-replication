# Replication package: "The impact of tax blacklisting"

Matt Collin, *International Tax and Public Finance* (accepted 2026).

This package reproduces every table and figure of the published paper and its online appendix from
Stata code. All but four exhibits are produced by scripts; the four hand-made ones are in `static/`.

## Quick start

1. Install Stata 18 (tested with Stata/MP 18 on Windows 11) and the packages listed under **Software**.
2. Request the RSIT ITI database (International Tax Institutions) and put `ITI_CITR_ct_R2.dta` and `ITI_CITR_cit_R2.dta`
   in `input/` (see **Data availability**). Without them the package still runs and skips the exhibits
   that need them.
3. Open Stata in this folder and run `do master_rr.do`, or in batch mode `StataMP-64 -e do master_rr.do`.

A full run takes about an hour. `exhibits/` ships with the exhibits the package produced; a run
overwrites them, so `git status exhibits/` shows at once whether anything changed (in our tests, nothing
did). They match the published files except as listed under **Known differences**. Files in `output/`
also show as modified after a run, because Stata stores the save time in `.dta` and `.ster` files; their
contents are unchanged.

## What the run does

`master_rr.do` sets the paths, checks the required packages and calls every script in the order its
exhibit appears in the paper. Toggles in its section 2:

| Toggle | Default | Effect |
|---|---|---|
| `run_data` | 0 | 1 = Part 1: rebuild the intermediate data in `output/` from the raw files in `input/`. Needs the Tax Justice Network files (not redistributed). With 0 the analysis starts from the checkpoint files shipped in `output/` |
| `wb_refresh` | 0 | 1 = pull the World Bank series live instead of the frozen copies in `output/wb_frozen_*.dta` and `output/regready_042822_gdp2026_frozen20260820.dta`; results then depend on the Bank's current vintage |
| `fdi_accepted_sample` | 0 | 1 = drop North Macedonia and State of Palestine from the FDI panel, which reproduces the published FDI exhibits exactly (see **Known differences**) |
| `run_main`, `run_appendix`, `run_pending` | 1 | Parts 2-4: main-text exhibits, online-appendix exhibits, further online-appendix exhibits |

## Folders

| Folder | Contents |
|---|---|
| `do/` | Stata scripts. `D..` data construction (Part 1), `T..`/`F..` main-text tables and figures, `A_..` online-appendix exhibits, `P_..` further online-appendix exhibits; `*.grec` graph-editor recordings used by the scripts |
| `python/` | optional pre-processing (not called by `master_rr.do`; their outputs ship in `output/`): BIS 2026 and UNCTAD extracts, OECD AEOI ratings, MAP-profile dates from archived OECD PDFs |
| `ado/` | packages shipped with the code and found first on the adopath: graph scheme `modern`; `kountry` with the package's list of 59 non-standard country names; `dropmiss` 2.5 |
| `input/` | raw data that may be redistributed (see **Data availability**) |
| `output/` | checkpoint and intermediate data; the default run starts here |
| `exhibits/graphs`, `exhibits/tables` | the code-generated exhibits as the package produces them, under the file names the paper uses |
| `static/` | the four hand-made exhibits |
| `graphs/`, `tables/` | working copies written during a run |

## Software

Stata 18 with these packages (SSC unless noted): `rdrobust`, `rddensity`, `lpdensity`
(rdpackages.github.io), `csdid`, `drdid`, `reghdfe`, `ftools`, `did2s`, `did_multiplegt_dyn`,
`coefplot`, `estout`, `boottest`, `ivreg2`, `erepost`, `binscatter`, `listtab`, `mmerge`, `egenmore`,
`carryforward`, and `wbopendata` (only with `wb_refresh 1`). The master lists any that are missing.
The graphs use the font "LM Roman 10" (Latin Modern), which must be installed.

The optional Python scripts need Python 3 with `pandas`, `pycountry` and `requests`.

## Data availability

### Not included

| Data | Used by | How to obtain |
|---|---|---|
| ITI database (International Tax Institutions) of the Tübingen Research School of International Taxation (RSIT), corporate tax rates (`ITI_CITR_ct_R2.dta`, `ITI_CITR_cit_R2.dta`) | Figure 7(a)-(b), Figure 9, Tables 3 and 5, Figures A11 and A12 (scripts `F07`, `F10`, `T05b`, `P_tab_data_section`, `P_fig7_oecd_robustness`, `P_fig_ctr_gl_cohorts`) | Free for research on request from the RSIT: see https://www.rsit-uni-tuebingen.de/data/ or email rsit@wiwi.uni-tuebingen.de with your name, affiliation, co-authors, a one-paragraph summary of the research and the datasets requested. Cite Wamser et al. (2025), "The ITI database: new data on international tax institutions", *International Tax and Public Finance*. Place both files in `input/` |
| Tax Justice Network: Financial Secrecy Index 2018 and 2020 (`FSI-Rankings-2018.xlsx`, `fsi.xlsx`, `fsi_2020.xlsx`), Corporate Tax Haven Index 2019 (`CTHI2019.xlsx`) | Part 1 only (`D05_rd_sample.do`); the variables built from them ship in `output/` | Download from the Tax Justice Network (fsi.taxjustice.net, cthi.taxjustice.net) and place in `input/` under these names |
| BIS Locational Banking Statistics, full files: 2022 vintage `WS_LBS_D_PUB_csv_col.csv` (530 MB) and 2026 vintage `WS_LBS_D_PUB_csv_col.zip` (122 MB) | Part 1 (`D10_bis_deposits.do`) and `python/econ_data_extract_2026.py` | Too large for GitHub. The package ships the extracts the code reads: `output/bis_lbs_2022_filtered.dta` (made by `do/bis_2022_extract.do`) and `output/bis_lbs_2026_filtered.csv` (made by `python/econ_data_extract_2026.py`). The current vintage is at data.bis.org; past vintages are not archived there, so a fresh download will differ |

### Frozen downloads

The World Bank series the code used to pull live are saved in `output/`: the four 2010-2018 series read
by `D05_rd_sample.do` (poverty headcount, GDP per capita in PPP and current US$, FDI net inflows as % of
GDP) as pulled in March 2022, in `wb_frozen_d05_*_032522.dta`; GNI per capita and GNI (PPP) for 2016
read by `F10_targeting.do`, pulled on 30 October 2026, in `wb_frozen_f10_gnp2016_103026.dta`; and the GDP
per capita vintage of 20 August 2026 used in the RD analysis file. `do/freeze_wb_vintages.do` documents
how the first two were made. The OECD AEOI ratings (`output/aeoi_ratings_datawrapper_ZAIre71_091526.csv`)
and the archived MAP-profile PDFs (`input/map_wayback_profiles/`) are saved copies too.

### Included in `input/`

| Source | Files |
|---|---|
| EU Code of Conduct Group: 2015 pan-EU list, 2016 scoreboard, list of reviewed jurisdictions, EU lists of non-cooperative jurisdictions and their revisions (Council conclusions to February 2026), Council reports on preferential regimes (2018, 2021), commitment letters | `EU_2015_blacklist.xlsx`, `eu_scoreboard_final.csv`, `reviewed_list.xlsx`, `EU_BLGL_050322.xlsx`, `EU_BLGL_090926.xlsx`, `updated_bl/` (Council documents), `ST_9639_2018_REV_4_EN_2.xlsx`, `ST-7915-2021-INIT.xlsx`, `committment_data.xlsx`, `eu_states.xlsx` |
| OECD: Inclusive Framework membership, MAP profiles, MLI signatories, Multilateral Convention (MAA) status, Global Forum EOIR ratings, Corporate Tax Statistics, list of OECD members | `IF_membership_timeline_052919.xlsx`, `if_membership_timeline_103119.xlsx`, `members_if_jan_19.xlsx`, `map_profiles_062419.xlsx`, `map_wayback_profiles/`, `mli_signatories_062419.xlsx`, `Status_of_convention_11182019.xlsx`, `eoir.xlsx`, `CTS_CIT_20052020215449889.csv`, `oecd_cts_cit_091126.csv`, `oecd_cts_etr_baseline_091126.csv`, `oecd.xlsx` |
| IMF Balance of Payments, direct investment | `IMF_BOP_DI_NET_Q.xlsx` |
| Eurostat, foreign affiliates statistics | `eurostat/fats_out2_r2.tsv` |
| UNCTAD, FDI flows and stocks (7z archive despite the extension) | `US_FdiFlowsStock_updated.csv` |
| Tørsløv, Wier and Zucman, missing profits | `Profit shifting - Nov 2024.xlsx`, `zm_updated.xlsx` |
| Tax-haven lists: Johannesen and Zucman (2014); Garcia-Bernardo et al. (2017) sink and conduit OFCs | `zucman_haven.dta`, `zucman_havens.csv`, `sink_ofcs.xlsx` |

Each source remains subject to its provider's terms of use; please cite the original sources as in the
paper.

## Exhibits

Numbers as in the published paper. Files are in `exhibits/` unless marked *static*; [ITI] marks
exhibits that need the RSIT data.

### Main text

| Exhibit | Script | File(s) |
|---|---|---|
| Figure 1 | hand-made TikZ | *static* `rr_timeline_tikz_091226.tex` |
| Figure 2 | `F02_selection_bars.do` | `rr_table1_stackedbar_082726.pdf` |
| Figure 3 | `F03_list_evolution.do` | `time_blgl_2026_091226.png` (and `.pdf`) |
| Table 1 | `T01_worked_example.do` | `rr_B4_worked_example.tex` |
| Table 2 | written in the paper | |
| Figure 4 | `F04_first_stage_rd_plots.do` | `fs_{1,2,3}_fuzzy_euc_091226.png`, `{tax_transparency,fair_taxation,anti_beps}_now_fuzzy_euc_091226.png` |
| Figure 5 | `F05_main_rd_coefplot.do` (reads the estimates of `T03_main_rd.do`) | `rr_t3_coefplot_fuzzy_091226.pdf` |
| Table 3 [ITI] | `P_tab_data_section.do` | `rr_B11_econ_descstats_091226.tex` |
| Table 4 | `F06_T04_governance_did.do` | `rr_A2_govdid_table_091126.tex` |
| Figure 6 | `F06_T04_governance_did.do` | `rr_A2_es_top3_4panel_091126.pdf` |
| Figure 7 | `F07_tax_rates.do` (a, b) [ITI]; `T05_econ_did_2026.do` (c, d) | `listing_ctr.png`, `listing_eatr.png`, `listing_deposits_091226.png`, `listing_fdistock_091226.png` |
| Figure 8 | `F08_shifted_profits.do` | `haven_profits_090925.png` |
| Table 5 [ITI] | `T05b_taxrate_econ_did_table.do` (reads the estimates of `F07` and `T05_econ_did_2026.do`) | `rr_did_taxecon_2026_091426.tex` |
| Table 6 | `F09_T06_harmful_regimes.do` | `rr_nharmful_fuzzy_euc_091226.tex` |
| Figure 9 [ITI] | `F10_targeting.do` | `t{1,2,3,4}_091026.png` |

### Online appendix

| Exhibit | Script | File(s) |
|---|---|---|
| Figure A1 | hand-made | *static* `3dcountryplot2.png` |
| Table A1 | hand-made | *static* `rr_eu_crit_outcomes_091526.tex` |
| Tables A2-A3 | `P_tab_balance_eligible.do` | `rr_balance_elig_{distance,z_frontier}_091326.tex` |
| Table A4 | `A_tab_country_list.do` | `countrylist_091326.tex` |
| Figure A2 | `A_density_balance.do` | `{histogram,densitytest}_{distance_e,z_frontier}_091326.png` |
| Table A5 | `A_tab_first_stage.do` | `rd_fs_091326.tex` |
| Table A6 | `T03_main_rd.do` | `rr_table3_fuzzy_091226.tex` |
| Table A7, Figure A3 | `T03_main_rd.do`, `F05_main_rd_coefplot.do` (Manhattan distance; set by the master) | `rr_table3_fuzzy_manhattan_091526.tex`, `rr_t3_coefplot_fuzzy_manhattan_091526.pdf` |
| Table A8 | `A_tab_wild_bootstrap.do` | `rd_regs_bot_091426.tex` |
| Figure A4 | `P_fig_coefplot_boot.do` | `rr_t3_coefplot_boot_091326.pdf` |
| Figure A5 | `A_fig_placebo.do` | `placebo_{distance,z_frontier}_{ever_either,if_part_now,harm_now}_091326.png` |
| Table A9 | `A_tab_global_poly.do` | `rd_robu_091326.tex` |
| Figures A6-A7 | `A_fig_donuts.do` | `rr_A1_donut_{MDeuclid,SFfront}{,_fixedh}_091326.pdf` |
| Figure A8 | `A_fig_effort_havens_hrm.do` | `haven_outcome_{oldlist,haven,sink}_091026.png` |
| Figures A9-A10 | `F06_T04_governance_did.do` | `rr_A2_es_main_4panel_091126.pdf`, `rr_A2_es_NE_4panel_091526.pdf` |
| Table A10 | `F06_T04_governance_did.do` without least-developed countries (set by the master) | `rr_A2_govdid_table_noldc_091126.tex` |
| Table A11 | `P_tab_govdid_neverrev.do` | `rr_A2_govdid_neverrev_091226.tex` |
| Figure A11 [ITI] | `P_fig7_oecd_robustness.do` | `rr_fig6_oecd_scitr_091126.pdf` |
| Figure A12 [ITI] | `P_fig_ctr_gl_cohorts.do` | `rr_ctr_gl_cohorts_091526.pdf` |
| Figure A13 | `T05_econ_did_2026.do` | `rr_econ_es_2026_{deposits,fdistock,fdiflow}_091226.png` |
| Figure A14 | `F09_T06_harmful_regimes.do` | `{identified,harmful,rollback}_{cocg,oecd}_fuzzy_euc_091226.png` |
| Figure A15 | `A_fig_effort_havens_hrm.do` | `hrm{1,2,3}_091026.png` |
| Figure A16 | `A_fig_effort_havens_hrm.do` | `effort_outcome_{risk_transparency,preferential_regime,no_cit}{,2}_091326.png` |
| Figures A17-A18 | `A_fig_deficiency_letters.do` | `effort_outcome_{any_letter,c_1,c_5,c_8,c_3,c_6}{,2}_091326.png` |
| Table A12 | hand-made | *static* `rr_listing_costs_quotes_091526.tex` |

## Known differences from the published exhibits

- **FDI sample.** The published FDI results were produced with a `kountry` country-name file that had
  grown past Stata's size limit, so two UNCTAD economies received no ISO code and were dropped: North
  Macedonia (greylisted from December 2017) and State of Palestine (never listed). The package fixes the
  name file, so by default both are in the FDI panel. This changes four exhibits slightly: Figure 7(d),
  Figure A13 (FDI stock and flow) and the FDI panels of Table 5. No estimate changes sign; the largest
  event-study coefficient moves by 0.003 (0.3 percentage points of GNI, against standard errors of about
  8 points); the only change in significance is Table 5, Panel D, column (4), first blacklisting (0.085,
  p = 0.013 becomes 0.007). Set `fdi_accepted_sample 1` to reproduce the published exhibits exactly.
- **Figure 7(a)-(b)** use a wild bootstrap. `F07_tax_rates.do` sets the random-number state of the run
  that produced the published figure, so they reproduce exactly when the master runs in a fresh Stata
  session.
- Cosmetic only: fifteen appendix PNGs (Figures A8, A15-A18) are exported at 2,000 pixels wide rather
  than the 1,400 of the published files, with identical plotted content; in the PDFs of Figures 6, A9 and
  A10 one tick label sits 1/100 pt from its published position (font rendering, invisible); one panel of
  Figure A5 differs in a few pixels and the first panel of Figure 9 in a single pixel; Table A7 differs in
  trailing whitespace.
- **Part 1** (`run_data 1`) rebuilds the checkpoints the analysis reads identically, except
  `harm_043022.dta`, which comes back without three rows (Åland, Saint Helena, Venezuela). All three are
  outside the RD sample, so Table 6 and Figure A14 are unaffected. The MAP-profile scrape
  (`python/map_wayback_scrape.py`) cannot be re-run as shipped: its list of PDF URLs was lost; the
  archived PDFs it downloaded are in `input/map_wayback_profiles/`.

## Verification

Tested on 30 October 2026 with Stata/MP 18 on Windows 11, each time from a fresh copy of this repository
in a new folder, with the default settings:

- **With the ITI files in `input/`:** finished without errors in 62 minutes. All 88 files in `exhibits/`
  came back byte-identical; every dataset in `output/` had identical contents (the `.ster` estimate files
  differ only in their stored save time, and one intermediate file of Figure A11 in row order).
- **Without the ITI files:** finished without errors in 53 minutes. The six ITI scripts were skipped with
  a message, leaving the ten files of Figure 7(a)-(b), Figure 9, Tables 3 and 5 and Figures A11-A12
  untouched; the other 78 exhibits came back byte-identical.
- **Part 1** (`run_data 1`): tested the same day on the package before the ITI check and the BIS 2022
  extract were added. Every checkpoint the analysis reads rebuilt with identical contents, apart from
  `harm_043022.dta` as described above, and all exhibits matched. `D10_bis_deposits.do` was then re-run
  on the extract and rebuilt `bis_091125_quarterly.dta` with identical contents.

## Licence

Code (`master_rr.do`, `do/`, `python/`): BSD 3-Clause, see `LICENSE`. Data and documents compiled by
the author, the exhibits and this documentation: CC BY 4.0, see `LICENSE-data.md`. Third-party data
remain under their providers' terms, and the packages in `ado/` under their authors' licences.
