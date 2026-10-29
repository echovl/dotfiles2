#!/usr/bin/env bash
# tinty global hook: publish the applied scheme as a T3 Code environment theme,
# ~/.t3/userdata/themes/tinty.json. T3 Code's server watches that directory and
# lists the theme in Settings → Appearance as "Tinty"; clients showing it
# repaint when the file changes, so once it is picked (or `t3 theme set tinty`
# has run) T3 Code follows `tinty apply`.
#
# The file sets every color role T3 Code has
# (https://github.com/pingdotgg/t3code/blob/main/docs/user/appearance.md):
#   background  base00 canvas, toolbar and terminal; base01 sidebar
#   surfaces    base00 blended toward base02: cards 15%, code 30%, raised 45%,
#               muted 55%, popovers 70%, subtle controls 85%
#   highlight   base02 hover surfaces, selected sidebar row (hovered and active
#               rows 50% and 80% of the way from base01), terminal selection;
#               message bubbles base02 25% toward base03
#   lines       borders halfway from base02 to base03, inputs base03, terminal
#               scrollbar base03 (25% toward base05 on hover)
#   text        base05, and the terminal cursor as tinted-terminal has it;
#               muted text is base05 blended over the surface it labels just
#               far enough for T3 Code's own contrast: 5.08:1 (4.71:1 on light
#               schemes) on the canvas and sidebar, 4.6:1 on muted fills and
#               raised surfaces (placeholders)
#   accent      base0D: accent, focus ring, update badge, buttons
#   status      base08 error, base0A warning, base0D update, each over a 16%
#               tint of itself (8% on light schemes), its text moved toward
#               base05 until it reaches 4.6:1
#   search      base0A: matches at 35% over base00 (42% on light schemes),
#               eased back toward base00 until base05 on them reaches 4.5:1;
#               the current match solid
# Text on solid fills is base00 or base05, whichever contrasts more. Buttons
# and the current match keep 4.5:1: where their text falls short (base0A and
# base0D on most light schemes), the fill moves away from it until it doesn't.
# canvas and accent (base00, base0D) also seed T3 Code's generator, which fills
# any role a later release adds. T3 Code has no roles for the terminal's ANSI
# colors or for syntax highlighting, so those keep its defaults.
set -eu

dir=${T3CODE_HOME:-$HOME/.t3}/userdata/themes
out=$dir/tinty.json

case ${TINTY_SCHEME_SYSTEM:-} in
  base16 | base24) ;;
  *) exit 0 ;;
esac

case ${TINTY_SCHEME_VARIANT:-} in
  light) appearance=light tint=8 mark=42 muted_ratio=4.705 ;;
  *) appearance=dark tint=16 mark=35 muted_ratio=5.082 ;;
