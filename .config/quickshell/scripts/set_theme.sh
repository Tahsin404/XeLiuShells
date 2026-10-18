#!/usr/bin/env bash
# ~/.config/quickshell/scripts/set_theme.sh

WALL="$1"
CACHE_JSON="$HOME/.cache/quickshell_theme.json"

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

# 2. If 1.png is selected, restore the original handcrafted Caelestia palette
if [ "$FILENAME" = "1.png" ]; then
  cat <<EOF >"$CACHE_JSON"
{
  "wallpaper": "$WALL",
  "isDark": true,
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
    "bgBase": "#e6e0d6",
    "bgDark": "#d8d0c5",
    "bgHover": "#c8bfb2",
    "bgButton": "#ded7cc",
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
  hyprctl keyword general:col.active_border "rgb(C5BAA8)" >/dev/null 2>&1 &
  hyprctl keyword general:col.inactive_border "rgb(4f4a44)" >/dev/null 2>&1 &
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 &
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

        # Perceived luminance
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        sum_lum += lum
        total_px++

        max = r; if (g > max) max = g; if (b > max) max = b
        min = r; if (g < min) min = g; if (b < min) min = b
        d = max - min
        l = (max + min) / 2.0
        s = (d == 0) ? 0 : d / (1.0 - ((2.0 * l - 1.0 >= 0) ? (2.0 * l - 1.0) : -(2.0 * l - 1.0)))

        # Group non-black/non-white chromatic pixels into 36 hue buckets (10 degrees each)
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
            # Reward vibrant focal colors and mid-tones over dark shadows
            w = (d * d * 8.0 + s * 1.5) * (1.0 - 0.7 * (l - 0.5) * (l - 0.5))
            bin_weight[bin] += w
            bin_h_sum[bin] += h * w
            bin_s_sum[bin] += s * w
        }
    }
}

END {
    mean_lum = (total_px > 0) ? (sum_lum / total_px) : 0.2
    is_dark = (mean_lum > 0.62) ? "false" : "true"

    best_bin = -1
    best_w = -1
    for (b = 0; b < 36; b++) {
        # Smooth with adjacent hue bins so split-hue clusters lock cleanly
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

    # Ensure dark surfaces always carry a rich, unmistakable hue from the wallpaper (35% to 55% saturation)
    s_dark_surf = clamp(S * 0.90, 0.35, 0.55)
    s_dark_acc  = clamp(S * 1.25, 0.60, 0.85)

    # Dark Mode Layers (Strict lightness separation so buttons & inset boxes pop clearly!)
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

    # Light Mode Layers
    s_light_surf = clamp(S * 0.75, 0.28, 0.48)
    s_light_acc  = clamp(S * 1.15, 0.50, 0.80)

    l_bgBase   = hslToHex(H, s_light_surf, 0.89)
    l_bgDark   = hslToHex(H, s_light_surf, 0.80)
    l_bgButton = hslToHex(H, s_light_surf, 0.86)
    l_bgHover  = hslToHex(H, s_light_surf * 1.10, 0.73)
    l_accent   = hslToHex(H, s_light_acc, 0.36)
    l_ram      = hslToHex(H + 18.0, clamp(s_light_acc * 0.85, 0.40, 0.70), 0.44)
    l_gpu      = hslToHex(H - 22.0, clamp(s_light_acc * 0.75, 0.30, 0.60), 0.52)
    l_textMain = hslToHex(H, 0.35, 0.15)
    l_textMute = hslToHex(H, 0.28, 0.34)
    l_border   = hslToHex(H, clamp(s_light_acc * 0.85, 0.40, 0.70), 0.40)

    printf "{\"wallpaper\":\"%s\",\"isDark\":%s,", wall, is_dark
    printf "\"dark\":{\"bgBase\":\"%s\",\"bgDark\":\"%s\",\"bgHover\":\"%s\",\"bgButton\":\"%s\",\"accent\":\"%s\",\"hardwareRam\":\"%s\",\"hardwareGpu\":\"%s\",\"textMain\":\"%s\",\"textMuted\":\"%s\",\"border\":\"%s\",\"error\":\"#e06c75\"},", d_bgBase, d_bgDark, d_bgHover, d_bgButton, d_accent, d_ram, d_gpu, d_textMain, d_textMute, d_border
    printf "\"light\":{\"bgBase\":\"%s\",\"bgDark\":\"%s\",\"bgHover\":\"%s\",\"bgButton\":\"%s\",\"accent\":\"%s\",\"hardwareRam\":\"%s\",\"hardwareGpu\":\"%s\",\"textMain\":\"%s\",\"textMuted\":\"%s\",\"border\":\"%s\",\"error\":\"#c94f58\"}}\n", l_bgBase, l_bgDark, l_bgHover, l_bgButton, l_accent, l_ram, l_gpu, l_textMain, l_textMute, l_border
}
' >"$CACHE_JSON"

# 4. Sync Hyprland window borders & GTK color-scheme in the background
IS_DARK=$(jq -r '.isDark' "$CACHE_JSON" 2>/dev/null)
if [ "$IS_DARK" = "false" ]; then
  ACTIVE_HEX=$(jq -r '.light.accent' "$CACHE_JSON" | tr -d '#')
  INACTIVE_HEX=$(jq -r '.light.bgHover' "$CACHE_JSON" | tr -d '#')
  gsettings set org.gnome.desktop.interface color-scheme 'default' >/dev/null 2>&1 &
else
  ACTIVE_HEX=$(jq -r '.dark.accent' "$CACHE_JSON" | tr -d '#')
  INACTIVE_HEX=$(jq -r '.dark.bgHover' "$CACHE_JSON" | tr -d '#')
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 &
fi

if [ -n "$ACTIVE_HEX" ] && [ "$ACTIVE_HEX" != "null" ]; then
  hyprctl keyword general:col.active_border "rgb($ACTIVE_HEX)" >/dev/null 2>&1 &
  hyprctl keyword general:col.inactive_border "rgb($INACTIVE_HEX)" >/dev/null 2>&1 &
fi

# 5. Output JSON to stdout so Quickshell updates immediately
cat "$CACHE_JSON"
