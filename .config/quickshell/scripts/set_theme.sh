#!/usr/bin/env bash
# ~/dotfiles/quickshell/.config/quickshell/scripts/set_theme.sh

MODE_ARG="$1"

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

USER_CONFIG="$XDG_CONFIG/xeliushells/config.json"
THEME_STATE_DIR="$XDG_STATE/xeliushells/theme"
THEME_JSON="$THEME_STATE_DIR/theme.json"
LEGACY_CACHE_JSON="$HOME/.cache/quickshell_theme.json"

CACHE_JSON="$THEME_JSON"

mkdir -p "$THEME_STATE_DIR"

# 1. Migrate existing theme.json from ~/.cache if needed
if [ ! -f "$THEME_JSON" ] && [ -f "$LEGACY_CACHE_JSON" ]; then
  cp -f "$LEGACY_CACHE_JSON" "$THEME_JSON"
fi

# 2. Bootstrap default palette if theme.json doesn't exist yet
if [ ! -f "$THEME_JSON" ]; then
  cat <<EOF >"$THEME_JSON"
{
  "wallpaper": "$HOME/.config/quickshell/assets/wallpapers/1.png",
  "isDark": true,
  "wallIsDark": true,
  "dark": {
    "bgBase": "#413D38",
    "bgDark": "#34302c",
    "bgHover": "#4f4a44",
    "bgButton": "#413D38",
    "accent": "#C5BAA8",
    "hardwareRam": "#a39a8c",
    "hardwareGpu": "#797065",
    "textMain": "#dfdad2",
    "textMuted": "#9c9893",
    "border": "#dfdad2",
    "error": "#e06c75"
  },
  "light": {
    "bgBase": "#d8cebe",
    "bgDark": "#c7bba8",
    "bgHover": "#b5a792",
    "bgButton": "#cfc3b1",
    "accent": "#6d5e4c",
    "hardwareRam": "#7d6f5d",
    "hardwareGpu": "#8f8271",
    "textMain": "#2b2623",
    "textMuted": "#635c55",
    "border": "#6d5e4c",
    "error": "#c94f58"
  }
}
EOF
fi

# 3. Bootstrap harmless stub files ONLY if they don't exist yet on disk
if [ ! -f "$THEME_STATE_DIR/kitty.conf" ]; then
  echo "# XeLiuShells: Managed Kitty theme stub (initial state)" >"$THEME_STATE_DIR/kitty.conf"
fi

if [ ! -f "$THEME_STATE_DIR/hypr-colors.conf" ]; then
  echo "# XeLiuShells: Managed Hyprland theme stub (initial state)" >"$THEME_STATE_DIR/hypr-colors.conf"
fi

if [ ! -f "$THEME_STATE_DIR/nvim-palette.lua" ]; then
  cat <<'EOF' >"$THEME_STATE_DIR/nvim-palette.lua"
-- XeLiuShells: Managed Neovim theme stub (initial state)
return { enabled = false, apply_highlights = function() end }
EOF
fi

