"""
econ_data_extract_2026.py

Pre-processing for do/rr_econ_did_2026_090926.do (R&R, 2026-09-09).

1. BIS Locational Banking Statistics, vintage saved by the author on 2026-09-09
   as input/WS_LBS_D_PUB_csv_col.zip (537 MB CSV inside, quarters 1977-Q4 to
   2026-Q1). Stata cannot read the zip, and the full CSV is too large to keep
   a second copy in Dropbox, so this script streams it and keeps only the rows
   that do/bis_deposits_091125.do selects:
     series 1  Cross-border | Total liabilities | Stocks | Non-banks, total |
               All instruments | counterparty = individual countries
               (-> euro_deposits: EU-reporting banks' liabilities by counterparty)
     series 2  Cross-border | Total liabilities | Stocks | All sectors |
               All instruments | counterparty = All countries  (-> deposits_allsectors)
     series 3  Local | Total liabilities | Stocks | Non-banks, total |
               All currencies | All currencies (=D+F+U) | All instruments
               (-> deposits_local)
     series 4  Cross-border | Total liabilities | Stocks | Non-banks, total |
               All instruments | counterparty = All countries  (-> deposits)
   In this vintage the counterparty-total label is "All countries" (the 2025
   file said "All countries (total)"); both are accepted.
   -> output/bis_lbs_2026_filtered.csv  (same columns as the source)

2. UNCTAD FDI flows and stocks, saved by the author as
   input/US_FdiFlowsStock_updated.csv - which is in fact a 7z archive containing
   US_FdiFlowsStock.csv (years 1990-2025; the value column is now named
   "Millions of US$ at current prices").
   -> output/US_FdiFlowsStock_2026.csv

Run from the project root:  python python/econ_data_extract_2026.py
"""
import csv
import io
import os
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INP = os.path.join(ROOT, "input")
OUT = os.path.join(ROOT, "output")

# --- 1. BIS LBS -------------------------------------------------------------
zpath = os.path.join(INP, "WS_LBS_D_PUB_csv_col.zip")
opath = os.path.join(OUT, "bis_lbs_2026_filtered.csv")
z = zipfile.ZipFile(zpath)
name = [n for n in z.namelist() if n.lower().endswith(".csv")][0]
src = io.TextIOWrapper(z.open(name), encoding="utf-8", errors="ignore", newline="")
rdr = csv.reader(src)
hdr = next(rdr)
ix = {c: hdr.index(c) for c in [
    "Measure", "Balance sheet position", "Type of instruments",
    "Currency denomination", "Currency type of reporting country",
    "Counterparty sector", "Counterparty country", "Position type",
    "Reporting country"]}
ALLCTY = {"All countries", "All countries (total)"}


def keep(row):
    g = lambda c: row[ix[c]]
    if g("Measure") != "Amounts outstanding / Stocks":
        return False
    if g("Balance sheet position") != "Total liabilities":
        return False
    if g("Type of instruments") != "All instruments":
        return False
    if g("Reporting country") == "All reporting countries":
        return False
    pos, sec, cp = g("Position type"), g("Counterparty sector"), g("Counterparty country")
    if pos == "Cross-border" and sec == "Non-banks, total":
        return True                                   # series 1 and 4
    if pos == "Cross-border" and sec == "All sectors" and cp in ALLCTY:
        return True                                   # series 2
    if (pos == "Local" and sec == "Non-banks, total"
            and g("Currency denomination") == "All currencies"
            and g("Currency type of reporting country") == "All currencies (=D+F+U)"):
        return True                                   # series 3
    return False


n_in = n_out = 0
with open(opath, "w", encoding="utf-8", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(hdr)
    for row in rdr:
        n_in += 1
        if keep(row):
            w.writerow(row)
            n_out += 1
print(f"BIS: {n_in:,} rows read, {n_out:,} kept -> {opath}")
print(f"BIS: first data column {hdr[31]}, last column {hdr[-1]}, {len(hdr)} columns")

# --- 2. UNCTAD FDI (7z) ------------------------------------------------------
seven = r"C:\Program Files\7-Zip\7z.exe"
apath = os.path.join(INP, "US_FdiFlowsStock_updated.csv")
tmpdir = os.path.join(OUT, "_unctad_tmp")
os.makedirs(tmpdir, exist_ok=True)
subprocess.run([seven, "x", "-y", f"-o{tmpdir}", apath], check=True,
               stdout=subprocess.DEVNULL)
extracted = os.path.join(tmpdir, "US_FdiFlowsStock.csv")
fpath = os.path.join(OUT, "US_FdiFlowsStock_2026.csv")
os.replace(extracted, fpath)
try:
    os.rmdir(tmpdir)          # Dropbox may hold the folder briefly
except OSError:
    pass
with open(fpath, encoding="utf-8", errors="ignore") as fh:
    h = next(csv.reader(fh))
print(f"UNCTAD: -> {fpath}; columns: {h}")
