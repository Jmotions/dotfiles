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

# ================= ARG PARSING =================
NO_AUTOMUTE=false
for arg in "$@"; do
  if [[ "$arg" == "--noautomute" ]]; then
    NO_AUTOMUTE=true
    shift # Remove --noautomute from arguments passed to fzf
  fi
done

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

# Combine workshop and local files into one list
items=()
[[ -d "$WORKSHOP" ]] && items+=("$WORKSHOP"/*/)
[[ -d "$IMAGE_DIR" ]] && items+=("$IMAGE_DIR"/*)

# Sort the combined list by modification time, newest first
# `ls -dt` sorts by modification time descending.
# Using nullglob is important. If items is empty, it should not cause an error.
if (( ${#items[@]} > 0 )); then
    mapfile -t sorted_items < <(ls -dt -- "${items[@]}")
else
    sorted_items=()
fi

for item in "${sorted_items[@]}"; do
    if [[ ! -e "$item" ]]; then
        continue
    fi

    if [[ -d "$item" ]]; then # Workshop item
        dir="$item"
        id=$(basename "$dir")

        title="Untitled"
        type=""
        video=""
        preview=""

        if [[ -f "$dir/project.json" ]]; then
            title=$(jq -r '.title // "Untitled"' "$dir/project.json" | sed 's/<[^>]*>//g')
            type=$(jq -r '.type // empty' "$dir/project.json")
        fi
        title="[${id}] ${title}"

        video=$(find "$dir" -type f \
            \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) \
            ! -iname "preview.*" \
            ! -iname "thumbnail.*" \
            | head -n1 || true)

        preview=$(find "$dir" -maxdepth 1 -type f \
            \( -iname "preview.*" -o -iname "thumbnail.*" \) \
            -print -quit || true)

        [[ -z "$preview" ]] && preview="(none)"

        if [[ "$type" != "video" && "$type" != "scene" ]]; then
            [[ -n "$video" ]] && type="video" || type="scene"
        fi

        printf "%s\t%s\t%s\t%s\t%s\n" \
            "$id" "$title" "$video" "$preview" "$type" >> "$LIST_FILE"

    elif [[ -f "$item" ]]; then # Local wallpaper
        file="$item"
        ext="${file##*.}"
        ext="${ext,,}"

        id="local-$(basename "$file")"
        title="$(basename "$file")"
        title="[${id}] ${title}"
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
    fi
done

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

# Prompt for automute if audio is enabled
AUTOMUTE=true # Default to automute behavior (i.e., do NOT pass --noautomute to mpvpaper/lwe)
if [[ "$AUDIO" == "y" ]]; then
  read -rp "Pause audio when other apps play sound (automute)? (Y/n): " AUTOMUTE_INPUT
  AUTOMUTE_INPUT=${AUTOMUTE_INPUT,,}
  [[ "$AUTOMUTE_INPUT" == "n" ]] && AUTOMUTE=false # If user says 'n', set AUTOMUTE to false (meaning pass --noautomute)
fi

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
    # If AUTOMUTE is false and audio is enabled, add mpv option to prevent auto-pausing
    [[ "$AUTOMUTE" == "false" && "$AUDIO" == "y" ]] && opts+=" --no-input-default-bindings"

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
  # If AUTOMUTE is false and audio is enabled, add --noautomute flag
  [[ "$AUTOMUTE" == "false" && "$AUDIO" == "y" ]] && cmd+=(--noautomute)

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