# Read boolean toggle from ~/.config/xeliushells/config.json -> .sync.<key>
get_sync_toggle() {
  local key="$1"
  local default_val="$2"
  if [ -f "$USER_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    local val
    val=$(jq -r "if (.sync != null and .sync.${key} != null) then .sync.${key} else \"${default_val}\" end" "$USER_CONFIG" 2>/dev/null)
    if [ -n "$val" ] && [ "$val" != "null" ]; then
      echo "$val"
      return
    fi
  fi
  echo "$default_val"
}

sync_external_themes() {
  local target_json="${1:-$CACHE_JSON}"

  if [ ! -f "$target_json" ]; then
    return
  fi

  local sync_kitty sync_hypr sync_glass sync_nvim sync_gtk
  sync_kitty=$(get_sync_toggle "syncKitty" "false")
  sync_hypr=$(get_sync_toggle "syncHyprland" "false")
  sync_glass=$(get_sync_toggle "syncGlassEffects" "false")
  sync_nvim=$(get_sync_toggle "syncNeovim" "false")
  sync_gtk=$(get_sync_toggle "syncGtk" "false")

  # Only write state files for apps whose sync toggle is currently TRUE.
  # When a toggle is FALSE, its state file is left untouched (freezing the last active palette).
  python3 - "$target_json" "$THEME_STATE_DIR" "$sync_kitty" "$sync_hypr" "$sync_glass" "$sync_nvim" <<'PYEOF'
import json
import os
import sys

json_path  = sys.argv[1]
state_dir  = sys.argv[2]
sync_kitty = (sys.argv[3] == "true")
sync_hypr  = (sys.argv[4] == "true")
sync_glass = (sys.argv[5] == "true")
sync_nvim  = (sys.argv[6] == "true")

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

is_dark = bool(data.get("isDark", True))
wall_is_dark = bool(data.get("wallIsDark", is_dark))

dark_p = data.get("dark", {})
light_p = data.get("light", dark_p)
p = dark_p if is_dark else light_p

bgBase    = p.get("bgBase", "#413D38")
bgDark    = p.get("bgDark", "#34302c")
bgHover   = p.get("bgHover", "#4f4a44")
bgButton  = p.get("bgButton", "#413D38")
accent    = p.get("accent", "#C5BAA8")
ram       = p.get("hardwareRam", "#a39a8c")
gpu       = p.get("hardwareGpu", "#797065")
textMain  = p.get("textMain", "#dfdad2")
textMuted = p.get("textMuted", "#9c9893")
border    = p.get("border", "#dfdad2")
error     = p.get("error", "#e06c75")

kitty_opacity = "0.4"
term_bg       = bgBase
term_fg       = textMain
term_muted    = textMuted
term_accent   = accent
term_ram      = ram
term_gpu      = gpu
on_accent     = bgDark
tab_bar_bg    = bgDark
shadow_hex    = accent.lstrip("#")

if not is_dark:
    on_accent = bgBase
    if wall_is_dark:
        kitty_opacity = "0.12"
        term_bg       = bgBase
        term_fg       = dark_p.get("textMain", textMain)
        term_muted    = dark_p.get("textMuted", textMuted)
        term_accent   = bgBase
        term_ram      = bgButton
        term_gpu      = dark_p.get("accent", accent)
        on_accent     = textMain
        tab_bar_bg    = dark_p.get("bgDark", bgDark)
        shadow_hex    = bgBase.lstrip("#")

opacity_line = f"background_opacity    {kitty_opacity}\n" if sync_glass else ""

# 1. Update ~/.local/state/xeliushells/theme/kitty.conf ONLY if syncKitty is true
if sync_kitty:
    kitty_conf = f"""# Auto-generated by XeLiuShells (Do not edit manually)
# Add to ~/.config/kitty/kitty.conf (below your own includes):
#   include ~/.local/state/xeliushells/theme/kitty.conf
{opacity_line}foreground            {term_fg}
background            {term_bg}
cursor                {term_accent}
cursor_text_color     {on_accent}

selection_foreground  {on_accent}
selection_background  {term_accent}

active_border_color   {term_accent}
inactive_border_color {bgHover}

active_tab_foreground   {on_accent}
active_tab_background   {term_accent}
inactive_tab_foreground {term_fg}
inactive_tab_background {tab_bar_bg}
tab_bar_background      {tab_bar_bg}
tab_bar_margin_color    {tab_bar_bg}

color0                {on_accent}
color8                {term_muted}
color1                {term_accent}
color9                {term_gpu}
color2                {term_fg}
color10               {term_ram}
color3                {term_gpu}
color11               {term_gpu}
color4                {term_accent}
color12               {term_ram}
color5                {term_ram}
color13               {term_ram}
color6                {term_accent}
color14               {term_accent}
color7                {term_fg}
color15               {term_fg}
"""
    with open(os.path.join(state_dir, "kitty.conf"), "w", encoding="utf-8") as f:
        f.write(kitty_conf)

# 2. Update ~/.local/state/xeliushells/theme/hypr-colors.conf ONLY if syncHyprland is true
def sh(c):
    return c.lstrip("#")

if sync_hypr:
    blur_size = "6" if (not is_dark and wall_is_dark) else "2"
    glass_block = ""
    if sync_glass:
        glass_block = f"""
decoration {{
    inactive_opacity = 0.4
    blur {{
        enabled = true
        size = {blur_size}
        passes = 5
    }}
}}
"""
    hypr_conf = f"""# Auto-generated by XeLiuShells (Do not edit manually)
# Add to the bottom of ~/.config/hypr/hyprland.conf:
#   source = ~/.local/state/xeliushells/theme/hypr-colors.conf

$qs_active_border   = rgba({shadow_hex}ee)
$qs_inactive_border = rgba({sh(bgDark)}ee)
$qs_shadow_color    = rgba({shadow_hex}ee)

general {{
    col.active_border = $qs_active_border
    col.inactive_border = $qs_inactive_border
}}

decoration {{
    shadow {{
        color = $qs_shadow_color
    }}
}}
{glass_block}"""
    with open(os.path.join(state_dir, "hypr-colors.conf"), "w", encoding="utf-8") as f:
        f.write(hypr_conf)

# 3. Update ~/.local/state/xeliushells/theme/nvim-palette.lua ONLY if syncNeovim is true
use_dark_fg = is_dark or wall_is_dark
fg_p = dark_p if use_dark_fg else light_p
on_pill = bgDark if is_dark else bgBase

if sync_nvim:
    nvim_lua = f"""-- Auto-generated by XeLiuShells (Do not edit manually)
local M = {{
  enabled = true,
  isDark = {str(is_dark).lower()},
  wallIsDark = {str(wall_is_dark).lower()},
  useDarkFg = {str(use_dark_fg).lower()},
  palette = {{
    bgBase = "{bgBase}",
    bgDark = "{bgDark}",
    bgHover = "{bgHover}",
    bgButton = "{bgButton}",
    onPill = "{on_pill}",
    accent = "{fg_p.get('accent', accent)}",
    textMain = "{fg_p.get('textMain', textMain)}",
    textMuted = "{fg_p.get('textMuted', textMuted)}",
    border = "{border}",
    error = "{error}",
    hardwareRam = "{fg_p.get('hardwareRam', ram)}",
    hardwareGpu = "{fg_p.get('hardwareGpu', gpu)}",
  }}
}}

function M.apply_highlights()
  if not M.enabled then return end
  local p = M.palette
  local set_hl = vim.api.nvim_set_hl
  set_hl(0, "Normal", {{ bg = "NONE" }})
  set_hl(0, "NormalNC", {{ bg = "NONE" }})
  set_hl(0, "NormalFloat", {{ bg = "NONE" }})
  set_hl(0, "SignColumn", {{ bg = "NONE" }})
  set_hl(0, "EndOfBuffer", {{ bg = "NONE" }})
  set_hl(0, "FloatBorder", {{ fg = p.accent, bg = "NONE" }})
  set_hl(0, "WinSeparator", {{ fg = p.bgHover, bg = "NONE" }})
  set_hl(0, "VertSplit", {{ fg = p.bgHover, bg = "NONE" }})
  set_hl(0, "CursorLineNr", {{ fg = p.accent, bold = true, bg = "NONE" }})
  set_hl(0, "LineNr", {{ fg = p.textMuted, bg = "NONE" }})
  set_hl(0, "Visual", {{ fg = p.bgDark, bg = p.accent }})
  set_hl(0, "Search", {{ fg = p.bgDark, bg = p.hardwareRam, bold = true }})
  set_hl(0, "IncSearch", {{ fg = p.bgDark, bg = p.accent, bold = true }})
  set_hl(0, "Directory", {{ fg = p.accent, bold = true }})
  set_hl(0, "Title", {{ fg = p.accent, bold = true }})
  set_hl(0, "Special", {{ fg = p.hardwareRam }})
  set_hl(0, "Identifier", {{ fg = p.textMain }})
  set_hl(0, "Function", {{ fg = p.accent, bold = true }})
  set_hl(0, "Statement", {{ fg = p.hardwareRam, bold = true }})
  set_hl(0, "Type", {{ fg = p.hardwareGpu, bold = true }})
  set_hl(0, "SnacksDashboardHeader", {{ fg = p.accent, bold = true }})
  set_hl(0, "SnacksDashboardIcon", {{ fg = p.accent }})
  set_hl(0, "SnacksDashboardDesc", {{ fg = p.textMain }})
  set_hl(0, "SnacksDashboardKey", {{ fg = p.hardwareRam, bold = true }})
  set_hl(0, "SnacksDashboardFooter", {{ fg = p.hardwareGpu, italic = true }})
  set_hl(0, "SnacksDashboardSpecial", {{ fg = p.accent, bold = true }})
end

function M.lualine_theme()
  local p = M.palette
  return {{
    normal = {{
      a = {{ fg = p.onPill, bg = p.accent, gui = "bold" }},
      b = {{ fg = p.onPill, bg = p.hardwareGpu }},
      c = {{ fg = p.accent, bg = p.bgHover }},
    }},
    insert  = {{ a = {{ fg = p.onPill, bg = p.hardwareRam, gui = "bold" }} }},
    visual  = {{ a = {{ fg = p.onPill, bg = p.hardwareGpu, gui = "bold" }} }},
    replace = {{ a = {{ fg = p.onPill, bg = p.error, gui = "bold" }} }},
    inactive = {{
      a = {{ fg = p.accent, bg = p.bgDark }},
      b = {{ fg = p.accent, bg = p.bgDark }},
      c = {{ fg = p.accent, bg = p.bgDark }},
    }},
  }}
end

return M
"""
    with open(os.path.join(state_dir, "nvim-palette.lua"), "w", encoding="utf-8") as f:
        f.write(nvim_lua)
PYEOF

  local is_dark wall_is_dark
  is_dark=$(jq -r '.isDark' "$target_json" 2>/dev/null)
  wall_is_dark=$(jq -r 'if .wallIsDark == null then .isDark else .wallIsDark end' "$target_json" 2>/dev/null)

  local mode_key="dark"
  if [ "$is_dark" = "false" ]; then
    mode_key="light"
  fi

  local bgBase bgDark accent
  bgBase=$(jq -r ".${mode_key}.bgBase" "$target_json" 2>/dev/null)
  bgDark=$(jq -r ".${mode_key}.bgDark" "$target_json" 2>/dev/null)
  accent=$(jq -r ".${mode_key}.accent" "$target_json" 2>/dev/null)

  local bgDark_hex="${bgDark#\#}"
  local shadow_hex="${accent#\#}"
  local blur_size="2"
  local blur_passes="5"

  if [ "$is_dark" = "false" ] && [ "$wall_is_dark" = "true" ]; then
    shadow_hex="${bgBase#\#}"
    blur_size="6"
    blur_passes="5"
  fi

  # 1. Reload Kitty ONLY if syncKitty is enabled
  if [ "$sync_kitty" = "true" ]; then
    killall -USR1 kitty >/dev/null 2>&1 &
  fi

  # 2. Apply Hyprland colors/glass ONLY if syncHyprland is enabled
  if [ "$sync_hypr" = "true" ] && [ -n "$shadow_hex" ] && [ "$shadow_hex" != "null" ]; then
    if [ "$sync_glass" = "true" ]; then
      hyprctl --batch "keyword general:col.active_border rgba(${shadow_hex}ee); keyword general:col.inactive_border rgba(${bgDark_hex}ee); keyword decoration:shadow:color rgba(${shadow_hex}ee); keyword decoration:inactive_opacity 0.4; keyword decoration:blur:size $blur_size; keyword decoration:blur:passes $blur_passes" >/dev/null 2>&1 &
    else
      hyprctl --batch "keyword general:col.active_border rgba(${shadow_hex}ee); keyword general:col.inactive_border rgba(${bgDark_hex}ee); keyword decoration:shadow:color rgba(${shadow_hex}ee)" >/dev/null 2>&1 &
    fi
  fi

  # 3. Sync GTK Dark/Light preference ONLY if syncGtk is enabled
  if [ "$sync_gtk" = "true" ]; then
    if [ "$is_dark" = "false" ]; then
      gsettings set org.gnome.desktop.interface color-scheme 'default' >/dev/null 2>&1 &
    else
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 &
    fi
  fi

  # 4. Optional user post-theme hook script
  if [ -x "$XDG_CONFIG/xeliushells/post_theme_hook.sh" ]; then
    "$XDG_CONFIG/xeliushells/post_theme_hook.sh" "$target_json" >/dev/null 2>&1 &
  fi
}

# --- MODE 0: Explicit Reset of External State Files (--reset-sync) ---
if [ "$MODE_ARG" = "--reset-sync" ]; then
  echo "# XeLiuShells: Reset to clean stub" >"$THEME_STATE_DIR/kitty.conf"
  echo "# XeLiuShells: Reset to clean stub" >"$THEME_STATE_DIR/hypr-colors.conf"
  cat <<'EOF' >"$THEME_STATE_DIR/nvim-palette.lua"
-- XeLiuShells: Reset to clean stub
return { enabled = false, apply_highlights = function() end }
EOF
  killall -USR1 kitty >/dev/null 2>&1 &
  hyprctl reload >/dev/null 2>&1 &
  exit 0
fi

# --- MODE A: Polarity Toggle Only (--sync-only <true|false>) ---
if [ "$MODE_ARG" = "--sync-only" ]; then
  NEW_DARK="${2:-true}"
  if [ -f "$CACHE_JSON" ]; then
    TMP_JSON=$(mktemp)
    jq --argjson d "$NEW_DARK" '.isDark = $d' "$CACHE_JSON" >"$TMP_JSON" && mv "$TMP_JSON" "$CACHE_JSON"
    sync_external_themes "$CACHE_JSON"
    cat "$CACHE_JSON"
  fi
  exit 0
fi

# --- MODE B: Full Wallpaper & Palette Generation ---
WALL="$MODE_ARG"
if [ -z "$WALL" ]; then
  exit 1
fi
if [ ! -f "$WALL" ]; then
  exit 1
fi

# 1. Fire the 60fps awww wallpaper transition immediately in the background
awww img "$WALL" \
  --transition-type grow \
  --transition-pos 0.5,0.5 \
  --transition-fps 60 \
  --transition-duration 1.5 >/dev/null 2>&1 &

FILENAME=$(basename "$WALL")

# 2. If 1.png is selected, restore the original handcrafted Caelestia coffee palette
if [ "$FILENAME" = "1.png" ]; then
  cat <<EOF >"$CACHE_JSON"
{
  "wallpaper": "$WALL",
  "isDark": true,
  "wallIsDark": true,
  "dark": {
    "bgBase": "#413D38",
    "bgDark": "#34302c",
    "bgHover": "#4f4a44",
    "bgButton": "#413D38",
    "accent": "#C5BAA8",
    "hardwareRam": "#a39a8c",
    "hardwareGpu": "#797065",
    "textMain": "#dfdad2",
    "textMuted": "#9c9893",
    "border": "#dfdad2",
    "error": "#e06c75"
  },
  "light": {
    "bgBase": "#d8cebe",
    "bgDark": "#c7bba8",
    "bgHover": "#b5a792",
    "bgButton": "#cfc3b1",
    "accent": "#6d5e4c",
    "hardwareRam": "#7d6f5d",
    "hardwareGpu": "#8f8271",
    "textMain": "#2b2623",
    "textMuted": "#635c55",
    "border": "#6d5e4c",
    "error": "#c94f58"
  }
}
EOF
  sync_external_themes "$CACHE_JSON"
  cat "$CACHE_JSON"
  exit 0
fi

# 3. Analyze the wallpaper pixels and build HSL-calibrated Dark & Light palettes
TMP_TXT=$(mktemp)
magick "$WALL" -resize 64x64\! -depth 8 "txt:$TMP_TXT" 2>/dev/null

awk -v wall="$WALL" '
function hex2dec(h,    i, c, val, pos) {
    val = 0
    h = tolower(h)
    for (i = 1; i <= length(h); i++) {
        c = substr(h, i, 1)
        pos = index("0123456789abcdef", c) - 1
        if (pos >= 0) val = val * 16 + pos
    }
    return val
}
function clamp(v, lo, hi) {
    return (v < lo) ? lo : ((v > hi) ? hi : v)
}
function hue2rgb(p, q, t) {
    if (t < 0) t += 1.0
    if (t > 1) t -= 1.0
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t
    if (t < 1.0 / 2.0) return q
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0
    return p
}
function hslToHex(h, s, l,    q, p, hk, r, g, b) {
    while (h < 0) h += 360.0
    while (h >= 360.0) h -= 360.0
    s = clamp(s, 0.0, 1.0)
    l = clamp(l, 0.0, 1.0)
    if (s == 0) {
        r = l; g = l; b = l
    } else {
        q = (l < 0.5) ? (l * (1.0 + s)) : (l + s - l * s)
        p = 2.0 * l - q
        hk = h / 360.0
        r = hue2rgb(p, q, hk + 1.0 / 3.0)
        g = hue2rgb(p, q, hk)
        b = hue2rgb(p, q, hk - 1.0 / 3.0)
    }
    return sprintf("#%02x%02x%02x", int(r * 255 + 0.5), int(g * 255 + 0.5), int(b * 255 + 0.5))
}

NR > 1 {
    if (match($0, /#[0-9A-Fa-f]{6}/)) {
        hex = substr($0, RSTART, 7)
        r = hex2dec(substr(hex, 2, 2)) / 255.0
        g = hex2dec(substr(hex, 4, 2)) / 255.0
        b = hex2dec(substr(hex, 6, 2)) / 255.0

        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        sum_lum += lum
        total_px++

        max = r; if (g > max) max = g; if (b > max) max = b
        min = r; if (g < min) min = g; if (b < min) min = b
        d = max - min
        l = (max + min) / 2.0
        s = (d == 0) ? 0 : d / (1.0 - ((2.0 * l - 1.0 >= 0) ? (2.0 * l - 1.0) : -(2.0 * l - 1.0)))

        if (d > 0.04 && l > 0.06 && l < 0.94) {
            if (max == r) {
                h = 60.0 * (((g - b) / d) % 6.0)
            } else if (max == g) {
                h = 60.0 * (((b - r) / d) + 2.0)
            } else {
                h = 60.0 * (((r - g) / d) + 4.0)
            }
            if (h < 0) h += 360.0

            bin = int(h / 10.0) % 36
            w = (d * d * 8.0 + s * 1.5) * (1.0 - 0.7 * (l - 0.5) * (l - 0.5))
            bin_weight[bin] += w
            bin_h_sum[bin] += h * w
            bin_s_sum[bin] += s * w
        }
    }
}

END {
    mean_lum = (total_px > 0) ? (sum_lum / total_px) : 0.2
    is_dark = (mean_lum > 0.58) ? "false" : "true"

    best_bin = -1
    best_w = -1
    for (b = 0; b < 36; b++) {
        prev_b = (b + 35) % 36
        next_b = (b + 1) % 36
        score = bin_weight[b] + 0.35 * (bin_weight[prev_b] + bin_weight[next_b])
        if (score > best_w && bin_weight[b] > 0) {
            best_w = score
            best_bin = b
        }
    }

    if (best_bin >= 0 && bin_weight[best_bin] > 0) {
        H = bin_h_sum[best_bin] / bin_weight[best_bin]
        S = bin_s_sum[best_bin] / bin_weight[best_bin]
    } else {
        H = 35.0
        S = 0.25
    }

    s_dark_surf = clamp(S * 0.90, 0.35, 0.55)
    s_dark_acc  = clamp(S * 1.25, 0.60, 0.85)

    d_bgDark   = hslToHex(H, s_dark_surf, 0.11)
    d_bgBase   = hslToHex(H, s_dark_surf, 0.18)
    d_bgButton = hslToHex(H, s_dark_surf * 0.95, 0.26)
    d_bgHover  = hslToHex(H, s_dark_surf * 1.05, 0.35)
    d_accent   = hslToHex(H, s_dark_acc, 0.72)
    d_ram      = hslToHex(H + 18.0, clamp(s_dark_acc * 0.85, 0.45, 0.75), 0.62)
    d_gpu      = hslToHex(H - 22.0, clamp(s_dark_acc * 0.75, 0.35, 0.65), 0.52)
    d_textMain = hslToHex(H, 0.25, 0.93)
    d_textMute = hslToHex(H, 0.32, 0.74)
    d_border   = hslToHex(H, clamp(s_dark_acc * 0.80, 0.40, 0.70), 0.64)

    s_light_surf = clamp(S * 0.85, 0.34, 0.56)
    s_light_acc  = clamp(S * 1.20, 0.52, 0.82)

    l_bgBase   = hslToHex(H, s_light_surf, 0.77)
    l_bgDark   = hslToHex(H, s_light_surf, 0.68)
    l_bgButton = hslToHex(H, s_light_surf, 0.73)
    l_bgHover  = hslToHex(H, s_light_surf * 1.10, 0.61)
    l_accent   = hslToHex(H, s_light_acc, 0.34)
    l_ram      = hslToHex(H + 18.0, clamp(s_light_acc * 0.85, 0.42, 0.72), 0.42)
    l_gpu      = hslToHex(H - 22.0, clamp(s_light_acc * 0.75, 0.32, 0.62), 0.48)
    l_textMain = hslToHex(H, 0.38, 0.14)
    l_textMute = hslToHex(H, 0.30, 0.32)
    l_border   = hslToHex(H, clamp(s_light_acc * 0.85, 0.42, 0.72), 0.38)

    printf "{\"wallpaper\":\"%s\",\"isDark\":%s,\"wallIsDark\":%s,", wall, is_dark, is_dark
    printf "\"dark\":{\"bgBase\":\"%s\",\"bgDark\":\"%s\",\"bgHover\":\"%s\",\"bgButton\":\"%s\",\"accent\":\"%s\",\"hardwareRam\":\"%s\",\"hardwareGpu\":\"%s\",\"textMain\":\"%s\",\"textMuted\":\"%s\",\"border\":\"%s\",\"error\":\"#e06c75\"},", d_bgBase, d_bgDark, d_bgHover, d_bgButton, d_accent, d_ram, d_gpu, d_textMain, d_textMute, d_border
    printf "\"light\":{\"bgBase\":\"%s\",\"bgDark\":\"%s\",\"bgHover\":\"%s\",\"bgButton\":\"%s\",\"accent\":\"%s\",\"hardwareRam\":\"%s\",\"hardwareGpu\":\"%s\",\"textMain\":\"%s\",\"textMuted\":\"%s\",\"border\":\"%s\",\"error\":\"#c94f58\"}}\n", l_bgBase, l_bgDark, l_bgHover, l_bgButton, l_accent, l_ram, l_gpu, l_textMain, l_textMute, l_border
}
' "$TMP_TXT" >"$CACHE_JSON"
rm -f "$TMP_TXT"

# 4. Sync external state files (only updating apps whose sync toggle is true)
sync_external_themes "$CACHE_JSON"

# 5. Output JSON to stdout so Quickshell updates immediately
cat "$CACHE_JSON"
