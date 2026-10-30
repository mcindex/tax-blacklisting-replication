"""aeoi_ratings_091526.py -- build the AEOI effectiveness outcome (2026-09-15).

Source: OECD / Global Forum, "Automatic exchange of information ratings"
  https://www.oecd.org/en/networks/global-forum-tax-transparency/resources/automatic-exchange-of-information-ratings.html
The page embeds Datawrapper chart ZAIre (version 71, published 2026-07-08); its dataset is
  https://datawrapper.dwcdn.net/ZAIre/71/dataset.csv
saved as output/aeoi_ratings_datawrapper_ZAIre71_091526.csv (the oecd.org page returns 403 to scripts).
The author's input/aeoi_ratings_2.xlsx is the same table (checked identical on all names and overall ratings).

Coding: aeoi_ontrack = 1 if "Overall rating" == "On Track"; 0 otherwise, including jurisdictions not in the table.
ISO2 codes come from the flag tags (":al: Albania"); XK -> XKS. Merged onto the 209 non-EU jurisdictions of
output/regready_042822_gdp2026_frozen20260820.dta.
Output: output/aeoi_ontrack_091526.{dta,csv}  (read by do/D11_aeoi_ontrack.do)

Run from the replication_rr folder:  python python/aeoi_ratings_091526.py [--download]
"""
import sys
import pandas as pd
import pycountry

RAW = "output/aeoi_ratings_datawrapper_ZAIre71_091526.csv"
URL = "https://datawrapper.dwcdn.net/ZAIre/71/dataset.csv"

if "--download" in sys.argv:
    import requests
    r = requests.get(URL, headers={"User-Agent": "Mozilla/5.0"}, timeout=60)
    r.raise_for_status()
    open(RAW, "wb").write(r.content)

dw = pd.read_csv(RAW)
dw["iso2"] = dw["Jurisdiction"].str.extract(r"^:(\w\w):")[0].str.upper()
dw["name"] = dw["Jurisdiction"].str.replace(r"^:\w\w:\s*", "", regex=True).str.strip()
fix = {"XK": "XKS"}


def iso3(code):
    if code in fix:
        return fix[code]
    c = pycountry.countries.get(alpha_2=code)
    return c.alpha_3 if c else None


dw["iso3"] = dw["iso2"].map(iso3)
assert dw["iso3"].notna().all(), dw[dw["iso3"].isna()]

base = pd.read_stata("output/regready_042822_gdp2026_frozen20260820.dta", convert_categoricals=False)[["iso3", "country"]]
out = base.merge(dw[["iso3", "name", "Overall rating"]], on="iso3", how="left", indicator=True)
out = out.rename(columns={"Overall rating": "aeoi_overall_rating", "name": "aeoi_table_name"})
out["aeoi_rated"] = (out["_merge"] == "both").astype(int)
out["aeoi_ontrack"] = (out["aeoi_overall_rating"] == "On Track").astype(int)
out = out.drop(columns="_merge")
print(out["aeoi_overall_rating"].fillna("(not in table)").value_counts())
out.to_csv("output/aeoi_ontrack_091526.csv", index=False)
out.to_stata(
    "output/aeoi_ontrack_091526.dta", write_index=False, version=118,
    variable_labels={
        "aeoi_overall_rating": "Global Forum AEOI overall rating (OECD table, chart v71, published 2026-07-08)",
        "aeoi_rated": "=1 if in the AEOI ratings table",
        "aeoi_ontrack": "=1 if overall rating On Track; 0 otherwise incl. not in table",
    },
)
