#!/bin/bash

config="$HOME/.config/hypr/hyprland.conf"
colors="$HOME/.cache/wal/colors.json"

active=$(jq -r '.colors.color1' "$colors" | sed 's/#//')ff
inactive=$(jq -r '.colors.color0' "$colors" | sed 's/#//')ff

# Use hyprctl keyword to apply live
hyprctl keyword general:col.active_border "rgba($active)"
hyprctl keyword general:col.inactive_border "rgba($inactive)"
