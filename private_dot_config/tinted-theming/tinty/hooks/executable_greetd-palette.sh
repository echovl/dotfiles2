#!/usr/bin/env bash
# tinty global hook: write the applied scheme's 16 ANSI colors to the file the
# greetd login screen loads into the console palette (see tuigreet-tinted).
# Same mapping as tinted-terminal, so the greeter matches the terminal.
set -eu

out=/etc/greetd/palette
[[ -w $out ]] || exit 0

case ${TINTY_SCHEME_SYSTEM:-} in
  base16) bright=(03 08 0B 0A 0D 0E 0C 07) ;;
  base24) bright=(03 12 14 13 16 17 15 07) ;;
  *) exit 0 ;;
esac
normal=(00 08 0B 0A 0D 0E 0C 05)

hex() {
  local r=TINTY_SCHEME_PALETTE_BASE$1_HEX_R g=TINTY_SCHEME_PALETTE_BASE$1_HEX_G b=TINTY_SCHEME_PALETTE_BASE$1_HEX_B
  printf '%s%s%s\n' "${!r}" "${!g}" "${!b}"
}

# Build first so a missing variable leaves the old palette intact.
palette=$(for k in "${normal[@]}" "${bright[@]}"; do hex "$k"; done)
printf '%s\n' "$palette" > "$out"
