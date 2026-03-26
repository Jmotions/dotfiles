#!/bin/bash

# === CONFIG ===
PLAYER="deezer"
MAX_LEN=40        # visible characters before scrolling starts
SCROLL_SPEED=0.3  # delay in seconds between scroll steps

# === MAIN ===
player_status=$(playerctl --player=$PLAYER status 2>/dev/null)

if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
    artist=$(playerctl --player=$PLAYER metadata artist 2>/dev/null)
    title=$(playerctl --player=$PLAYER metadata title 2>/dev/null)
    text="$title - $artist"

    # Add pause icon if paused
    if [ "$player_status" = "Paused" ]; then
        text=" $text"
    fi

    # Truncate if text too long
    if [ ${#text} -gt $MAX_LEN ]; then
        echo "${text:0:$MAX_LEN}..."
    else
        echo "$text"
    fi
else
    # Hide when nothing is playing
    echo ""
fi

