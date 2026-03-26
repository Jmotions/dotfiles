#!/bin/bash

#export XDG_RUNTIME_DIR=/run/user/$(id -u)
#export HYPRLAND_INSTANCE_SIGNATURE=$(ls $XDG_RUNTIME_DIR/hypr | head -n 1)

# Reload config to restore normal layout
#hyprctl --instance "$HYPRLAND_INSTANCE_SIGNATURE" reload
hyprctl reload
