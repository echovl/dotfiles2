#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

# sketchybar --set "$NAME" background.drawing="$SELECTED"

# args=()
# if [ "$NAME" != "space_template" ]; then
#   args+=(--set $NAME label=$NAME \
#                      icon.highlight=$SELECTED)
# fi
#
# sketchybar -m --animate tanh 0 "${args[@]}"

if [ "$SELECTED" = "true" ]; then
  args+=(--set spaces_$DID.label label=${NAME#"spaces_$DID."} \
         --set $NAME icon.background.y_offset=0               )
fi

WIN=$(yabai -m query --spaces --space $SID | jq '.windows[0]')
HAS_WINDOWS_OR_IS_SELECTED="true"
if [ "$WIN" = "null" ] && [ "$SELECTED" = "false" ];then
  HAS_WINDOWS_OR_IS_SELECTED="false"
fi

DRAWING="off"
if [ "$HAS_WINDOWS_OR_IS_SELECTED" = "true" ]; then
  DRAWING="on"
fi

sketchybar --set $NAME background.drawing="$SELECTED" drawing="$DRAWING"
