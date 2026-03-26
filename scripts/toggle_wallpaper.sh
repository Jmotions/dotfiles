#!/bin/bash
set -euo pipefail

# This script toggles a video wallpaper and sets a static fallback.
# It requires `mpvpaper`, `swww`, and `ffmpeg` to be installed.

# --- Configuration ---
FALLBACK_WALLPAPER="/home/jahmad/fallback_wallpaper.png"
OUTPUT_DISPLAY="DP-3" # The display to show the wallpaper on.

# --- Prerequisite Check ---
for cmd in mpvpaper swww ffmpeg; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# --- Main Logic ---
if pgrep -x "mpvpaper" > /dev/null; then
    echo "Video wallpaper is running. Stopping it and creating fallback."

    # Get the video path from the running mpvpaper process
    # This command extracts the video path from the running process.
    # It takes the text after 'loop ' and before any subsequent '--' option.
    VIDEO_PATH_RUNNING=$(pgrep -af 'mpvpaper' | sed -n 's/.*loop //;s/ --.*//p')

    if [ -n "$VIDEO_PATH_RUNNING" ] && [ -f "$VIDEO_PATH_RUNNING" ]; then
        echo "Generating new fallback wallpaper from currently playing video: $VIDEO_PATH_RUNNING"
        if ffmpeg -y -i "$VIDEO_PATH_RUNNING" -ss 00:00:01.000 -vframes 1 "$FALLBACK_WALLPAPER" >/dev/null 2>&1; then
            echo "Successfully generated new fallback wallpaper with ffmpeg."
        else
            echo "Warning: Failed to generate new fallback wallpaper with ffmpeg from '$VIDEO_PATH_RUNNING'." >&2
            # Continue and try to use the old fallback if it exists, or a black screen.
        fi
    else
        echo "Warning: Could not determine running video path or video file not found. Using existing fallback if available." >&2
    fi

    # Stop the video wallpaper.
    pkill -x mpvpaper
    echo "Video wallpaper stopped."

    # Set the new or existing fallback image.
    if [ -f "$FALLBACK_WALLPAPER" ]; then
        swww img "$FALLBACK_WALLPAPER" --outputs "$OUTPUT_DISPLAY" --transition-type grow --transition-fps 60
        echo "Static fallback is now visible."
    else
        echo "Warning: No fallback wallpaper available to set."
    fi
else
    echo "Video wallpaper is not running. Starting it..."
    
    # Get video path from the startup script
    VIDEO_PATH_SCRIPT="/home/jahmad/.config/wallset-engine/wallpaper_startup.sh"
    if [ ! -x "$VIDEO_PATH_SCRIPT" ]; then
        echo "Error: Wallpaper startup script not found or not executable at $VIDEO_PATH_SCRIPT" >&2
        exit 1
    fi
    
    VIDEO_PATH=$("$VIDEO_PATH_SCRIPT")
    if [ ! -f "$VIDEO_PATH" ]; then
        echo "Error: Video file '$VIDEO_PATH' not found." >&2
        exit 1
    fi
    
    echo "Selected video: $VIDEO_PATH"

    # Ensure swww-daemon is running
    if ! pgrep -x "swww-daemon" > /dev/null; then
        echo "swww-daemon not found, starting it."
        swww-daemon &
        # Wait for the daemon to initialize
        sleep 1
    fi
    
    # Set the current fallback wallpaper before starting the video.
    # This prevents a black screen if no wallpaper was set before.
    if [ -f "$FALLBACK_WALLPAPER" ]; then
        echo "Setting fallback wallpaper before starting video."
        swww img "$FALLBACK_WALLPAPER" --outputs "$OUTPUT_DISPLAY" --transition-type grow --transition-fps 60
    else
        echo "Warning: No fallback wallpaper found. Screen might be black before video starts."
    fi
    
    # Give swww a moment to change the wallpaper
    sleep 1

    # Start the video wallpaper.
    echo "Starting video wallpaper..."
    nohup mpvpaper -vs --screen-root "$OUTPUT_DISPLAY" -o "no-audio,loop" "$VIDEO_PATH" >/dev/null 2>&1 &
    echo "Video wallpaper started."
fi