esac

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# $1 blended $3% toward $2, per channel.
mix() {
  local i out='#'
  for i in 1 3 5; do
    out+=$(printf '%02x' $(((16#${1:i:2} * (100 - $3) + 16#${2:i:2} * $3 + 50) / 100)))
  done
  printf '%s' "$out"
}

# WCAG relative luminance and contrast; blend() rounds as mix() does.
lib='
function ch(h, i) {
  h = tolower(h)
  return (index("0123456789abcdef", substr(h, i, 1)) - 1) * 16 + index("0123456789abcdef", substr(h, i + 1, 1)) - 1
}
function lin(x) { x /= 255; return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ^ 2.4 }
function lum(h) { return 0.2126 * lin(ch(h, 2)) + 0.7152 * lin(ch(h, 4)) + 0.0722 * lin(ch(h, 6)) }
function cr(x, y) { return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }
function blend(a, b, p,  i, out) {
  out = "#"
  for (i = 2; i <= 6; i += 2) out = out sprintf("%02x", int((ch(a, i) * (100 - p) + ch(b, i) * p + 50) / 100))
  return out
}'

# The first 1% step from $1 toward $2 with $3:1 contrast against each of the
# remaining colors; $2 if no step gets there.
reach() {
  awk -v from="$1" -v to="$2" -v ratio="$3" -v bgs="${*:4}" "$lib"'
    BEGIN {
      n = split(bgs, bg, " ")
      for (p = 0; p <= 100; p++) {
        c = blend(from, to, p)
        for (i = 1; i <= n && cr(lum(c), lum(bg[i])) >= ratio; i++);
        if (i > n) { print c; exit }
      }
      print to
    }'
}

# base00 or base05, whichever reads better on $1.
ink() {
  awk -v fill="$1" -v a="$b00" -v b="$b05" "$lib"'
    BEGIN { print cr(lum(fill), lum(a)) >= cr(lum(fill), lum(b)) ? a : b }'
}

# The end of base00..base05 away from $1, a text color from ink().
away() {
  if [[ $1 == "$b00" ]]; then printf '%s' "$b05"; else printf '%s' "$b00"; fi
}

# Plain assignments, so a missing variable stops the hook before it writes.
b00=$(hex 00)
b01=$(hex 01)
b02=$(hex 02)
b03=$(hex 03)
b05=$(hex 05)
b08=$(hex 08)
b0A=$(hex 0A)
b0D=$(hex 0D)

surface=$(mix "$b00" "$b02" 15)
code=$(mix "$b00" "$b02" 30)
raised=$(mix "$b00" "$b02" 45)
muted=$(mix "$b00" "$b02" 55)
overlay=$(mix "$b00" "$b02" 70)
control=$(mix "$b00" "$b02" 85)
row_hover=$(mix "$b01" "$b02" 50)
row_active=$(mix "$b01" "$b02" 80)
bubble=$(mix "$b02" "$b03" 25)
border=$(mix "$b02" "$b03" 50)
scrollbar_hover=$(mix "$b03" "$b05" 25)
text_muted=$(reach "$b00" "$b05" "$muted_ratio" "$b00")
sidebar_muted=$(reach "$b01" "$b05" "$muted_ratio" "$b01")
muted_fg=$(reach "$muted" "$b05" 4.6 "$muted")
placeholder=$(reach "$raised" "$b05" 4.6 "$raised")

accent_ink=$(ink "$b0D")
accent_away=$(away "$accent_ink")
action=$(reach "$b0D" "$accent_away" 4.5 "$accent_ink")
action_hover=$(mix "$action" "$accent_away" 15)

error_surface=$(mix "$b00" "$b08" "$tint")
error_fg=$(reach "$b08" "$b05" 4.6 "$error_surface" "$b00")
warning_surface=$(mix "$b00" "$b0A" "$tint")
warning_fg=$(reach "$b0A" "$b05" 4.6 "$warning_surface" "$b00")
update_surface=$(mix "$b00" "$b0D" "$tint")
update_fg=$(reach "$b0D" "$b05" 4.6 "$update_surface" "$b00")

match=$(reach "$(mix "$b00" "$b0A" "$mark")" "$b00" 4.5 "$b05")
current_ink=$(ink "$b0A")
current=$(reach "$b0A" "$(away "$current_ink")" 4.5 "$current_ink")

json=$(cat <<EOF
{
  "version": 1,
  "name": "Tinty",
  "appearance": "$appearance",
  "canvas": "$b00",
  "accent": "$b0D",
  "colors": {
    "canvas": "$b00",
    "chrome": "$b00",
    "toolbar": "$b00",
    "toolbarForeground": "$b05",
    "toolbarBorder": "$border",
    "toolbarControl": "$control",
    "toolbarControlForeground": "$b05",
    "toolbarControlHover": "$b02",
    "surface": "$surface",
    "surfaceRaised": "$raised",
    "surfaceOverlay": "$overlay",
    "text": "$b05",
    "textMuted": "$text_muted",
    "border": "$border",
    "input": "$b03",
    "focus": "$b0D",
    "accent": "$b0D",
    "accentForeground": "$accent_ink",
    "secondary": "$control",
    "secondaryForeground": "$b05",
    "muted": "$muted",
    "mutedForeground": "$muted_fg",
    "placeholder": "$placeholder",
    "secondaryLabel": "$text_muted",
    "iconMuted": "$text_muted",
    "error": "$b08",
    "errorForeground": "$error_fg",
    "errorSurface": "$error_surface",
    "warning": "$b0A",
    "warningForeground": "$warning_fg",
    "warningSurface": "$warning_surface",
    "update": "$b0D",
    "updateForeground": "$update_fg",
    "updateSurface": "$update_surface",
    "accentSurface": "$b02",
    "accentSurfaceForeground": "$b05",
    "messageSurface": "$bubble",
    "messageForeground": "$b05",
    "messageAction": "$action",
    "messageActionForeground": "$accent_ink",
    "messageActionHover": "$action_hover",
    "codeBackground": "$code",
    "codeForeground": "$b05",
    "searchMatchBackground": "$match",
    "searchMatchForeground": "$b05",
    "searchMatchActiveBackground": "$current",
    "searchMatchActiveForeground": "$current_ink",
    "sidebar": "$b01",
    "sidebarForeground": "$b05",
    "sidebarMutedForeground": "$sidebar_muted",
    "sidebarControlSurface": "$row_hover",
    "sidebarRowHover": "$row_hover",
    "sidebarRowActive": "$row_active",
    "sidebarRowSelected": "$b02",
    "sidebarBorder": "$border",
    "terminalBackground": "$b00",
    "terminalForeground": "$b05",
    "terminalCursor": "$b05",
    "terminalSelection": "$b02",
    "terminalScrollbar": "$b03",
    "terminalScrollbarHover": "$scrollbar_hover"
  }
}
EOF
)

# The server republishes the theme on every change: replace the file in one
# step so it never reads a half-written one (it skips names not ending .json).
mkdir -p "$dir"
tmp=$(mktemp "$dir/.tinty.json.XXXXXX")
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$json" >"$tmp"
chmod 644 "$tmp"
mv -f "$tmp" "$out"
