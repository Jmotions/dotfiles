#!/usr/bin/env bash
set -euo pipefail

# ================= CONFIG =================
STANDARD_STEAM="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
FLATPAK_STEAM="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
IMAGE_DIR="$HOME/Pictures/wallpapers"
CONFIG_DIR="$HOME/.config/wallset-engine"
LIST_FILE="$CONFIG_DIR/wallpapers.txt"
STARTUP_SCRIPT="$CONFIG_DIR/wallpaper_startup.sh"
CACHE_DIR="$CONFIG_DIR/cache"
FPS=60

mkdir -p "$CONFIG_DIR" "$CACHE_DIR"

# ================= DEPENDENCIES =================
for cmd in fzf jq wal ffmpeg kitty; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd"; exit 1; }
done

# ================= WORKSHOP DIR =================
WORKSHOP="$STANDARD_STEAM"
[[ ! -d "$WORKSHOP" && -d "$FLATPAK_STEAM" ]] && WORKSHOP="$FLATPAK_STEAM"
[[ ! -d "$WORKSHOP" ]] && { echo "Workshop directory not found"; exit 1; }

# ================= MONITOR DETECTION =================
if command -v hyprctl >/dev/null; then
  mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
elif command -v xrandr >/dev/null; then
  mapfile -t MONITORS < <(xrandr | awk '/ connected/ {print $1}')
else
  MONITORS=("DP-1")
