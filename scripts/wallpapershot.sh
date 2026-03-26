#!/bin/bash
# === generate_all_wallpaper_screenshots.sh ===

WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
CACHE_SCREENSHOT_DIR="$HOME/.cache/wallset-engine"
mkdir -p "$CACHE_SCREENSHOT_DIR"

MAX_JOBS=4
CURRENT_JOBS=0

# Check linux-wallpaperengine is installed
if ! command -v linux-wallpaperengine >/dev/null; then
    echo "Error: linux-wallpaperengine is required but not installed."
    exit 1
fi

capture_screenshot() {
    local WALLPAPER_ID="$1"
    local SS_FILE="$CACHE_SCREENSHOT_DIR/$WALLPAPER_ID.png"

    if [[ -f "$SS_FILE" ]]; then
        echo "Screenshot exists for $WALLPAPER_ID, skipping..."
        return
    fi

    echo "Generating screenshot for wallpaper ID: $WALLPAPER_ID"
    linux-wallpaperengine --screenshot "$SS_FILE" --bg "$WALLPAPER_ID" >/dev/null 2>&1
    if [[ -f "$SS_FILE" ]]; then
        echo "Saved: $SS_FILE"
    else
        echo "Failed: $WALLPAPER_ID"
    fi
}

# Loop through all wallpapers in Workshop
for ID_DIR in "$WORKSHOP_DIR"/*/; do
    WALLPAPER_ID=$(basename "$ID_DIR")
    capture_screenshot "$WALLPAPER_ID" &

    ((CURRENT_JOBS++))
    if (( CURRENT_JOBS >= MAX_JOBS )); then
        wait -n
        ((CURRENT_JOBS--))
    fi
done

# Wait for remaining jobs
wait

echo "All wallpapers processed. Screenshots are in $CACHE_SCREENSHOT_DIR"
