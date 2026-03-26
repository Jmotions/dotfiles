#!/bin/bash
# === screenshot_all_skipfail.sh ===
set -e

CACHE_DIR="$HOME/.cache/wallset-engine"
ID_LIST="$HOME/.config/wallset-engine/wallpaperengine_ids.txt"

mkdir -p "$CACHE_DIR"

if [[ ! -f "$ID_LIST" ]]; then
    echo "Wallpaper ID list not found: $ID_LIST"
    exit 1
fi

mapfile -t WALLPAPERS < "$ID_LIST"

for entry in "${WALLPAPERS[@]}"; do
    # Keep only numeric ID (strip title if present)
    ID="${entry%% *}"
    SS_FILE="$CACHE_DIR/$ID.png"

    if [[ -f "$SS_FILE" ]]; then
        echo "Cached screenshot exists for $ID, skipping..."
        continue
    fi

    echo "Generating screenshot for $ID..."
    if ./linux-wallpaperengine --screenshot "$SS_FILE" --bg "$ID"; then
        echo "Screenshot saved: $SS_FILE"
    else
        echo "⚠ Failed to generate screenshot for $ID — skipping."
        continue
    fi
done

echo "All wallpapers processed!"
