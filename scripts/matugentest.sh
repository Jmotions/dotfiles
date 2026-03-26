#!/usr/bin/env bash
set -euo pipefail

# === wallselect.sh (linux-wallpaperengine only + safe matugen) ===

# ---------------- CONFIG ----------------
STANDARD_STEAM_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
FLATPAK_STEAM_DIR="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"

CONFIG_DIR="$HOME/.config/wallset-engine"
ID_LIST="$CONFIG_DIR/wallpapers.txt"
STARTUP_SCRIPT="$CONFIG_DIR/wallpaper_startup.sh"
SCREENSHOT_DIR="$CONFIG_DIR/screenshots"

WALLPAPER_FPS=60

mkdir -p "$CONFIG_DIR" "$SCREENSHOT_DIR"

# ---------------- DEP CHECK ----------------
for cmd in fzf wal jq ffmpeg kitty linux-wallpaperengine; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd"; exit 1; }
done

# ---------------- FIND WORKSHOP DIR ----------------
WORKSHOP_DIR="$STANDARD_STEAM_DIR"
[[ ! -d "$WORKSHOP_DIR" && -d "$FLATPAK_STEAM_DIR" ]] && WORKSHOP_DIR="$FLATPAK_STEAM_DIR"
[[ ! -d "$WORKSHOP_DIR" ]] && { echo "Workshop directory not found"; exit 1; }

# ---------------- MONITOR DETECTION ----------------
if command -v hyprctl >/dev/null 2>&1; then
  mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
elif command -v xrandr >/dev/null 2>&1; then
  mapfile -t MONITORS < <(xrandr --query | awk '/ connected/ {print $1}')
else
  MONITORS=("DP-1")
fi
[[ ${#MONITORS[@]} -eq 0 ]] && MONITORS=("DP-1")

echo "Detected monitors: ${MONITORS[*]}"

# ---------------- BUILD LIST ----------------
: > "$ID_LIST"
shopt -s nullglob

for dir in "$WORKSHOP_DIR"/*/; do
  id=$(basename "$dir")

  title="Untitled Wallpaper"
  if [[ -f "$dir/project.json" ]]; then
    title=$(jq -r '.title // "Untitled Wallpaper"' "$dir/project.json" | sed 's/<[^>]*>//g')
  fi

  preview=$(find "$dir" -maxdepth 1 -type f \
    \( -iname "preview.*" -o -iname "thumbnail.*" \) \
    -print -quit || true)

  [[ -z "$preview" ]] && preview="(none)"

  printf "%s\t%s\t%s\n" "$id" "$title" "$preview" >> "$ID_LIST"
done

shopt -u nullglob
[[ ! -s "$ID_LIST" ]] && { echo "No wallpapers found"; exit 1; }

# ---------------- FZF ----------------
CHOICE=$(
  cat "$ID_LIST" | fzf \
    --delimiter=$'\t' --with-nth=2 \
    --prompt="Select wallpaper: " \
    --preview='preview=$(awk -F "\t" "{print \$3}" <<< {}); if [[ -f "$preview" ]]; then kitty +kitten icat --clear --transfer-mode=stream --stdin=no --place=35x25@0x0 "$preview" 2>/dev/null || echo "Preview failed"; else echo "No preview"; fi' \
    --preview-window=right:50%:wrap
)

[[ -z "${CHOICE:-}" ]] && exit 0

WALLPAPER_ID=$(awk -F $'\t' '{print $1}' <<< "$CHOICE")
WALLPAPER_NAME=$(awk -F $'\t' '{print $2}' <<< "$CHOICE")

echo "Selected: $WALLPAPER_NAME"

# ---------------- OPTIONS ----------------
read -rp "Enable audio? (y/N): " enable_audio
enable_audio=${enable_audio,,}
read -rp "Keep running in fullscreen? (y/N): " keep_full
keep_full=${keep_full,,}

# ---------------- KILL EXISTING ----------------
pkill -f linux-wallpaperengine || true
sleep 0.5

# ---------------- MATUGEN (SAFE MODE) ----------------
preview=$(find "$WORKSHOP_DIR/$WALLPAPER_ID" -maxdepth 1 -type f \
  \( -iname "preview.*" -o -iname "thumbnail.*" \) \
  -print -quit || true)

apply_matugen() {
  local img="$1"
  [[ -f "$img" ]] || return 1

  echo "Generating Material You scheme..."
  matugen image "$img" --config "$HOME/.config/matugen/config.toml" \
    --mode dark \
    --type scheme-tonal-spot \
    --quiet \
    --continue-on-error || true
}

if [[ -n "$preview" && -f "$preview" ]]; then
  echo "Applying matugen from preview..."
  ext="${preview##*.}"
  ext="${ext,,}"

  if [[ "$ext" == "gif" ]]; then
    frame="$SCREENSHOT_DIR/${WALLPAPER_ID}_preview.png"
    ffmpeg -y -ss 0.3 -i "$preview" -frames:v 1 "$frame" >/dev/null 2>&1 || true
    [[ -f "$frame" ]] && apply_matugen "$frame"
  else
    apply_matugen "$preview"
  fi
else
  echo "No preview found — skipping matugen"
fi

# ---------------- BUILD COMMAND ----------------
cmd=(linux-wallpaperengine)

for MON in "${MONITORS[@]}"; do
  cmd+=(--screen-root "$MON" --bg "$WALLPAPER_ID")
done

cmd+=(--fps "$WALLPAPER_FPS")

[[ "$enable_audio" != "y" ]] && cmd+=(--silent)
[[ "$keep_full" == "y" ]] && cmd+=(--no-fullscreen-pause)

echo ""
echo "Launching wallpaper with command:"
printf '%q ' "${cmd[@]}"
echo
echo ""

# ---------------- START WALLPAPER ----------------
nohup "${cmd[@]}" >/dev/null 2>&1 &

# ---------------- STARTUP SCRIPT ----------------
{
  echo "#!/usr/bin/env bash"
  echo "pkill -f linux-wallpaperengine || true"
  echo "sleep 0.5"
  printf 'nohup '
  for p in "${cmd[@]}"; do printf '%q ' "$p"; done
  printf '>/dev/null 2>&1 &\n'
} > "$STARTUP_SCRIPT"

chmod +x "$STARTUP_SCRIPT"

echo "Startup script saved to: $STARTUP_SCRIPT"
echo "Done."
