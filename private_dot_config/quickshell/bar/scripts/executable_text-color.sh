#!/usr/bin/env bash
# Prints the theme color that reads best on the wallpaper behind a clear bar:
# the text color, or the background color when that contrasts more. Ported
# from Omarchy's omarchy-bar-text-color; the wallpaper comes from swaybg.
#
# Usage: text-color.sh <screen-width> <screen-height> <bar-height> <text-hex> <background-hex>

width=${1:-} height=${2:-} bar=${3:-} text=${4:-} background=${5:-}

fallback() {
  printf '%s\n' "$text"
  exit 0
}

[[ $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ && $bar =~ ^[0-9]+$ ]] || fallback
[[ $text =~ ^#[0-9A-Fa-f]{6}$ && $background =~ ^#[0-9A-Fa-f]{6}$ ]] || fallback
command -v magick >/dev/null || fallback

wallpaper=""
mode=stretch
for pid in $(pgrep -x swaybg); do
  mapfile -d '' args <"/proc/$pid/cmdline"
  for ((i = 0; i < ${#args[@]} - 1; i++)); do
    [[ ${args[i]} == -i || ${args[i]} == --image ]] && wallpaper=${args[i + 1]}
    [[ ${args[i]} == -m || ${args[i]} == --mode ]] && mode=${args[i + 1]}
  done
done
[[ -f $wallpaper ]] || fallback

# Lay the image out as swaybg does: stretched by default, or cropped to fill.
if [[ $mode == fill ]]; then
  layout=(-resize "${width}x${height}^" -gravity center -extent "${width}x${height}")
else
  layout=(-resize "${width}x${height}!")
fi

pixel=$(magick "$wallpaper[0]" -auto-orient "${layout[@]}" \
  -gravity NorthWest -crop "${width}x${bar}+0+0" +repage \
  -resize '1x1!' -format '%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]' info:- 2>/dev/null)
[[ $pixel =~ ^([0-9]+),([0-9]+),([0-9]+)$ ]] || fallback
sample=$(printf '#%02x%02x%02x' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}")

# WCAG contrast ratio between two hex colors.
contrast() {
  awk -v fg="$1" -v bg="$2" '
    function channel(hex, start) { return strtonum("0x" substr(hex, start, 2)) / 255 }
    function linear(c) { return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function luminance(hex) { return 0.2126 * linear(channel(hex, 2)) + 0.7152 * linear(channel(hex, 4)) + 0.0722 * linear(channel(hex, 6)) }
    BEGIN {
      l1 = luminance(fg); l2 = luminance(bg)
      if (l1 < l2) { t = l1; l1 = l2; l2 = t }
      printf "%.6f\n", (l1 + 0.05) / (l2 + 0.05)
    }'
}

text_contrast=$(contrast "$text" "$sample")
background_contrast=$(contrast "$background" "$sample")
if awk -v t="$text_contrast" -v b="$background_contrast" 'BEGIN { exit !(b > t) }'; then
  printf '%s\n' "$background"
else
  printf '%s\n' "$text"
fi
