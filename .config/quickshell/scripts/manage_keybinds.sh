#!/usr/bin/env bash
# ~/.config/quickshell/scripts/manage_keybinds.sh
# Reads, updates, or resets Quickshell Hyprland keybinds and hot-reloads Hyprland

CONF_DIR="$HOME/.config/quickshell"
JSON_FILE="$CONF_DIR/keybinds.json"
HYPR_BINDS_OUT="$CONF_DIR/quickshell_binds.conf"
MAIN_HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
USER_KEYBINDS_CONF="$HOME/.config/hypr/conf/keybinds.conf"

mkdir -p "$CONF_DIR"

write_defaults() {
  cat <<'EOF' >"$JSON_FILE"
{
  "launcher": { "mods": "SUPER", "key": "SUPER_L", "display": "WIN" },
  "media":    { "mods": "",      "key": "F6",      "display": "F6"  },
  "clock":    { "mods": "",      "key": "F7",      "display": "F7"  },
  "utility":  { "mods": "",      "key": "F8",      "display": "F8"  }
}
EOF
}

if [ ! -f "$JSON_FILE" ]; then
  write_defaults
fi

generate_hypr_conf() {
  if ! command -v jq >/dev/null 2>&1; then
    return
  fi

  local l_mods l_key m_mods m_key c_mods c_key u_mods u_key
  l_mods=$(jq -r '.launcher.mods // "SUPER"' "$JSON_FILE")
  l_key=$(jq -r '.launcher.key // "SUPER_L"' "$JSON_FILE")
  m_mods=$(jq -r '.media.mods // ""' "$JSON_FILE")
  m_key=$(jq -r '.media.key // "F6"' "$JSON_FILE")
  c_mods=$(jq -r '.clock.mods // ""' "$JSON_FILE")
  c_key=$(jq -r '.clock.key // "F7"' "$JSON_FILE")
  u_mods=$(jq -r '.utility.mods // ""' "$JSON_FILE")
  u_key=$(jq -r '.utility.key // "F8"' "$JSON_FILE")

  local l_bind_type="bind"
  if [[ "$l_key" == "SUPER_L" || "$l_key" == "SUPER_R" ]]; then
    l_bind_type="bindr"
  fi

  cat <<EOF >"$HYPR_BINDS_OUT"
# ==============================================================================
# QUICKSHELL MANAGED KEYBINDS (Auto-generated via '> keybinds' in Launcher)
# ==============================================================================
$l_bind_type = $l_mods, $l_key, exec, qs ipc call dock toggleMenu
bind = $m_mods, $m_key, exec, qs ipc call media toggle
bind = $c_mods, $c_key, exec, qs ipc call clock toggle
bind = $u_mods, $u_key, exec, qs ipc call utility toggle
EOF

  # Comment out old hardcoded 'qs ipc call' lines in ~/.config/hypr/conf/keybinds.conf so they don't clash
  if [ -f "$USER_KEYBINDS_CONF" ]; then
    sed -i 's/^[[:space:]]*bind[r]*[[:space:]]*=.*qs ipc call/# [Managed by Quickshell] &/' "$USER_KEYBINDS_CONF" 2>/dev/null
  fi

  # Ensure ~/.config/hypr/hyprland.conf sources quickshell_binds.conf once
  if [ -f "$MAIN_HYPR_CONF" ]; then
    if ! grep -q "quickshell_binds.conf" "$MAIN_HYPR_CONF" 2>/dev/null; then
      printf "\n# Quickshell Managed Keybinds\nsource = ~/.config/quickshell/quickshell_binds.conf\n" >>"$MAIN_HYPR_CONF"
    fi
  fi

  hyprctl reload >/dev/null 2>&1 &
}

case "$1" in
--get)
  if [ ! -f "$HYPR_BINDS_OUT" ]; then
    generate_hypr_conf
  fi
  cat "$JSON_FILE"
  ;;
--reset)
  write_defaults
  generate_hypr_conf
  cat "$JSON_FILE"
  ;;
--set)
  TARGET="$2"
  MODS="$3"
  KEY="$4"
  DISPLAY_STR="$5"
  if [ -n "$TARGET" ] && [ -n "$KEY" ] && command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg t "$TARGET" --arg m "$MODS" --arg k "$KEY" --arg d "$DISPLAY_STR" \
      '.[$t] = {"mods": $m, "key": $k, "display": $d}' "$JSON_FILE" >"$tmp" && mv "$tmp" "$JSON_FILE"
    generate_hypr_conf
  fi
  cat "$JSON_FILE"
  ;;
*)
  cat "$JSON_FILE"
  ;;
esac
