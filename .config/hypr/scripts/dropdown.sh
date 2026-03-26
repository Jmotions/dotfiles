#!/usr/bin/env bash

TOGGLE=/tmp/droptoggle
DROPTERM=kitty-dropdown

if [ -f "$TOGGLE" ]; then
    #Show terminal and pin
    hyprctl --batch "dispatch movewindowpixel 0 -800,$DROPTERM; dispatch focuswindow $DROPTERM"
    rm $TOGGLE
else
    #Hide terminal and unpin
    hyprctl --batch "dispatch movewindowpixel 0 800,$DROPTERM; dispatch cyclenext"
    touch $TOGGLE
fi