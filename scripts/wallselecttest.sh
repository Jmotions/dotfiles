#!/bin/bash
# === wallselect.sh ===
# Wallpaper selection with virtual-display screenshot caching

set -e

CACHE_DIR="$HOME/.cache/wallset-engine"
STARTUP_SCRIPT="$HOME/.config/wallset-engine/wallpaper_startup.sh"
mkdir -p "$CACHE_DIR" "$(dirname "$STARTUP_SCRIPT")"

# Ask for wallpaper ID
read -rp "Enter Wallpaper ID: " WALLPAPER_ID
SS_FILE="$CACHE_DIR/$WALLPAPER_ID.png"

# Ask about audio
read -rp "Enable audio for this wallpaper? (y/N): " ENABLE_AUDIO
ENABLE_AUDIO=${ENABLE_AUDIO,,} # lowercase

# Generate screenshot in virtual display if not cached
if [[ ! -f "$SS_FILE" ]]; then
    echo "Generating screenshot for $WALLPAPER_ID in virtual display..."
    for cmd in linux-wallpaperengine xvfb-run; do
        if ! command -v "$cmd" >/dev/null; then
            echo "Error: $cmd is required but not installed."
            exit 1
        fi
    done

    # Run wallpaper in virtual display and take screenshot
    xvfb-run -s "-screen 0 1920x1080x24" \
        linux-wallpaperengine --screenshot "$SS_FILE" --bg "$WALLPAPER_ID"

    if [[ -f "$SS_FILE" ]]; then
        echo "Screenshot saved: $SS_FILE"
    else
        echo "Failed to generate screenshot for $WALLPAPER_ID"
        exit 1
    fi
else
    echo "Using cached screenshot: $SS_FILE"
fi

# Apply pywal theme based on screenshot
wal -i "$SS_FILE" >/dev/null 2>&1

# Generate startup script
cat > "$STARTUP_SCRIPT" <<EOF
#!/bin/bash
# Auto-start wallpaper on login
linux-wallpaperengine --bg "$WALLPAPER_ID" $( [[ "$ENABLE_AUDIO" == "y" ]] && echo "" || echo "--no-audio" )
EOF
chmod +x "$STARTUP_SCRIPT"

echo "Wallpaper '$WALLPAPER_ID' applied."
echo "Audio: $([[ "$ENABLE_AUDIO" == "y" ]] && echo Enabled || echo Disabled)."
echo "Startup script saved to: $STARTUP_SCRIPT"
echo "You're all set! Feel free to close this terminal."
