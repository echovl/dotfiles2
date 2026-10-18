#!/usr/bin/env bash
# Switches to a workspace. Tries Hyprland's Lua dispatcher first, then the
# classic one for a hyprlang config (Quickshell's Hyprland.usingLua doesn't
# detect a Lua config reliably).
#
# Usage: workspace.sh <id>

id=${1:?usage: workspace.sh <id>}
[[ $(hyprctl dispatch "hl.dsp.focus({ workspace = \"$id\" })" 2>/dev/null) == ok ]] ||
  hyprctl dispatch workspace "$id" >/dev/null
