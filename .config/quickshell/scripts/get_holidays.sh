#!/usr/bin/env bash
# ~/dotfiles/quickshell/.config/quickshell/scripts/get_holidays.sh
# Privacy-first holiday fetcher with offline timezone detection and state caching

YEAR="${1:-$(date +%Y)}"
ARG_CC="$2"
ARG_ALLOW_IP="$3"

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
USER_CONFIG="$XDG_CONFIG/xeliushells/config.json"
CACHE_DIR="$XDG_STATE/xeliushells/holidays"
mkdir -p "$CACHE_DIR"

# 1. Read countryCode and allowIpLookup from arguments or ~/.config/xeliushells/config.json
CC="$ARG_CC"
ALLOW_IP="$ARG_ALLOW_IP"

if [ -z "$CC" ] && [ -f "$USER_CONFIG" ] && command -v jq >/dev/null 2>&1; then
  CC=$(jq -r '.localization.countryCode // "AUTO"' "$USER_CONFIG" 2>/dev/null)
fi
if [ -z "$ALLOW_IP" ] && [ -f "$USER_CONFIG" ] && command -v jq >/dev/null 2>&1; then
  ALLOW_IP=$(jq -r '.localization.allowIpLookup // false' "$USER_CONFIG" 2>/dev/null)
fi

CC=$(echo "${CC:-AUTO}" | tr '[:lower:]' '[:upper:]' | xargs)

# 2. Respect OFF setting
if [[ "$CC" == "OFF" || "$CC" == "NONE" || "$CC" == "FALSE" ]]; then
  echo '{"dates":[],"names":{}}'
  exit 0
fi

# 3. Resolve AUTO country code (Offline Timezone -> Offline Locale -> Opt-in IP fallback)
if [[ "$CC" == "AUTO" || -z "$CC" ]]; then
  CC=""
  # Tier A: Offline /etc/localtime -> zone1970.tab lookup
  if [ -L /etc/localtime ] && [ -f /usr/share/zoneinfo/zone1970.tab ]; then
    TZ_NAME=$(readlink -f /etc/localtime | sed 's|^.*/zoneinfo/||')
    if [ -n "$TZ_NAME" ]; then
      CC=$(awk -F'\t' -v tz="$TZ_NAME" '!/^#/ && $3 == tz { split($1, a, ","); print a[1]; exit }' /usr/share/zoneinfo/zone1970.tab)
    fi
  fi

  # Tier B: Offline $LC_TIME / $LANG parsing (e.g., en_US.UTF-8 -> US)
  if [ -z "$CC" ]; then
    LOCALE_STR="${LC_TIME:-$LANG}"
    if [[ "$LOCALE_STR" =~ ^[a-z]{2}_([A-Z]{2}) ]]; then
      CC="${BASH_REMATCH[1]}"
    fi
  fi

  # Tier C: Opt-in IP lookup ONLY if allowIpLookup is explicitly true
  if [ -z "$CC" ] && [ "$ALLOW_IP" = "true" ]; then
    CC=$(curl -fsSL --max-time 3 "https://ipinfo.io/country" 2>/dev/null | tr -d '[:space:]')
  fi

  # Final fallback
  CC="${CC:-BD}"
fi

CACHE_FILE="$CACHE_DIR/holidays_${CC}_${YEAR}.json"

# 4. Serve from persistent state cache if available
if [ -s "$CACHE_FILE" ]; then
  cat "$CACHE_FILE"
  exit 0
fi

# 5. Fetch & format via Python (Nager.Date public holiday API or python-holidays)
python3 - "$YEAR" "$CC" "$CACHE_FILE" <<'PYEOF'
import json
import sys
import urllib.request

year = int(sys.argv[1])
cc = sys.argv[2].upper()
cache_file = sys.argv[3]

dates = []
names = {}

# Try local python-holidays library first if installed, otherwise Nager.Date API
loaded = False
try:
    import holidays
    h_list = holidays.country_holidays(cc, years=year)
    for dt, name in sorted(h_list.items()):
        key = f"{dt.month - 1}-{dt.day}"
        if key not in dates:
            dates.append(key)
        names[key] = name
    loaded = True
except Exception:
    pass

if not loaded:
    try:
        url = f"https://date.nager.at/api/v3/PublicHolidays/{year}/{cc}"
        req = urllib.request.Request(url, headers={"User-Agent": "XeLiuShells/1.0"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            for item in data:
                parts = item.get("date", "").split("-")
                if len(parts) == 3:
                    m = int(parts[1]) - 1
                    d = int(parts[2])
                    key = f"{m}-{d}"
                    if key not in dates:
                        dates.append(key)
                    names[key] = item.get("localName") or item.get("name") or "Holiday"
            loaded = True
    except Exception:
        pass

out = json.dumps({"dates": dates, "names": names})
if loaded and len(dates) > 0:
    try:
        with open(cache_file, "w", encoding="utf-8") as f:
            f.write(out)
    except Exception:
        pass

print(out)
PYEOF
