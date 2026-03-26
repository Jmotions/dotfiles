#!/bin/bash

# Toggle the special workspace
hyprctl dispatch togglespecialworkspace hyprspace

# Give Hyprland a moment to process the workspace change
sleep 0.1

# Attempt to force a layout reflow on the active workspace
# These commands often trigger a re-layout without being too visually disruptive.
hyprctl dispatch movefocus l
hyprctl dispatch movefocus r
hyprctl dispatch splitratio 0.50001
hyprctl dispatch splitratio 0.5
