* bis_2022_extract.do  |  2026-10-30: one-off provenance script, not called by master_rr.do
* The 2022 vintage of the BIS Locational Banking Statistics read by D10_bis_deposits.do
* (input/WS_LBS_D_PUB_csv_col.csv, 530 MB) is too large for GitHub (100 MB file limit).
* This keeps the rows that pass any of D10's four row filters, after importing the full file, so
* every column keeps the storage type import delimited gives it on the full file (a CSV extract
* re-imported can come back as float instead of double and lose digits). D10 then applies its own
* filters to output/bis_lbs_2022_filtered.dta unchanged.
*   (1) Cross-border | Non-banks, total                      (euro deposits; and (4) = (1) + All countries (total))
*   (2) Cross-border | All sectors | All countries (total)   (deposits, all sectors)
*   (3) Local | Non-banks, total | All currencies | All currencies (=D+F+U)  (local deposits)
*   all: Total liabilities | Amounts outstanding / Stocks | All instruments | not "All reporting countries"

import delimited "$input\WS_LBS_D_PUB_csv_col.csv", clear
keep if balancesheet == "Total liabilities" & measure == "Amounts outstanding / Stocks" ///
    & typeofinstruments == "All instruments" & reportingcountry != "All reporting countries"
keep if (positiontype == "Cross-border" & counterpartysector == "Non-banks, total")            ///
      | (positiontype == "Cross-border" & counterpartysector == "All sectors"                  ///
         & counterpartycountry == "All countries (total)")                                     ///
      | (positiontype == "Local" & counterpartysector == "Non-banks, total"                    ///
         & currencydenomination == "All currencies"                                            ///
         & currencytypeofreportingcountry == "All currencies (=D+F+U)")
save "$output\bis_lbs_2022_filtered.dta", replace
