#!/bin/bash

CAMERA_ID_FILE="/tmp/scrcpy_camera_id"
PID_FILE="/tmp/scrcpy_camera_pid"
V4L2_SINK="/dev/video2"



get_camera_id() {
    if [ -f "$CAMERA_ID_FILE" ]; then
        cat "$CAMERA_ID_FILE"
    else
        echo "0" # Default to back camera
    fi
}

set_camera_id() {
    echo "$1" > "$CAMERA_ID_FILE"
}

is_scrcpy_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            return 0 # Running
        else
            rm "$PID_FILE"
            return 1 # Not running
        fi
    else
        return 1 # Not running
    fi
}

#!/bin/bash

CAMERA_ID_FILE="/tmp/scrcpy_camera_id"
PID_FILE="/tmp/scrcpy_camera_pid"
V4L2_SINK="/dev/video2"
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

get_camera_id() {
    if [ -f "$CAMERA_ID_FILE" ]; then
        cat "$CAMERA_ID_FILE"
    else
        echo "0" # Default to back camera
    fi
}

set_camera_id() {
    echo "$1" > "$CAMERA_ID_FILE"
}

is_scrcpy_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            return 0 # Running
        else
            rm "$PID_FILE"
            return 1 # Not running
        fi
    else
        return 1 # Not running
    fi
}

start_scrcpy() {
    CAMERA_ID=$(get_camera_id)
    nohup scrcpy --video-source=camera --camera-id="$CAMERA_ID" --v4l2-sink="$V4L2_SINK" --no-video-playback --no-window > /tmp/scrcpy_camera.log 2>&1 &
    echo "$!" > "$PID_FILE"
}

stop_scrcpy() {
    if is_scrcpy_running; then
        PID=$(cat "$PID_FILE")
        kill "$PID"
        rm "$PID_FILE"
    fi
}

toggle_camera() {
    stop_scrcpy
    CURRENT_ID=$(get_camera_id)
    NEW_ID=$((1 - CURRENT_ID)) # Toggle between 0 and 1
    set_camera_id "$NEW_ID"
    start_scrcpy
}

handle_click() {
    case "$1" in
        "1") # Left click - connect/reconnect
            stop_scrcpy
            start_scrcpy
            ;;
        "2") # Middle click - toggle camera
            toggle_camera
            ;;
        "3") # Right click - stop camera
            stop_scrcpy
            ;;
    esac
}

# Main logic for Waybar output
if [ -n "$1" ]; then
    handle_click "$1"
fi
STATUS_TEXT="Pixel 6a"
TOOLTIP="Disconnected"
CLASS="disconnected"

if is_scrcpy_running; then
    CURRENT_ID=$(get_camera_id)

    if [ "$CURRENT_ID" -eq "0" ]; then
        TOOLTIP="Connected (Back)"
        CLASS="connected-back"
    else
        TOOLTIP="Connected (Front)"
        CLASS="connected-front"
    fi
fi


# Output for Waybar
printf '{"text":"%s","alt":"Cam","tooltip":"%s","class":"%s"}\n' \
"$STATUS_TEXT" "$TOOLTIP" "$CLASS"

stop_scrcpy() {
    if is_scrcpy_running; then
        PID=$(cat "$PID_FILE")
        kill "$PID"
        rm "$PID_FILE"
    fi
}
check_idle_disconnect() {
    IDLE_FILE="/tmp/scrcpy_camera_idle"

    if fuser /dev/video2 >/dev/null 2>&1; then
        # Camera is being used
        rm -f "$IDLE_FILE"
    else
        # Camera not in use
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

toggle_camera() {
    stop_scrcpy
    CURRENT_ID=$(get_camera_id)
    NEW_ID=$((1 - CURRENT_ID)) # Toggle between 0 and 1
    set_camera_id "$NEW_ID"
    start_scrcpy
}

handle_click() {
    case "$1" in
        "1") # Left click - connect/reconnect
            stop_scrcpy
            start_scrcpy
            ;;
        "2") # Middle click - toggle camera
            toggle_camera
            ;;
        "3") # Right click - stop camera
            stop_scrcpy
            ;;
    esac
}

# Main logic for Waybar output
if [ -n "$1" ]; then
    handle_click "$1"
fi

STATUS_TEXT="Disconnected"
TOOLTIP="Left-click to connect, Right-click to disable"
CLASS="disconnected"
CAMERA_STATE=""

if is_scrcpy_running; then
    CURRENT_ID=$(get_camera_id)
    if [ "$CURRENT_ID" -eq "0" ]; then
        CAMERA_STATE=" (Back)"
        CLASS="connected-back"
    else
        CAMERA_STATE=" (Front)"
        CLASS="connected-front"
    fi
    STATUS_TEXT="Connected$CAMERA_STATE"
    TOOLTIP="Left-click to reconnect, Middle-click to flip camera, Right-click to disable"
fi

# Output for Waybar
printf '{"text":"%s","alt":"Cam","tooltip":"%s","class":"%s"}\n' \
"$STATUS_TEXT" "$TOOLTIP" "$CLASS"

