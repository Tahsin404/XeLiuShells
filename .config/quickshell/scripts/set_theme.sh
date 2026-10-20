#!/usr/bin/env bash
# ~/.config/quickshell/scripts/set_theme.sh

MODE_ARG="$1"
CACHE_JSON="$HOME/.cache/quickshell_theme.json"
USER_CONFIG="$HOME/.config/quickshell/config.json"

# Dedicated Quickshell-owned theme state directory (Caelestia-style)
THEME_OUT_DIR="$HOME/.cache/quickshell/theme"
mkdir -p "$THEME_OUT_DIR"

KITTY_COLORS="$HOME/.config/kitty/colors-kitty.conf"
HYPR_COLORS="$HOME/.config/hypr/conf/colors.conf"

# Helper: Read boolean toggle from ~/.config/quickshell/config.json (defaults to true)
get_toggle() {
  local key="$1"
  local default_val="${2:-true}"
  if [ -f "$USER_CONFIG" ] && command -v jq >/dev/null 2>&1; then
    local val
    val=$(jq -r "if .theming.${key} != null then .theming.${key} elif .${key} != null then .${key} else \"${default_val}\" end" "$USER_CONFIG" 2>/dev/null)
    echo "$val"
  else
    echo "$default_val"
  fi
}

# Helper function: Reads $CACHE_JSON and syncs Kitty, Ranger, Hyprland, GTK, and Neovim
sync_external_themes() {
  if [ ! -f "$CACHE_JSON" ] || ! command -v jq >/dev/null 2>&1; then
    return
  fi

  local is_dark wall_is_dark
  is_dark=$(jq -r '.isDark' "$CACHE_JSON" 2>/dev/null)
  wall_is_dark=$(jq -r 'if .wallIsDark == null then .isDark else .wallIsDark end' "$CACHE_JSON" 2>/dev/null)

  local mode_key="dark"
  if [ "$is_dark" = "false" ]; then
    mode_key="light"
  fi

  # Read per-app toggles (all default to true)
  local sync_kitty sync_hypr sync_glass sync_gtk sync_nvim
  sync_kitty=$(get_toggle "syncKitty" "true")
  sync_hypr=$(get_toggle "syncHyprland" "true")
  sync_glass=$(get_toggle "syncGlassEffects" "true")
  sync_gtk=$(get_toggle "syncGtk" "true")
  sync_nvim=$(get_toggle "syncNeovim" "true")

  # Pull active mode colors
  local bgBase bgDark bgHover bgButton accent ram gpu textMain textMuted border error
  bgBase=$(jq -r ".${mode_key}.bgBase" "$CACHE_JSON")
  bgDark=$(jq -r ".${mode_key}.bgDark" "$CACHE_JSON")
  bgHover=$(jq -r ".${mode_key}.bgHover" "$CACHE_JSON")
  bgButton=$(jq -r ".${mode_key}.bgButton" "$CACHE_JSON")
  accent=$(jq -r ".${mode_key}.accent" "$CACHE_JSON")
  ram=$(jq -r ".${mode_key}.hardwareRam" "$CACHE_JSON")
  gpu=$(jq -r ".${mode_key}.hardwareGpu" "$CACHE_JSON")
  textMain=$(jq -r ".${mode_key}.textMain" "$CACHE_JSON")
  textMuted=$(jq -r ".${mode_key}.textMuted" "$CACHE_JSON")
  border=$(jq -r ".${mode_key}.border" "$CACHE_JSON")
  error=$(jq -r ".${mode_key}.error" "$CACHE_JSON")

  local kitty_opacity="0.4"
  local blur_size="2"
  local blur_passes="5"

  local term_bg="$bgBase"
  local term_fg="$textMain"
  local term_muted="$textMuted"
  local term_accent="$accent"
  local term_ram="$ram"
  local term_gpu="$gpu"
  local on_accent="$bgDark"
  local tab_bar_bg="$bgDark"
  local shadow_hex="${accent#\#}"

  if [ "$is_dark" = "false" ]; then
    on_accent="$bgBase"

    if [ "$wall_is_dark" = "true" ]; then
      kitty_opacity="0.12"
      blur_size="6"
      blur_passes="5"

      term_bg="$bgBase"
      term_fg=$(jq -r ".dark.textMain" "$CACHE_JSON")
      term_muted=$(jq -r ".dark.textMuted" "$CACHE_JSON")
      term_accent="$bgBase"
      term_ram="$bgButton"
      term_gpu=$(jq -r ".dark.accent" "$CACHE_JSON")
      on_accent="$textMain"
      tab_bar_bg=$(jq -r ".dark.bgDark" "$CACHE_JSON")
      shadow_hex="${bgBase#\#}"
    fi
  fi

  local bgBase_hex="${bgBase#\#}"
  local bgDark_hex="${bgDark#\#}"
  local accent_hex="${accent#\#}"
  local ram_hex="${ram#\#}"
  local gpu_hex="${gpu#\#}"
  local textMain_hex="${textMain#\#}"
  local textMuted_hex="${textMuted#\#}"

  # 1. Generate Kitty & Ranger theme in ~/.cache/quickshell/theme/kitty.conf
  local opacity_line=""
  if [ "$sync_glass" = "true" ]; then
    opacity_line="background_opacity    $kitty_opacity"
  fi

  cat <<EOF >"$THEME_OUT_DIR/kitty.conf"
$opacity_line
foreground            $term_fg
background            $term_bg
cursor                $term_accent
cursor_text_color     $on_accent

selection_foreground  $on_accent
selection_background  $term_accent

active_border_color   $term_accent
inactive_border_color $bgHover

active_tab_foreground   $on_accent
active_tab_background   $term_accent
inactive_tab_foreground $term_fg
inactive_tab_background $tab_bar_bg
tab_bar_background      $tab_bar_bg
tab_bar_margin_color    $tab_bar_bg

color0                $on_accent
color8                $term_muted
color1                $term_accent
color9                $term_gpu
color2                $term_fg
color10               $term_ram
color3                $term_gpu
color11               $term_gpu
color4                $term_accent
color12               $term_ram
color5                $term_ram
color13               $term_ram
color6                $term_accent
color14               $term_accent
color7                $term_fg
color15               $term_fg
EOF

  if [ "$sync_kitty" = "true" ]; then
    if [ -d "$(dirname "$KITTY_COLORS")" ]; then
      cp "$THEME_OUT_DIR/kitty.conf" "$KITTY_COLORS"
    fi
    killall -USR1 kitty >/dev/null 2>&1 &
  fi

  # 2. Generate Hyprland colors in ~/.cache/quickshell/theme/hypr-colors.conf
  cat <<EOF >"$THEME_OUT_DIR/hypr-colors.conf"
# DYNAMICALLY GENERATED BY QUICKSHELL (set_theme.sh)

\$foreground = rgb($textMain_hex)
\$background = rgb($bgBase_hex)
\$cursor     = rgb($gpu_hex)

\$color0  = rgb($bgDark_hex)
\$color1  = rgb($textMain_hex)
\$color2  = rgb($textMain_hex)
\$color3  = rgb($gpu_hex)
\$color4  = rgb($textMain_hex)
\$color5  = rgb($ram_hex)
\$color6  = rgb($accent_hex)
\$color7  = rgb($textMain_hex)
\$color8  = rgb($textMuted_hex)
\$color9  = rgb($gpu_hex)
\$color10 = rgb($ram_hex)
\$color11 = rgb($gpu_hex)
\$color12 = rgb($ram_hex)
\$color13 = rgb($ram_hex)
\$color14 = rgb($accent_hex)
\$color15 = rgb($textMain_hex)

\$active_border   = rgba(${shadow_hex}ee)
\$inactive_border = rgba(${bgDark_hex}ee)
\$shadow_color    = rgba(${shadow_hex}ee)
EOF

  if [ "$sync_hypr" = "true" ] && [ -n "$shadow_hex" ] && [ "$shadow_hex" != "null" ]; then
    if [ -d "$(dirname "$HYPR_COLORS")" ]; then
      cp "$THEME_OUT_DIR/hypr-colors.conf" "$HYPR_COLORS"
    fi
    if [ "$sync_glass" = "true" ]; then
      hyprctl --batch "keyword general:col.active_border rgba(${shadow_hex}ee); keyword general:col.inactive_border rgba(${bgDark_hex}ee); keyword decoration:shadow:color rgba(${shadow_hex}ee); keyword decoration:inactive_opacity 0.4; keyword decoration:blur:size $blur_size; keyword decoration:blur:passes $blur_passes" >/dev/null 2>&1 &
    else
      hyprctl --batch "keyword general:col.active_border rgba(${shadow_hex}ee); keyword general:col.inactive_border rgba(${bgDark_hex}ee); keyword decoration:shadow:color rgba(${shadow_hex}ee)" >/dev/null 2>&1 &
    fi
  fi

  # 3. Sync GTK Dark/Light preference
  if [ "$sync_gtk" = "true" ]; then
    if [ "$is_dark" = "false" ]; then
      gsettings set org.gnome.desktop.interface color-scheme 'default' >/dev/null 2>&1 &
    else
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 &
    fi
  fi

  # 4. Safe Neovim live reload: Only send SIGUSR1 if the user's Neovim config handles SIGUSR1!
  if [ "$sync_nvim" = "true" ] && grep -rq "SIGUSR1" "$HOME/.config/nvim" 2>/dev/null; then
    pkill -USR1 -x nvim >/dev/null 2>&1 &
  fi

  # 5. Optional user post-theme hook script
  if [ -x "$HOME/.config/quickshell/scripts/post_theme_hook.sh" ]; then
    "$HOME/.config/quickshell/scripts/post_theme_hook.sh" "$CACHE_JSON" >/dev/null 2>&1 &
  fi
}

# --- MODE A: Polarity Toggle Only (--sync-only <true|false>) ---
if [ "$MODE_ARG" = "--sync-only" ]; then
  NEW_DARK="${2:-true}"
  if [ -f "$CACHE_JSON" ]; then
    TMP_JSON=$(mktemp)
    jq --argjson d "$NEW_DARK" '.isDark = $d' "$CACHE_JSON" >"$TMP_JSON" && mv "$TMP_JSON" "$CACHE_JSON"
    sync_external_themes
    cat "$CACHE_JSON"
  fi
  exit 0
fi

# --- MODE B: Full Wallpaper & Palette Generation ---
WALL="$MODE_ARG"
if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
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
  sync_external_themes
  cat "$CACHE_JSON"
  exit 0
fi

# 3. Analyze the wallpaper pixels and build HSL-calibrated Dark & Light palettes directly in awk
magick "$WALL" -resize 64x64\! -depth 8 txt:- 2>/dev/null | awk -v wall="$WALL" '
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
' >"$CACHE_JSON"

# 4. Sync Kitty, Ranger, Hyprland, GTK, and Neovim
sync_external_themes

# 5. Output JSON to stdout so Quickshell updates immediately
cat "$CACHE_JSON"
