#!/bin/bash

# Point to your user’s Hyprland session
#export XDG_RUNTIME_DIR=/run/user/$(id -u)
#xport HYPRLAND_INSTANCE_SIGNATURE=$(ls $XDG_RUNTIME_DIR/hypr | head -n 1)

# Force DP-3 for streaming
#hyprctl --instance "$HYPRLAND_INSTANCE_SIGNATURE" keyword monitor "DP-3,preferred,auto,1"
hyprctl keyword monitor "HDMI-A-1,disable"
