#!/usr/bin/env bash
# tinty global hook: writes the applied scheme's base16 palette to the file
# the bar reads its colors from (Common/Theme.qml), so the bar follows
# `tinty apply` without a restart. Listed in `hooks` in
# ~/.config/tinted-theming/tinty/config.toml.
set -eu

out=${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/bar/colors.json

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# Build it first so a missing variable leaves the old colors in place.
json=$(
  printf '{\n  "scheme": "%s",\n  "variant": "%s"' "${TINTY_SCHEME_SLUG:-}" "${TINTY_SCHEME_VARIANT:-dark}"
  for k in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
    printf ',\n  "base%s": "%s"' "$k" "$(hex "$k")"
  done
  printf '\n}\n'
)

mkdir -p "${out%/*}"
printf '%s' "$json" >"$out"
