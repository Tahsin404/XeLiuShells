#!/usr/bin/env bash
# ~/.config/quickshell/scripts/get_holidays.sh
# Universal Location-Aware Holiday Engine for Quickshell (Rolling ±10 Year Window)

YEAR="${1:-$(date +%Y)}"

python3 - "$YEAR" <<'PYEOF'
import sys
import os
import re
import time
import math
import json
import urllib.request
from datetime import date, datetime, timedelta

target_year = int(sys.argv[1]) if len(sys.argv) > 1 else date.today().year
current_year = date.today().year
min_window_year = current_year - 10
max_window_year = current_year + 10

cache_dir = os.path.expanduser("~/.cache/quickshell")
os.makedirs(cache_dir, exist_ok=True)
config_path = os.path.expanduser("~/.config/quickshell/config.json")

# Load optional user config overrides
user_cfg = {}
if os.path.exists(config_path):
    try:
        with open(config_path, "r", encoding="utf-8") as cf:
            user_cfg = json.load(cf)
    except Exception:
        pass

# -------------------------------------------------------------------------
# 1. Privacy-First Country Detection (Config -> System Timezone -> Locale)
# -------------------------------------------------------------------------
def detect_country_code():
    # Tier 1: Explicit user preference in ~/.config/quickshell/config.json
    cfg_country = (
        user_cfg.get("localization", {}).get("countryCode")
        or user_cfg.get("countryCode")
        or "AUTO"
    ).strip().upper()
    if len(cfg_country) == 2 and cfg_country.isalpha():
        return cfg_country

    # Tier 2: Offline Linux System Timezone (/etc/localtime -> /usr/share/zoneinfo/zone1970.tab)
    try:
        real_tz = os.path.realpath("/etc/localtime")
        if "zoneinfo/" in real_tz:
            tz_name = real_tz.split("zoneinfo/", 1)[1]
            for zone_tab in ["/usr/share/zoneinfo/zone1970.tab", "/usr/share/zoneinfo/zone.tab"]:
                if os.path.exists(zone_tab):
                    with open(zone_tab, "r", encoding="utf-8", errors="ignore") as zf:
                        for line in zf:
                            if line.startswith("#") or not line.strip():
                                continue
                            parts = line.strip().split("\t")
                            if len(parts) >= 3 and parts[2] == tz_name:
                                code = parts[0].split(",")[0].strip().upper()
                                if len(code) == 2 and code.isalpha():
                                    return code
    except Exception:
        pass

    # Tier 3: Offline System Locale ($LC_TIME / $LANG)
    for env_var in ["LC_TIME", "LC_ALL", "LANG"]:
        val = os.environ.get(env_var, "")
        m = re.search(r"_([A-Z]{2})", val)
        if m:
            return m.group(1)

    return "BD"

country = detect_country_code()

# Fast Per-Year Cache Check (7-day TTL so scrolling between years is instant!)
year_cache_file = os.path.join(cache_dir, f"holidays_{country}_{target_year}.json")
if os.path.exists(year_cache_file):
    age_days = (time.time() - os.path.getmtime(year_cache_file)) / 86400.0
    if age_days < 7 and os.path.getsize(year_cache_file) > 50:
        with open(year_cache_file, "r", encoding="utf-8") as yf:
            print(yf.read().strip())
        sys.exit(0)

holidays = {}

# -------------------------------------------------------------------------
# 2. Dynamic Astronomical Calculators (Works for ANY year: 2016, 2037, 2050+)
# -------------------------------------------------------------------------
SYNODIC_MONTH = 29.530588853
REF_NEW_MOON = datetime(2000, 1, 6, 18, 14)

def get_moon_phase_after(target_dt, phase_offset=0.0, tz_hours=6.0):
    diff_days = (target_dt - REF_NEW_MOON).total_seconds() / 86400.0
    cycles = math.floor(diff_days / SYNODIC_MONTH)
    for k in range(int(cycles) - 1, int(cycles) + 3):
        lunation = k + phase_offset
        t = lunation / 1236.85
        jde = 2451550.09766 + SYNODIC_MONTH * lunation + 0.00015437 * (t ** 2)
        dt = datetime(2000, 1, 1, 12, 0) + timedelta(days=(jde - 2451545.0) + (tz_hours / 24.0))
        if dt >= target_dt:
            return dt.date()
    return target_dt.date()

