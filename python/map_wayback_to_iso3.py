"""
map_wayback_to_iso3.py — attach ISO3 codes to the Wayback MAP-profile dating
panel (output/map_wayback_panel.csv -> output/map_wayback_dates_iso3.csv).

Explicit hand mapping for all 118 slugs (no fuzzy matching): the slug set is
fixed by the July-2024 OECD index page, so a complete dictionary is both
safest and self-documenting. Asserts completeness on both sides.
"""
import csv, os

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # 2026-10-28: package root (was an absolute path)
INCSV  = os.path.join(PROJ, "output", "map_wayback_panel.csv")
OUTCSV = os.path.join(PROJ, "output", "map_wayback_dates_iso3.csv")

ISO3 = {
 "albania":"ALB","andorra":"AND","argentina":"ARG","armenia":"ARM","aruba":"ABW",
 "australia":"AUS","austria":"AUT","azerbaijan":"AZE","bahrain":"BHR",
 "barbados":"BRB","belgium":"BEL","benin":"BEN","bermuda":"BMU",
 "bosnia-and-herzegovina":"BIH","botswana":"BWA","brazil":"BRA",
 "british-virgin-islands":"VGB","brunei":"BRN","bulgaria":"BGR",
 "burkina-faso":"BFA","cameroon":"CMR","canada":"CAN","cayman-islands":"CYM",
 "chile":"CHL","china":"CHN","colombia":"COL","cook-islands":"COK",
 "costa-rica":"CRI","cote-divoire":"CIV","croatia":"HRV","curacao":"CUW",
 "czechia":"CZE","denmark":"DNK","dominica":"DMA","dominican-republic":"DOM",
 "drc":"COD","egypt":"EGY","estonia":"EST","finland":"FIN","france":"FRA",
 "gabon":"GAB","germany":"DEU","gibraltar":"GIB","greece":"GRC",
 "greenland":"GRL","guernsey":"GGY","hong-kong":"HKG","hungary":"HUN",
 "iceland":"ISL","india":"IND","indonesia":"IDN","ireland":"IRL",
 "isle-of-man":"IMN","israel":"ISR","italy":"ITA","jamaica":"JAM",
 "japan":"JPN","jersey":"JEY","kazakhstan":"KAZ","kenya":"KEN","korea":"KOR",
 "latvia":"LVA","liechtenstein":"LIE","lithuania":"LTU","luxembourg":"LUX",
 "macau":"MAC","malaysia":"MYS","maldives":"MDV","malta":"MLT",
 "mauritania":"MRT","mauritius":"MUS","mexico":"MEX","monaco":"MCO",
 "mongolia":"MNG","morocco":"MAR","new-zealand":"NZL","nigeria":"NGA",
 "north-macedonia":"MKD","norway":"NOR","oman":"OMN","pakistan":"PAK",
 "panama":"PAN","papua-new-guinea":"PNG","paraguay":"PRY","peru":"PER",
 "poland":"POL","portugal":"PRT","qatar":"QAT","romania":"ROU","samoa":"WSM",
 "san-marino":"SMR","saudi-arabia":"SAU","senegal":"SEN","serbia":"SRB",
 "seychelles":"SYC","singapore":"SGP","slovak-republic":"SVK",
 "slovenia":"SVN","south-africa":"ZAF","spain":"ESP","sri-lanka":"LKA",
 "st.kitts-and-nevis":"KNA","sweden":"SWE","switzerland":"CHE",
 "thailand":"THA","the-bahamas":"BHS","the-faroe-islands":"FRO",
 "the-netherlands":"NLD","trinidad-and-tobago":"TTO","tunisia":"TUN",
 "turkiye":"TUR","ukraine":"UKR","united-arab-emirates":"ARE",
 "united-kingdom":"GBR","united-states":"USA","uruguay":"URY",
 "vietnam":"VNM","zambia":"ZMB",
}

rows = list(csv.DictReader(open(INCSV, encoding="utf-8")))
unmapped = [r["slug"] for r in rows if r["slug"] not in ISO3]
assert not unmapped, f"unmapped slugs: {unmapped}"
unused = set(ISO3) - {r["slug"] for r in rows}
assert not unused, f"dict entries with no csv row: {unused}"
codes = [ISO3[r["slug"]] for r in rows]
assert len(codes) == len(set(codes)), "duplicate iso3!"

with open(OUTCSV, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["iso3", "slug", "wayback_first_capture", "last_updated"])
    for r in rows:
        w.writerow([ISO3[r["slug"]], r["slug"],
                    r["wayback_first_capture"], r["last_updated"]])
print(f"wrote {OUTCSV}: {len(rows)} rows, all mapped")
