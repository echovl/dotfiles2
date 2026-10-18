#!/usr/bin/env bash
# tinty global hook: write the applied scheme's colors to
# ~/.config/rofi/colors.rasi, which config.rasi loads with @theme. Built here
# from the same palette the other hooks get, instead of copied from
# base16-rofi's prebuilt files: those come from whatever version of the
# schemes that repo was last built with, which can differ from tinty's local
# copy (Dracula's base0D did).
set -eu

out=$HOME/.config/rofi/colors.rasi

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# placeholder is base05 at 55% alpha: a dimmed foreground that works on any
# scheme (on Catppuccin Mocha it blends to the old fixed #7f849c).
# Build it first so a missing variable leaves the old colors in place.
rasi=$(cat <<EOF
/* Written by ~/.config/tinted-theming/tinty/hooks/rofi-colors.sh on
 * \`tinty apply\` (${TINTY_SCHEME_SLUG:-unknown scheme}). Changes here are overwritten. */
* {
    background:                  $(hex 00);
    lightbg:                     $(hex 01);
    foreground:                  $(hex 05);
    placeholder:                 $(hex 05)8c;
    blue:                        $(hex 0D);
    border-color:                @foreground;
    alternate-active-background: @lightbg;
}
EOF
)

mkdir -p "${out%/*}"
printf '%s\n' "$rasi" >"$out"
