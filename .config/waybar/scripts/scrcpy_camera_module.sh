#!/bin/bash

CAMERA_ID_FILE="/tmp/scrcpy_camera_id"
PID_FILE="/tmp/scrcpy_camera_pid"
IDLE_FILE="/tmp/scrcpy_camera_idle"
V4L2_SINK="/dev/video2"

get_camera_id() {
    [ -f "$CAMERA_ID_FILE" ] && cat "$CAMERA_ID_FILE" || echo 0
}

set_camera_id() {
    echo "$1" > "$CAMERA_ID_FILE"
}

is_scrcpy_running() {
    [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1
}

start_scrcpy() {
    CAMERA_ID=$(get_camera_id)

    if adb devices -l | grep -q "usb:"; then
        DEVICE_FLAG="-d"
    else
        DEVICE_FLAG="-e"
    fi

    nohup scrcpy $DEVICE_FLAG \
        --video-source=camera \
        --camera-id="$CAMERA_ID" \
        --v4l2-sink="$V4L2_SINK" \
        --no-video-playback \
        --no-window \
        > /tmp/scrcpy_camera.log 2>&1 &

    echo "$!" > "$PID_FILE"
}

stop_scrcpy() {
    if is_scrcpy_running; then
        kill "$(cat "$PID_FILE")"
        rm -f "$PID_FILE"
    fi
}

toggle_camera() {
    stop_scrcpy
    CURRENT_ID=$(get_camera_id)
    NEW_ID=$((1 - CURRENT_ID))
    set_camera_id "$NEW_ID"
    start_scrcpy
}

check_idle_disconnect() {
    if ! is_scrcpy_running; then
        rm -f "$IDLE_FILE"
        return
    fi

    if fuser "$V4L2_SINK" >/dev/null 2>&1; then
        rm -f "$IDLE_FILE"
    else
        if [ ! -f "$IDLE_FILE" ]; then
            date +%s > "$IDLE_FILE"
        else
            START=$(cat "$IDLE_FILE")
            NOW=$(date +%s)

            if [ $((NOW - START)) -ge 40 ]; then
                stop_scrcpy
                rm -f "$IDLE_FILE"
            fi
        fi
    fi
}

handle_click() {
    case "$1" in
        1) stop_scrcpy; start_scrcpy ;;
        2) toggle_camera ;;
        3) stop_scrcpy ;;
    esac
}

# Handle Waybar click
[ -n "$1" ] && handle_click "$1"

# Check idle timeout
check_idle_disconnect

STATUS_TEXT="Pixel 6a (Off)"
TOOLTIP="Disconnected"
CLASS="disconnected"

if is_scrcpy_running; then
    CURRENT_ID=$(get_camera_id)

    STATUS_TEXT="Pixel 6a (On)"

    if [ "$CURRENT_ID" -eq 0 ]; then
        TOOLTIP="Connected (Back camera)"
        CLASS="connected-back"
    else
        TOOLTIP="Connected (Front camera)"
        CLASS="connected-front"
    fi
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
"$STATUS_TEXT" "$TOOLTIP" "$CLASS"
