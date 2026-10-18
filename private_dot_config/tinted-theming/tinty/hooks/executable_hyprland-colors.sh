#!/usr/bin/env bash
# tinty global hook: write the applied scheme's window border colors to
# ~/.config/hypr/colors.lua, which hyprland.lua loads last, then reload
# Hyprland. Active border is base0D (accent), inactive is base03.
set -eu

out=$HOME/.config/hypr/colors.lua

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '0xff%s%s%s' "${!r}" "${!g}" "${!b}"
}

# Build it first so a missing variable leaves the old colors in place.
lua=$(cat <<EOF
-- Written by ~/.config/tinted-theming/tinty/hooks/hyprland-colors.sh on
-- \`tinty apply\` (${TINTY_SCHEME_SLUG:-unknown scheme}). Changes here are overwritten.
hl.config({
  general = {
    col = {
      active_border = "$(hex 0D)",
      inactive_border = "$(hex 03)",
    },
  },
})
EOF
)

printf '%s\n' "$lua" >"$out"
hyprctl reload >/dev/null 2>&1 || true
