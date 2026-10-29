#!/usr/bin/env bash
# tinty global hook: write the applied scheme as a Tern CSS theme,
# ~/.config/tern/themes/tinty.css. Tern lists it in its theme picker as
# "tinty" and restyles every window showing it when the file changes, so with
# tinty picked for both appearances Tern follows `tinty apply`.
#
# The sheet imports Tern's own "dark" or "light" theme after the scheme's
# variant, which sets the window's appearance, then overrides every color a
# Tern theme carries (https://docs.stencil.so/tern/styles/variables.html):
#   terminal  tinted-terminal's colors: base00 background, base05 foreground
#             and cursor, the same 16 ANSI colors, base0A/base09 search marks
#   text      base05, and base05 blended over base00 for the dimmer steps
#   chrome    base01 window and cards, base02 popovers (base01 on light
#             schemes), blends of base00 and base02 for raised controls and code
#   accent    base0D, as the other hooks; the gradient runs base0C to base0D
#   status    base0B ok, base0A warning, base08 error, base0E running
#   syntax    the base16 styling guide's roles (code, diff and Markdown blocks)
# The *-fill colors carry white text, so they are capped at OKLCH lightness
# 0.5 (at least 4.5:1 against white).
set -eu

out=${TERN_CONFIG_DIR:-$HOME/.config/tern}/themes/tinty.css

# ANSI 9-14, as tinted-terminal: base24 has its own bright colors.
case ${TINTY_SCHEME_SYSTEM:-} in
  base16) bright=(08 0B 0A 0D 0E 0C) ;;
  base24) bright=(12 14 13 16 17 15) ;;
  *) exit 0 ;;
esac

case ${TINTY_SCHEME_VARIANT:-} in
  light) base=light ;;
  *) base=dark ;;
esac

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

# WCAG relative luminance of base $1.
lum() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  awk -v r=$((16#${!r})) -v g=$((16#${!g})) -v b=$((16#${!b})) '
    function c(x) { x /= 255; return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ^ 2.4 }
    BEGIN { print 0.2126 * c(r) + 0.7152 * c(g) + 0.0722 * c(b) }'
}

# Text on the gradient (accent buttons, marks): base00 or base07, whichever
# reads better against the gradient's weaker stop.
grad_ink=$(awk -v a="$(lum 0C)" -v b="$(lum 0D)" -v d="$(lum 00)" -v l="$(lum 07)" '
  function cr(x, y) { return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }
  function lo(x, y) { return x < y ? x : y }
  BEGIN { print lo(cr(a, d), cr(b, d)) >= lo(cr(a, l), cr(b, l)) ? "00" : "07" }')

# Build it first so a missing variable leaves the old theme in place.
css=$(cat <<EOF
/* Written by ~/.config/tinted-theming/tinty/hooks/tern-colors.sh on
 * \`tinty apply\` (${TINTY_SCHEME_SLUG:-unknown scheme}). Changes here are overwritten. */
@import "$base";

:root {
	--tv-bg: $(hex 00);
	--tv-fg: $(hex 05);
	--tv-cur: $(hex 05);
	--tv-cur-ink: $(hex 00);
	--tn-sel: $(hex 0D);
	--tv-sel-a: $(hex 0D);
	--tv-sel-b: $(hex 0C);
	--tv-m1: light-dark(rgb(from $(hex 0A) r g b / 42%), rgb(from $(hex 0A) r g b / 34%));
	--tv-m2: light-dark(rgb(from $(hex 09) r g b / 42%), rgb(from $(hex 09) r g b / 34%));

	--ansi0: $(hex 00);
	--ansi1: $(hex 08);
	--ansi2: $(hex 0B);
	--ansi3: $(hex 0A);
	--ansi4: $(hex 0D);
	--ansi5: $(hex 0E);
	--ansi6: $(hex 0C);
	--ansi7: $(hex 05);
	--ansi8: $(hex 03);
	--ansi9: $(hex "${bright[0]}");
	--ansi10: $(hex "${bright[1]}");
	--ansi11: $(hex "${bright[2]}");
	--ansi12: $(hex "${bright[3]}");
	--ansi13: $(hex "${bright[4]}");
	--ansi14: $(hex "${bright[5]}");
	--ansi15: $(hex 07);

	--ink: $(hex 05);
	--t1: var(--ink);
	--t2: light-dark(color-mix(in srgb, var(--ink) 88%, var(--tv-bg)), color-mix(in srgb, var(--ink) 75%, var(--tv-bg)));
	--t3: light-dark(color-mix(in srgb, var(--ink) 78%, var(--tv-bg)), color-mix(in srgb, var(--ink) 60%, var(--tv-bg)));
	--t4: light-dark(color-mix(in srgb, var(--ink) 55%, var(--tv-bg)), color-mix(in srgb, var(--ink) 40%, var(--tv-bg)));

	--tn-page: $(hex 01);
	--tn-pop: light-dark($(hex 01), $(hex 02));
	--card: $(hex 01);
	--raise: color-mix(in srgb, $(hex 00), $(hex 02));
	--code-bg: color-mix(in srgb, $(hex 00) 72%, $(hex 02));
	--tbl-head: var(--code-bg);

	--accent: $(hex 0D);
	--accent-ink: var(--accent);
	--accent-fill: oklch(from var(--accent) min(l, 0.5) c h);
	--a1: $(hex 0C);
	--a2: $(hex 0D);
	--grad-ink: $(hex "$grad_ink");
	--tn-grad-face: linear-gradient(135deg, var(--a1), var(--a2));
	--ok: $(hex 0B);
	--ok-fill: oklch(from var(--ok) min(l, 0.5) c h);
	--warn: $(hex 0A);
	--bad: $(hex 08);
	--bad-fill: oklch(from var(--bad) min(l, 0.5) c h);
	--live: $(hex 0E);
	--live-fill: oklch(from var(--live) min(l, 0.5) c h);

	--tk-comment: $(hex 03);
	--tk-keyword: $(hex 0E);
	--tk-function: $(hex 0D);
	--tk-variable: $(hex 08);
	--tk-string: $(hex 0B);
	--tk-number: $(hex 09);
	--tk-type: $(hex 0A);
	--tk-operator: $(hex 05);
	--tk-punct: $(hex 05);
	--tk-inserted: $(hex 0B);
	--tk-deleted: $(hex 08);
}
EOF
)

# Tern reloads the theme on every change: replace the file in one step so it
# never reads a half-written sheet.
mkdir -p "${out%/*}"
tmp=$(mktemp "${out%/*}/.tinty.css.XXXXXX")
printf '%s\n' "$css" >"$tmp"
chmod 644 "$tmp"
mv -f "$tmp" "$out"
