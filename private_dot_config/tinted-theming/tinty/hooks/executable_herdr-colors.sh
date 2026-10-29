#!/usr/bin/env bash
# tinty global hook: write the applied scheme's colors into the marked
# [theme.custom] block of herdr's config.toml, then reload the herdr server.
#
# herdr runs the "terminal" theme, so accents, borders and separators follow
# the terminal's ANSI colors. Its neutral tokens can only name ANSI colors, and
# a base16 terminal has one muted gray (color 8, base03): too dark for labels
# and too close to any row highlight. This block overrides just those tokens:
#   active_row_bg  base02, the scheme's selection background
#   overlay0       base05 at 45% over base00: sidebar labels, inactive tabs,
#                  unfocused pane borders, secondary agent text
#   overlay1       base05 at 55%: hovered tabs, scrollbar thumb (rofi's
#                  placeholder uses the same blend)
#   subtext0       base05 at 78%: unfocused space and agent names
#   mauve          base0E: branch of the focused space, resize mode bar
# On Catppuccin Mocha the blends land on its overlay0/overlay1/subtext0.
set -eu

cfg=${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}
begin='# >>> tinty herdr-colors >>>'
end='# <<< tinty herdr-colors <<<'

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# base05 blended $1% over base00, per channel.
dim() {
  local c bg fg out='#'
  for c in R G B; do
    bg=TINTY_SCHEME_PALETTE_BASE00_HEX_$c fg=TINTY_SCHEME_PALETTE_BASE05_HEX_$c
    out+=$(printf '%02x' $(((16#${!bg} * (100 - $1) + 16#${!fg} * $1 + 50) / 100)))
  done
  printf '%s' "$out"
}

# Plain assignments, so a missing variable stops the hook before it writes.
active_row_bg=$(hex 02)
overlay0=$(dim 45)
overlay1=$(dim 55)
subtext0=$(dim 78)
mauve=$(hex 0E)

block="$begin
# Written by ~/.config/tinted-theming/tinty/hooks/herdr-colors.sh on
# \`tinty apply\` (${TINTY_SCHEME_SLUG:-unknown scheme}). Changes here are overwritten.
[theme.custom]
active_row_bg = \"$active_row_bg\"
overlay0 = \"$overlay0\"
overlay1 = \"$overlay1\"
subtext0 = \"$subtext0\"
mauve = \"$mauve\"
$end"

old=$(cat "$cfg" 2>/dev/null || true)
if grep -qxF "$begin" <<<"$old" && grep -qxF "$end" <<<"$old"; then
  new=$(block=$block awk -v b="$begin" -v e="$end" '
    $0 == b { print ENVIRON["block"]; skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' <<<"$old")
elif grep -q '^\[theme\.custom\]' <<<"$old"; then
  # A second [theme.custom] table would make the whole config invalid.
  echo "herdr-colors: $cfg has [theme.custom] outside the tinty markers; not writing" >&2
  exit 1
elif [[ -n $old ]]; then
  new=$old$'\n\n'$block
else
  new=$block
fi

mkdir -p "${cfg%/*}"
printf '%s\n' "$new" >"$cfg"
herdr server reload-config >/dev/null 2>&1 || true