def hijri_to_gregorian(hy, hm, hd, moon_offset=0):
    jd = (
        int((11 * hy + 3) / 30)
        + 354 * hy
        + 30 * hm
        - int((hm - 1) / 2)
        + hd
        + 1948440
        - 385
    )
    l = jd + 68569 + moon_offset
    n = int((4 * l) / 146097)
    l = l - int((146097 * n + 3) / 4)
    i = int((4000 * (l + 1)) / 1461001)
    l = l - int((1461 * i) / 4) + 31
    j = int((80 * l) / 2447)
    day = l - int((2447 * j) / 80)
    l = int(j / 11)
    month = j + 2 - 12 * l
    greg_year = 100 * (n - 49) + i + l
    try:
        return date(greg_year, month, day)
    except ValueError:
        return None

def add_regional_astronomical_holidays(y, cc):
    islamic_countries = {"BD", "PK", "IN", "MY", "ID", "SA", "AE", "EG", "TR", "MA", "DZ", "TN", "JO", "KW", "QA", "OM", "BH"}
    south_asia_offset = 1 if cc in {"BD", "IN", "PK"} else 0

    if cc in islamic_countries:
        approx_hy = int((y - 622) * 33 / 32)
        for hy in range(approx_hy - 1, approx_hy + 2):
            d_ashura = hijri_to_gregorian(hy, 1, 10, south_asia_offset)
            if d_ashura and d_ashura.year == y:
                holidays[d_ashura.isoformat()] = "Holy Ashura"

            d_milad = hijri_to_gregorian(hy, 3, 12, south_asia_offset)
            if d_milad and d_milad.year == y:
                holidays[d_milad.isoformat()] = "Eid-e-Milad-un-Nabi"

            if cc in {"BD", "PK", "IN"}:
                d_barat = hijri_to_gregorian(hy, 8, 15, south_asia_offset)
                if d_barat and d_barat.year == y:
                    holidays[d_barat.isoformat()] = "Shab-e-Barat"

                d_qadr = hijri_to_gregorian(hy, 9, 27, south_asia_offset)
                if d_qadr and d_qadr.year == y:
                    holidays[d_qadr.isoformat()] = "Shab-e-Qadr"

            d_fitr = hijri_to_gregorian(hy, 10, 1, south_asia_offset)
            if d_fitr:
                if cc == "BD":
                    for back in range(1, 8):
                        cand = d_fitr - timedelta(days=back)
                        if cand.weekday() == 4:
                            if cand.year == y:
                                holidays[cand.isoformat()] = "Jumatul Bida"
                            break
                    for offset in range(-2, 3):
                        cur = d_fitr + timedelta(days=offset)
                        if cur.year == y:
                            holidays[cur.isoformat()] = "Eid-ul-Fitr" if offset == 0 else "Eid-ul-Fitr Holiday"
                else:
                    for offset in range(0, 3):
                        cur = d_fitr + timedelta(days=offset)
                        if cur.year == y:
                            holidays[cur.isoformat()] = "Eid-ul-Fitr" if offset == 0 else "Eid-ul-Fitr Holiday"

            d_adha = hijri_to_gregorian(hy, 12, 10, south_asia_offset)
            if d_adha:
                win = range(-2, 4) if cc == "BD" else range(0, 3)
                for offset in win:
                    cur = d_adha + timedelta(days=offset)
                    if cur.year == y:
                        holidays[cur.isoformat()] = "Eid-ul-Adha" if offset == 0 else "Eid-ul-Adha Holiday"

    if cc in {"BD", "IN", "NP", "LK"}:
        bp = get_moon_phase_after(datetime(y, 4, 28), phase_offset=0.5)
        holidays[bp.isoformat()] = "Buddha Purnima"

        shravana_nm = get_moon_phase_after(datetime(y, 7, 25), phase_offset=0.0)
        jm = shravana_nm + timedelta(days=22)
        holidays[jm.isoformat()] = "Shubho Janmashtami"

        mahalaya_nm = get_moon_phase_after(datetime(y, 9, 16), phase_offset=0.0)
        puja_days = [
            (7, "Durga Puja (Maha Saptami)"),
            (8, "Durga Puja (Maha Ashtami)"),
            (9, "Durga Puja (Maha Nabami)"),
            (10, "Durga Puja (Bijoya Dashami)"),
        ]
        for offset, label in puja_days:
            p_date = mahalaya_nm + timedelta(days=offset)
            if p_date.year == y:
                holidays[p_date.isoformat()] = label

    if cc == "BD":
        bd_fixed = {
            f"{y}-02-21": "Shaheed Day & International Mother Language Day",
            f"{y}-03-17": "Children's Day",
            f"{y}-03-26": "Independence & National Day",
            f"{y}-04-14": "Pahela Baishakh (Bangla New Year)",
            f"{y}-05-01": "May Day",
            f"{y}-08-05": "July Mass Uprising Day",
            f"{y}-11-07": "National Revolution & Solidarity Day",
            f"{y}-12-16": "Victory Day",
            f"{y}-12-25": "Christmas Day",
        }
        holidays.update(bd_fixed)