fi
[[ ${#MONITORS[@]} -eq 0 ]] && MONITORS=("DP-1")

echo "Detected monitors: ${MONITORS[*]}"

# ================= BUILD LIST =================
: > "$LIST_FILE"
shopt -s nullglob

for dir in "$WORKSHOP"/*/; do
  id=$(basename "$dir")

  title="Untitled"
  type=""
  video=""
  preview=""

  if [[ -f "$dir/project.json" ]]; then
    title=$(jq -r '.title // "Untitled"' "$dir/project.json" | sed 's/<[^>]*>//g')
    type=$(jq -r '.type // empty' "$dir/project.json")
  fi

  # Detect real video (recursive, ignore previews)
  video=$(find "$dir" -type f \
    \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) \
    ! -iname "preview.*" \
    ! -iname "thumbnail.*" \
    | head -n1 || true)

  # Detect preview
  preview=$(find "$dir" -maxdepth 1 -type f \
    \( -iname "preview.*" -o -iname "thumbnail.*" \) \
    -print -quit || true)

  [[ -z "$preview" ]] && preview="(none)"

  # Final type resolution
  if [[ "$type" != "video" && "$type" != "scene" ]]; then
    [[ -n "$video" ]] && type="video" || type="scene"
  fi

  printf "%s\t%s\t%s\t%s\t%s\n" \
    "$id" "$title" "$video" "$preview" "$type" >> "$LIST_FILE"
done
# ================= LOCAL WALLPAPERS =================
if [[ -d "$IMAGE_DIR" ]]; then
  for file in "$IMAGE_DIR"/*; do
    [[ -f "$file" ]] || continue

    ext="${file##*.}"
    ext="${ext,,}"

    id="local-$(basename "$file")"
    title="$(basename "$file")"
    preview="$file"
    video=""
    type=""

    case "$ext" in
      png|jpg|jpeg|webp)
        type="static"
        ;;
      mp4|webm|mkv)
        type="video"
        video="$file"
        ;;
      *)
        continue
        ;;
    esac

    printf "%s\t%s\t%s\t%s\t%s\n" \
      "$id" "$title" "$video" "$preview" "$type" >> "$LIST_FILE"
  done
fi

shopt -u nullglob
[[ ! -s "$LIST_FILE" ]] && { echo "No wallpapers found"; exit 1; }


# ================= FZF =================
CHOICE=$(
  fzf --delimiter=$'\t' --with-nth=2 \
      --prompt="Select wallpaper: " \
      --preview='p=$(awk -F "\t" "{print \$4}" <<< {}); \
                 if [[ -f "$p" ]]; then \
                   kitty +kitten icat --clear --transfer-mode=stream --stdin=no --place=35x25@0x0 "$p" 2>/dev/null || echo "Preview failed"; \
                 else echo "No preview"; fi' \
      --preview-window=right:50%:wrap \
      < "$LIST_FILE"
)

[[ -z "${CHOICE:-}" ]] && exit 0

ID=$(awk -F $'\t' '{print $1}' <<< "$CHOICE")
NAME=$(awk -F $'\t' '{print $2}' <<< "$CHOICE")
VIDEO=$(awk -F $'\t' '{print $3}' <<< "$CHOICE")
PREVIEW=$(awk -F $'\t' '{print $4}' <<< "$CHOICE")
TYPE=$(awk -F $'\t' '{print $5}' <<< "$CHOICE")

echo "Selected: $NAME"
echo "Type: $TYPE"

# ================= OPTIONS =================
read -rp "Enable audio? (y/N): " AUDIO
AUDIO=${AUDIO,,}
read -rp "Keep fullscreen? (y/N): " FULL
FULL=${FULL,,}

# ================= STOP EXISTING =================
pkill -f mpvpaper || true
pkill -f linux-wallpaperengine || true
sleep 0.4

ENGINE="mpv"
[[ "$TYPE" == "scene" ]] && ENGINE="lwe"
[[ "$TYPE" == "static" ]] && ENGINE="static"
echo "Engine: $ENGINE"

# ================= PYWAL =================
apply_wal() {
  local img="$1"
  [[ -f "$img" ]] && wal -i "$img" --contrast >/dev/null 2>&1
}

applied=false

if [[ "$PREVIEW" != "(none)" && -f "$PREVIEW" ]]; then
  ext="${PREVIEW##*.}"
  ext="${ext,,}"

  if [[ "$ext" == "gif" ]]; then
    frame="$CACHE_DIR/${ID}_preview.png"
    ffmpeg -y -ss 0.3 -i "$PREVIEW" -frames:v 1 "$frame" >/dev/null 2>&1 || true
    [[ -f "$frame" ]] && apply_wal "$frame" && applied=true
  else
    apply_wal "$PREVIEW" && applied=true
  fi
fi
~/.config/wallset-engine/vicinae-pywal.sh
# Fallback: extract frame from video if preview failed
if [[ "$applied" == false && -n "$VIDEO" ]]; then
  frame="$CACHE_DIR/${ID}_video.png"
  ffmpeg -y -ss 1 -i "$VIDEO" -frames:v 1 "$frame" >/dev/null 2>&1 || true
  [[ -f "$frame" ]] && apply_wal "$frame"
fi

# ================= START WALLPAPER =================

echo "#!/usr/bin/env bash" > "$STARTUP_SCRIPT"
echo "pkill -f mpvpaper || true" >> "$STARTUP_SCRIPT"
echo "pkill -f linux-wallpaperengine || true" >> "$STARTUP_SCRIPT"
echo "sleep 0.4" >> "$STARTUP_SCRIPT"
if [[ "$ENGINE" == "static" ]]; then

  # Apply wallpaper (Hyprland)
  if command -v swww >/dev/null; then
    swww img "$PREVIEW" --transition-type none
  # X11 fallback
  elif command -v feh >/dev/null; then
    feh --bg-fill "$PREVIEW"
  fi

  # Write to startup script
  if command -v swww >/dev/null; then
    echo "swww img \"$PREVIEW\"" >> "$STARTUP_SCRIPT"
  elif command -v feh >/dev/null; then
    echo "feh --bg-fill \"$PREVIEW\"" >> "$STARTUP_SCRIPT"
  fi

  chmod +x "$STARTUP_SCRIPT"
  echo "Startup script saved to: $STARTUP_SCRIPT"
  echo "Done."
  exit 0
fi

if [[ "$ENGINE" == "mpv" ]]; then
  for MON in "${MONITORS[@]}"; do
    opts="loop"
    [[ "$AUDIO" != "y" ]] && opts="no-audio loop"

    cmd=(mpvpaper -vs --screen-root "$MON" -o "$opts" "$VIDEO")
    [[ "$FULL" == "y" ]] && cmd+=(--no-fullscreen-pause)

    # Run now
    nohup "${cmd[@]}" >/dev/null 2>&1 &

    # Write correctly to startup file
    {
      printf 'nohup '
      for piece in "${cmd[@]}"; do
        printf '%q ' "$piece"
      done
      printf '>/dev/null 2>&1 &\n'
    } >> "$STARTUP_SCRIPT"
  done
else
  cmd=(linux-wallpaperengine --fps "$FPS")
  [[ "$AUDIO" != "y" ]] && cmd+=(--silent)
  [[ "$FULL" == "y" ]] && cmd+=(--no-fullscreen-pause)

  for MON in "${MONITORS[@]}"; do
    cmd+=(--screen-root "$MON" --bg "$ID")
  done

  # Run now
  nohup "${cmd[@]}" >/dev/null 2>&1 &

  # Write correctly to startup file
  {
    printf 'nohup '
    for piece in "${cmd[@]}"; do
      printf '%q ' "$piece"
    done
    printf '>/dev/null 2>&1 &\n'
  } >> "$STARTUP_SCRIPT"
fi

chmod +x "$STARTUP_SCRIPT"

echo "Startup script saved to: $STARTUP_SCRIPT"
echo "Done."
