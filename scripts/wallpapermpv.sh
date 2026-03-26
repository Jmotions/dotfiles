#!/usr/bin/env bash
set -euo pipefail

# === wallselect.sh (mpvpaper + pywal + kitty preview) ===

# CONFIG
STANDARD_STEAM_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
FLATPAK_STEAM_DIR="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
CONFIG_DIR="$HOME/.config/wallset-engine"
ID_LIST="$CONFIG_DIR/video_wallpapers.txt"
STARTUP_SCRIPT="$CONFIG_DIR/wallpaper_startup.sh"
SCREENSHOT_DIR="$CONFIG_DIR/screenshots"
WALLPAPER_FPS=60

mkdir -p "$CONFIG_DIR" "$SCREENSHOT_DIR"

# DEPENDENCY CHECK
for cmd in fzf wal mpvpaper jq ffmpeg kitty; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

# FIND WORKSHOP DIR
WORKSHOP_DIR="$STANDARD_STEAM_DIR"
[[ ! -d "$WORKSHOP_DIR" && -d "$FLATPAK_STEAM_DIR" ]] && WORKSHOP_DIR="$FLATPAK_STEAM_DIR"
[[ ! -d "$WORKSHOP_DIR" ]] && { echo "Error: workshop directory not found"; exit 1; }

# DETECT MONITORS
if command -v hyprctl >/dev/null 2>&1; then
  mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
elif command -v xrandr >/dev/null 2>&1; then
  mapfile -t MONITORS < <(xrandr --query | awk '/ connected/ {print $1}')
else
  MONITORS=( "DP-1" "HDMI-1" "eDP-1" )
fi
[[ ${#MONITORS[@]} -eq 0 ]] && MONITORS=( "DP-1" )
echo "Detected monitors: ${MONITORS[*]}"

# BUILD VIDEO LIST
: > "$ID_LIST"
shopt -s nullglob
for dir in "$WORKSHOP_DIR"/*/; do
  video=$(find "$dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) -print -quit || true)
  [[ -z "$video" ]] && continue
  name=$(basename "$dir")
  title=""
  [[ -f "$dir/project.json" ]] && title=$(jq -r '.title // ""' "$dir/project.json" | sed -e 's/<[^>]*>//g')
  [[ -z "$title" ]] && title="Untitled Wallpaper"
  preview=$(find "$dir" -maxdepth 1 -type f \( -iname "preview.*" -o -iname "thumbnail.*" \) -print -quit || true)
  [[ -z "$preview" ]] && preview="(none)"
  printf "%s\t%s\t%s\t%s\n" "$name" "$title" "$video" "$preview" >> "$ID_LIST"
done
shopt -u nullglob

[[ ! -s "$ID_LIST" ]] && { echo "No video wallpapers found in $WORKSHOP_DIR"; exit 1; }

# FZF SELECTION
CHOICE=$(
  cat "$ID_LIST" | fzf \
    --delimiter=$'\t' --with-nth=1,2 \
    --prompt="Select wallpaper: " \
    --preview='preview=$(awk -F "\t" "{print \$4}" <<< {}); if [[ -f "$preview" ]]; then kitty +kitten icat --clear --transfer-mode=stream --stdin=no --place=35x25@0x0 "$preview" 2>/dev/null || echo "preview exists but failed to show"; else echo "No preview"; fi' \
    --preview-window=right:50%:wrap
)
[[ -z "${CHOICE:-}" ]] && echo "No selection. Exiting." && exit 0

WALLPAPER_ID=$(awk -F $'\t' '{print $1}' <<< "$CHOICE")
WALLPAPER_NAME=$(awk -F $'\t' '{print $2}' <<< "$CHOICE")
VIDEO_FILE=$(awk -F $'\t' '{print $3}' <<< "$CHOICE")
PREVIEW_IMAGE=$(awk -F $'\t' '{print $4}' <<< "$CHOICE")

echo "Selected wallpaper: $WALLPAPER_NAME"
echo "Video file: $VIDEO_FILE"
[[ "$PREVIEW_IMAGE" != "(none)" && -n "$PREVIEW_IMAGE" ]] && echo "Preview image: $PREVIEW_IMAGE"

# USER OPTIONS
read -rp "Enable audio? (y/N): " enable_audio
enable_audio=${enable_audio,,}
read -rp "Keep running in fullscreen? (y/N): " keep_full
keep_full=${keep_full,,}

# KILL EXISTING
pkill -f mpvpaper || true
sleep 0.4

# APPLY PYWAL
if [[ -n "$PREVIEW_IMAGE" && "$PREVIEW_IMAGE" != "(none)" && -f "$PREVIEW_IMAGE" ]]; then
  wal -i "$PREVIEW_IMAGE" >/dev/null 2>&1 || echo "pywal failed (preview image)"
else
  frame="$SCREENSHOT_DIR/${WALLPAPER_NAME// /_}.png"
  ffmpeg -y -ss 1 -i "$VIDEO_FILE" -frames:v 1 "$frame" >/dev/null 2>&1 || true
  [[ -f "$frame" ]] && wal -i "$frame" >/dev/null 2>&1 || echo "pywal failed (generated frame)"
fi

# === BUILD STARTUP SCRIPT ===
{
  echo "#!/usr/bin/env bash"
  echo "set -euo pipefail"
  echo "pkill -f mpvpaper || true"
  echo "sleep 0.4"
} > "$STARTUP_SCRIPT"

echo ""
echo "The following mpvpaper command(s) will be saved for startup:"
echo "-----------------------------"

for MON in "${MONITORS[@]}"; do
  opts="loop"
  [[ "$enable_audio" != "y" && "$enable_audio" != "yes" ]] && opts="no-audio loop"

  cmd=(mpvpaper -vs --screen-root "$MON" -o "$opts" "$VIDEO_FILE")
  [[ "$keep_full" == "y" || "$keep_full" == "yes" ]] && cmd+=(--no-fullscreen-pause)

  # Print readable and escaped commands
  printf 'Readable: %s\n' "${cmd[*]}"
  printf 'Escaped: '
  for piece in "${cmd[@]}"; do printf '%q ' "$piece"; done
  echo ""

  # Append properly quoted command to startup script
  {
    printf 'nohup '
    for piece in "${cmd[@]}"; do
      printf '%q ' "$piece"
    done
    printf ' >/dev/null 2>&1 &\n'
  } >> "$STARTUP_SCRIPT"

  # Execute now for current session
  nohup "${cmd[@]}" >/dev/null 2>&1 &
  sleep 0.05
done

chmod +x "$STARTUP_SCRIPT"

echo "-----------------------------"
echo "Startup script saved to: $STARTUP_SCRIPT"
echo "Run later with: bash $STARTUP_SCRIPT"
echo ""
echo "Current mpvpaper processes:"
pgrep -a mpvpaper || echo "(none found)"
echo ""
echo "Done."
