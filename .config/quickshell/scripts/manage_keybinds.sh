#!/usr/bin/env bash
# ~/dotfiles/quickshell/.config/quickshell/scripts/manage_keybinds.sh
# Compiles keybinds from ~/.config/xeliushells/config.json into
# ~/.local/state/xeliushells/hypr/quickshell_binds.conf without touching user files.

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

USER_CONFIG="$XDG_CONFIG/xeliushells/config.json"
HYPR_STATE_DIR="$XDG_STATE/xeliushells/hypr"
HYPR_BINDS_OUT="$HYPR_STATE_DIR/quickshell_binds.conf"
HYPR_USER_DIR="$XDG_CONFIG/hypr"

mkdir -p "$HYPR_STATE_DIR"

get_bind_field() {
  local target="$1"
  local field="$2"
  local fallback="$3"
  if [ -f "$USER_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    local has_key
    has_key=$(jq -r "(.keybinds.${target} != null) and (.keybinds.${target} | has(\"${field}\"))" "$USER_CONFIG" 2>/dev/null)
    if [ "$has_key" = "true" ]; then
      jq -r ".keybinds.${target}.${field}" "$USER_CONFIG" 2>/dev/null
      return
    fi
  fi
  echo "$fallback"
}

bind_type_for_key() {
  if [ "$1" = "SUPER_L" ]; then
    echo "bindr"
  elif [ "$1" = "SUPER_R" ]; then
    echo "bindr"
  else
    echo "bindn"
  fi
}

generate_hypr_conf() {
  local l_mods l_key m_mods m_key c_mods c_key u_mods u_key
  l_mods=$(get_bind_field "launcher" "mods" "SUPER")
  l_key=$(get_bind_field "launcher" "key" "SUPER_L")
  m_mods=$(get_bind_field "media" "mods" "")
  m_key=$(get_bind_field "media" "key" "F6")
  c_mods=$(get_bind_field "clock" "mods" "")
  c_key=$(get_bind_field "clock" "key" "F7")
  u_mods=$(get_bind_field "utility" "mods" "")
  u_key=$(get_bind_field "utility" "key" "F8")

  local l_bind_type m_bind_type c_bind_type u_bind_type
  l_bind_type=$(bind_type_for_key "$l_key")
  m_bind_type=$(bind_type_for_key "$m_key")
  c_bind_type=$(bind_type_for_key "$c_key")
  u_bind_type=$(bind_type_for_key "$u_key")

  cat <<EOF >"$HYPR_BINDS_OUT"
# ==============================================================================
# XELIUSHELLS MANAGED KEYBINDS (Auto-generated in ~/.local/state/xeliushells/hypr)
# Add to hyprland.conf:
#   source = ~/.local/state/xeliushells/hypr/quickshell_binds.conf
# ==============================================================================
$l_bind_type = $l_mods, $l_key, exec, qs ipc call dock toggleMenu
$m_bind_type = $m_mods, $m_key, exec, qs ipc call media toggle
$c_bind_type = $c_mods, $c_key, exec, qs ipc call clock toggle
$u_bind_type = $u_mods, $u_key, exec, qs ipc call utility toggle
EOF

  hyprctl reload >/dev/null 2>&1 &
}

check_status() {
  local source_ok="false"
  if [ -d "$HYPR_USER_DIR" ]; then
    if grep -Rqs "xeliushells/hypr/quickshell_binds.conf" "$HYPR_USER_DIR" 2>/dev/null; then
      source_ok="true"
    fi
  fi

  python3 - "$USER_CONFIG" "$source_ok" <<'PYEOF'
import json
import subprocess
import sys

config_path = sys.argv[1]
source_ok = sys.argv[2] == "true"

MOD_BITS = {
    "SHIFT": 1, "CAPS": 2, "CTRL": 4, "CONTROL": 4,
    "ALT": 8, "MOD2": 16, "MOD3": 32,
    "SUPER": 64, "WIN": 64, "LOGO": 64, "MOD4": 64, "MOD5": 128,
}

def mods_to_mask(mods_str):
    mask = 0
    for token in (mods_str or "").upper().replace("+", " ").split():
        mask = mask + MOD_BITS.get(token, 0)
    return mask

try:
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = json.load(f).get("keybinds", {})
except Exception:
    cfg = {}

defaults = {
    "launcher": {"mods": "SUPER", "key": "SUPER_L", "display": "WIN"},
    "media":    {"mods": "",      "key": "F6",      "display": "F6"},
    "clock":    {"mods": "",      "key": "F7",      "display": "F7"},
    "utility":  {"mods": "",      "key": "F8",      "display": "F8"},
}

conflicts = []
try:
    raw = subprocess.check_output(["hyprctl", "binds", "-j"], stderr=subprocess.DEVNULL).decode("utf-8")
    active_binds = json.loads(raw)
except Exception:
    active_binds = []

for action, d in defaults.items():
    entry = cfg.get(action, d)
    mods_str = entry.get("mods", d["mods"])
    key_str = (entry.get("key", d["key"]) or "").upper()
    disp_str = entry.get("display", d["display"])
    target_mask = mods_to_mask(mods_str)

    for b in active_binds:
        if b.get("submap", "") != "":
            continue
        b_key = (b.get("key") or "").upper()
        b_mask = int(b.get("modmask") or 0)
        b_arg = (b.get("arg") or "").strip()

        key_match = (b_key == key_str)
        mask_match = (b_mask == target_mask) or (key_str in ("SUPER_L", "SUPER_R") and b_mask in (0, 64))

        if key_match and mask_match:
            if "qs ipc call" not in b_arg and "quickshell" not in b_arg:
                dispatcher = b.get("dispatcher", "")
                conflicts.append(f"{disp_str} conflicts with '{dispatcher} {b_arg}'.strip()")

print(json.dumps({
    "sourceConfigured": source_ok,
    "conflicts": conflicts
}))
PYEOF
}

if [ "$1" = "--check" ]; then
  if [ ! -f "$HYPR_BINDS_OUT" ]; then
    generate_hypr_conf
  elif grep -q "^bind = " "$HYPR_BINDS_OUT" 2>/dev/null; then
    generate_hypr_conf
  fi
  check_status
else
  generate_hypr_conf
  check_status
fi
