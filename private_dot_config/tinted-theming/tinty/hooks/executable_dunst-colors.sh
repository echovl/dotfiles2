#!/usr/bin/env bash
# tinty global hook: write the applied scheme's colors to
# ~/.config/dunst/dunstrc.d/90-tinty.conf, which dunst loads after dunstrc,
# then reload dunst. Built here instead of copied from base16-dunst, which has
# no base24 files and sets no progress bar color.
set -eu

out=$HOME/.config/dunst/dunstrc.d/90-tinty.conf

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# Frame and progress bar use the accent, like window borders and rofi.
# Critical gets dark text: light text on base08 is hard to read in most
# schemes. Low uses base04 rather than base03 so it stays readable.
# Build it first so a missing variable leaves the old colors in place.
conf=$(cat <<EOF
# Written by ~/.config/tinted-theming/tinty/hooks/dunst-colors.sh on
# \`tinty apply\` (${TINTY_SCHEME_SLUG:-unknown scheme}). Changes here are overwritten.
[global]
    frame_color = "$(hex 0D)"
    separator_color = "$(hex 00)"

[urgency_low]
    background = "$(hex 01)"
    foreground = "$(hex 04)"
    highlight = "$(hex 0D)"

[urgency_normal]
    background = "$(hex 02)"
    foreground = "$(hex 05)"
    highlight = "$(hex 0D)"

[urgency_critical]
    background = "$(hex 08)"
    foreground = "$(hex 00)"
    frame_color = "$(hex 08)"
    highlight = "$(hex 00)"
EOF
)

mkdir -p "${out%/*}"
printf '%s\n' "$conf" >"$out"
dunstctl reload >/dev/null 2>&1 || true
