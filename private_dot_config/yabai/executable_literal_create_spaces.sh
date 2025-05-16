#!/bin/sh

function setup_space {
  local idx="$1"
  local name="$2"
  local space=
  echo "setup space $idx : $name"

  space=$(yabai -m query --spaces --space "$idx")
  if [ -z "$space" ]; then
    yabai -m space --create
  fi

  yabai -m space "$idx" --label "$name"
}


setup_space 1 one
setup_space 2 two
setup_space 3 three
setup_space 4 four
setup_space 5 five
setup_space 6 six
setup_space 7 seven
setup_space 8 eight
setup_space 9 nine
setup_space 10 zero

# sketchybar --trigger space_change --trigger windows_on_spaces
