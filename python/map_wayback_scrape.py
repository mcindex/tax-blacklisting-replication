"""
map_wayback_scrape.py — build a dated panel of OECD MAP-profile publication.

Context (R&R item A2, session 2026-08-24): the project's six MAP snapshots are
interval-censored. The OECD publishes one dispute-resolution-profile PDF per
jurisdiction; the Wayback Machine's earliest capture of each PDF bounds its
publication date from above, and the "last updated" line printed at the top of
each profile gives the OECD's own date.

Pipeline:
 1. Country PDF URLs were extracted from the archived index page
    (web.archive.org/web/20240713194356/.../mutual-agreement-procedure-profiles.html)
    into map_pdf_urls.json (118 URLs).
 2. For each country, query the Wayback CDX API for BOTH url generations
    (/tax/dispute/... and /ctp/dispute/...) — the OECD moved the files around,
    so the earliest capture is often under the other path. CDX canonicalises
    case, so capitalisation variants are covered automatically.
 3. Take the earliest 200/PDF capture across variants; download the original
    bytes (the `id_` timestamp flag).
 4. Extract page-1 text and parse the "last updated" date.
 5. Write output/map_wayback_panel.csv (one row per jurisdiction).

Restartable: state is kept in output/map_wayback_state.json; every network
result is cached there, so re-running skips completed work.

Usage:  python python/map_wayback_scrape.py [--phase cdx|download|extract|all]
"""
import json, os, re, sys, time
import requests

# 2026-10-28: paths relative to the package root (were absolute). The step-1 URL list was kept in a temporary
# folder that no longer exists; to re-run, rebuild it from the archived index page into input/map_pdf_urls.json.
PROJ    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
URLJSON = os.path.join(PROJ, "input", "map_pdf_urls.json")
PDFDIR  = os.path.join(PROJ, "input", "map_wayback_profiles")
STATE   = os.path.join(PROJ, "output", "map_wayback_state.json")
OUTCSV  = os.path.join(PROJ, "output", "map_wayback_panel.csv")

CDX = "https://web.archive.org/cdx/search/cdx"
HDR = {"User-Agent": "academic-research-map-profiles/1.0 (replication data collection)"}

os.makedirs(PDFDIR, exist_ok=True)

def load_state():
    if os.path.exists(STATE):
        return json.load(open(STATE))
    return {}

def save_state(st):
    json.dump(st, open(STATE, "w"), indent=1)

def slug_of(url):
    return url.rsplit("/", 1)[1].lower().replace("-dispute-resolution-profile.pdf", "")

def variants(url):
    fn = url.rsplit("/", 1)[1]
    return [f"https://www.oecd.org/tax/dispute/{fn}",
            f"https://www.oecd.org/ctp/dispute/{fn}"]

def cdx_earliest(url, sess, tries=4):
    """Earliest 200 capture of url; returns (timestamp, original_url) or None."""
    params = {"url": url, "output": "json", "filter": "statuscode:200",
              "limit": "3", "fl": "timestamp,original,mimetype"}
    for a in range(tries):
        try:
            r = sess.get(CDX, params=params, headers=HDR, timeout=60)
            if r.status_code == 200:
                rows = r.json()
                for row in rows[1:]:
                    ts, orig, mt = row
                    if "pdf" in mt.lower() or mt == "unk":
                        return ts, orig
                return None
            if r.status_code in (429, 503):
                time.sleep(10 * (a + 1)); continue
            return None
        except Exception:
            time.sleep(5 * (a + 1))
    return "ERROR"

def phase_cdx(st, urls):
    sess = requests.Session()
    done = 0
    for u in urls:
        s = slug_of(u)
        rec = st.setdefault(s, {"index_url": u})
        if "earliest" in rec and rec["earliest"] != "ERROR":
            continue
        best = None
        for v in variants(u):
            res = cdx_earliest(v, sess)
            time.sleep(0.6)
            if res and res != "ERROR":
                if best is None or res[0] < best[0]:
                    best = res
        rec["earliest"] = list(best) if best else None
        done += 1
        if done % 5 == 0:
            save_state(st)
        print(f"[cdx] {s}: {best[0] if best else 'NO CAPTURE'}", flush=True)
    save_state(st)

def phase_download(st):
    sess = requests.Session()
    for s, rec in st.items():
        if not rec.get("earliest") or rec["earliest"] == "ERROR":
            continue
        ts, orig = rec["earliest"]
        fp = os.path.join(PDFDIR, f"{s}_{ts}.pdf")
        rec["pdf_file"] = fp
        if os.path.exists(fp) and os.path.getsize(fp) > 10000:
            continue
        url = f"https://web.archive.org/web/{ts}id_/{orig}"
        for a in range(4):
            try:
                r = sess.get(url, headers=HDR, timeout=120)
                if r.status_code == 200 and r.content[:4] == b"%PDF":
                    open(fp, "wb").write(r.content)
                    print(f"[dl] {s}: {len(r.content)//1024} KB", flush=True)
                    break
                if r.status_code in (429, 503):
                    time.sleep(15 * (a + 1)); continue
                print(f"[dl] {s}: HTTP {r.status_code}", flush=True)
                rec["dl_error"] = r.status_code
                break
            except Exception as e:
                time.sleep(8 * (a + 1))
        time.sleep(0.8)
    save_state(st)

