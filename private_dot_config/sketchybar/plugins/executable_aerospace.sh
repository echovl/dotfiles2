#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

empty_workspaces=$(aerospace list-workspaces --monitor all --empty)

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on drawing=on
elif echo "$empty_workspaces" | grep -q "$1"; then
    # If it's empty, set drawing to "off"
    sketchybar --set $NAME background.drawing=off drawing=off
else
    sketchybar --set $NAME background.drawing=off
fi
