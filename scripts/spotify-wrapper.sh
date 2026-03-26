#!/bin/bash

# Check if Spotify is running
if hyprctl clients | grep -q -E "class: (Spotify|spotify)"; then
    # If it is, focus the window
    hyprctl dispatch focuswindow "class:(Spotify|spotify)"
else
    # If it's not, launch it with spicetify auto
    spicetify auto
fi