MONTHS = "january|february|march|april|may|june|july|august|september|october|november|december"
DATE_PATTERNS = [
    # 0/1: "last updated: [dd] Month YYYY"
    rf"last\s+update[ds]?\s*:?\s*(\d{{1,2}})?\s*({MONTHS})\s+(\d{{4}})",
    rf"updated?\s*:?\s*(\d{{1,2}})?\s*({MONTHS})\s+(\d{{4}})",
    # 2: numeric "last updated: dd.mm.yyyy" (also d/m/yyyy, d-m-yyyy)
    r"last\s+update[ds]?\s*:?\s*(\d{1,2})[./-](\d{1,2})[./-](\d{4})",
    # 3: bare "Month YYYY" near the top
    rf"({MONTHS})\s+(\d{{4}})",
]
MONTH_LIST = MONTHS.split("|")
# French profiles: "Dernière mise à jour: 12 Janvier 2018"
FR_MONTHS = ("janvier","fevrier","mars","avril","mai","juin","juillet",
             "aout","septembre","octobre","novembre","decembre")
FR_PAT = (r"mise\s+a\s+jour\s*:?\s*(\d{1,2})?\s*(" +
          "|".join(FR_MONTHS) + r")\s+(\d{4})")

def parse_last_updated(text):
    t = re.sub(r"\s+", " ", text.lower())
    # strip accents so the French pattern matches "à jour", "août", "février"
    t = (t.replace("à", "a").replace("â", "a").replace("é", "e")
          .replace("è", "e").replace("ê", "e").replace("û", "u"))
    head = t[:2000]
    m = re.search(FR_PAT, head)
    if m:
        day, mon, yr = m.groups()
        mon_en = MONTH_LIST[FR_MONTHS.index(mon)]
        return f"{(day or '1')} {mon_en} {yr}", 4
    # French numeric: "mise a jour: 21/09/2023"
    m = re.search(r"mise\s+a\s+jour\s*:?\s*(\d{1,2})[./-](\d{1,2})[./-](\d{4})", head)
    if m:
        day, mm, yr = m.groups()
        mi = int(mm)
        if 1 <= mi <= 12:
            return f"{day} {MONTH_LIST[mi-1]} {yr}", 5
    for i, pat in enumerate(DATE_PATTERNS):
        m = re.search(pat, head)
        if m:
            g = m.groups()
            if i < 2:
                day, mon, yr = g
            elif i == 2:
                day, mm, yr = g
                mi = int(mm)
                if not 1 <= mi <= 12:
                    continue
                mon = MONTH_LIST[mi - 1]
            else:
                mon, yr = g; day = None
            return f"{(day or '1')} {mon} {yr}", i
    return None, None

def phase_extract(st):
    from pypdf import PdfReader
    for s, rec in st.items():
        fp = rec.get("pdf_file")
        if not fp or not os.path.exists(fp):
            continue
        if "last_updated_raw" in rec and rec["last_updated_raw"]:
            continue
        try:
            rd = PdfReader(fp)
            text = ""
            for pg in rd.pages[:2]:
                text += (pg.extract_text() or "") + "\n"
            if len(text.strip()) < 50:          # pypdf drew a blank — retry
                import pdfplumber                # with pdfplumber's extractor
                with pdfplumber.open(fp) as pl:
                    for pg in pl.pages[:2]:
                        text += (pg.extract_text() or "") + "\n"
            raw, patno = parse_last_updated(text)
            rec["last_updated_raw"] = raw
            rec["pattern_used"] = patno
            rec["page1_head"] = re.sub(r"\s+", " ", text)[:300]
            print(f"[ex] {s}: {raw}", flush=True)
        except Exception as e:
            rec["extract_error"] = str(e)[:200]
            print(f"[ex] {s}: ERROR {e}", flush=True)
    save_state(st)

def phase_csv(st):
    import csv
    from datetime import datetime
    rows = []
    for s, rec in sorted(st.items()):
        ts = rec.get("earliest")[0] if rec.get("earliest") and rec["earliest"] != "ERROR" else None
        lu = rec.get("last_updated_raw")
        lu_iso = None
        if lu:
            try:
                lu_iso = datetime.strptime(lu, "%d %B %Y").date().isoformat()
            except ValueError:
                pass
        rows.append({
            "slug": s,
            "wayback_first_capture": f"{ts[:4]}-{ts[4:6]}-{ts[6:8]}" if ts else "",
            "last_updated": lu_iso or "",
            "last_updated_raw": lu or "",
            "pattern_used": rec.get("pattern_used", ""),
            "pdf_file": os.path.basename(rec.get("pdf_file", "")) if rec.get("pdf_file") else "",
            "capture_url_original": rec["earliest"][1] if ts else "",
        })
    with open(OUTCSV, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    print(f"wrote {OUTCSV} ({len(rows)} rows)", flush=True)

if __name__ == "__main__":
    phase = sys.argv[sys.argv.index("--phase") + 1] if "--phase" in sys.argv else "all"
    urls = json.load(open(URLJSON))
    st = load_state()
    if phase in ("cdx", "all"):      phase_cdx(st, urls)
    if phase in ("download", "all"): phase_download(st)
    if phase in ("extract", "all"):  phase_extract(st)
    phase_csv(st)
    print("done.", flush=True)