add_regional_astronomical_holidays(target_year, country)

# -------------------------------------------------------------------------
# 3. Live Nager.Date Public Holidays API
# -------------------------------------------------------------------------
try:
    req = urllib.request.Request(
        f"https://date.nager.at/api/v3/PublicHolidays/{target_year}/{country}",
        headers={"User-Agent": "Quickshell-Calendar/2.0"}
    )
    with urllib.request.urlopen(req, timeout=2.5) as resp:
        if resp.status == 200:
            nager_data = json.loads(resp.read().decode("utf-8"))
            for item in nager_data:
                d = item.get("date")
                name = item.get("name") or item.get("localName")
                if d and name:
                    holidays[d] = name
except Exception:
    pass

# -------------------------------------------------------------------------
# 4. Live Google Calendar Regional Holiday Feed (.ics)
# -------------------------------------------------------------------------
GOOGLE_FEED_MAP = {
    "BD": "bd", "US": "usa", "GB": "uk", "CA": "canadian", "AU": "australian",
    "IN": "indian", "PK": "pk", "DE": "german", "FR": "french", "JP": "japanese",
    "CN": "china", "KR": "south_korea", "BR": "brazilian", "IT": "italian",
    "ES": "spain", "NL": "dutch", "SE": "swedish", "NO": "norwegian", "DK": "danish",
    "FI": "finnish", "PL": "polish", "RU": "russian", "TR": "turkish", "SA": "saudiarabian",
    "AE": "ae", "MY": "malaysia", "ID": "indonesian", "SG": "singapore", "PH": "philippines",
    "NZ": "new_zealand", "MX": "mexican", "AR": "argentina", "ZA": "sa", "NG": "ng", "EG": "eg"
}

g_slug = GOOGLE_FEED_MAP.get(country, country.lower())
ics_cache = os.path.join(cache_dir, f"google_ics_{country}.ics")

def fetch_and_parse_google_ics(slug):
    urls = [
        f"https://calendar.google.com/calendar/ical/en.{slug}.official%23holiday%40group.v.calendar.google.com/public/basic.ics",
        f"https://calendar.google.com/calendar/ical/en.{slug}%23holiday%40group.v.calendar.google.com/public/basic.ics",
    ]
    need_download = True
    if os.path.exists(ics_cache):
        age_hours = (time.time() - os.path.getmtime(ics_cache)) / 3600.0
        if age_hours < 24 and os.path.getsize(ics_cache) > 200:
            need_download = False

    if need_download:
        combined = ""
        for u in urls:
            try:
                req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=3.0) as resp:
                    if resp.status == 200:
                        combined += resp.read().decode("utf-8", errors="ignore") + "\n"
            except Exception:
                pass
        if combined.strip():
            with open(ics_cache, "w", encoding="utf-8") as f:
                f.write(combined)

    if not os.path.exists(ics_cache):
        return {}

    parsed = {}
    with open(ics_cache, "r", encoding="utf-8", errors="ignore") as f:
        raw_lines = f.read().splitlines()

    lines = []
    for line in raw_lines:
        if line.startswith((" ", "\t")) and lines:
            lines[-1] += line[1:]
        else:
            lines.append(line.strip())

    in_event = False
    dt_start = None
    dt_end = None
    summary = None

    for line in lines:
        if line == "BEGIN:VEVENT":
            in_event = True
            dt_start = None
            dt_end = None
            summary = None
        elif line == "END:VEVENT":
            if in_event and dt_start and summary:
                try:
                    s_date = datetime.strptime(dt_start[:8], "%Y%m%d").date()
                    e_date = datetime.strptime(dt_end[:8], "%Y%m%d").date() if dt_end else (s_date + timedelta(days=1))
                    cur = s_date
                    while cur < e_date:
                        if cur.year == target_year:
                            parsed[cur.isoformat()] = summary
                        cur += timedelta(days=1)
                except Exception:
                    pass
            in_event = False
        elif in_event:
            if line.startswith("DTSTART"):
                dt_start = line.split(":", 1)[-1].strip()
            elif line.startswith("DTEND"):
                dt_end = line.split(":", 1)[-1].strip()
            elif line.startswith("SUMMARY"):
                summary = line.split(":", 1)[-1].strip().replace("\\,", ",")

    return parsed

live_ics_events = fetch_and_parse_google_ics(g_slug)
for d_str, title in live_ics_events.items():
    holidays[d_str] = title

output_json = json.dumps({
    "country": country,
    "year": target_year,
    "window": [min_window_year, max_window_year],
    "dates": sorted(list(holidays.keys())),
    "names": holidays
})

with open(year_cache_file, "w", encoding="utf-8") as yf:
    yf.write(output_json)

print(output_json)
PYEOF
