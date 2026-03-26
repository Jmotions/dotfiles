#!/bin/bash
colors_file="$HOME/.cache/wal/colors"
readarray -t colors < "$colors_file"

hex_to_rgb() {
    local hex=${1#"#"}
    echo "$((16#${hex:0:2})),$((16#${hex:2:2})),$((16#${hex:4:2}))"
}

active_rgb=$(hex_to_rgb "${colors[1]}")
inactive_rgb=$(hex_to_rgb "${colors[8]}")

cat <<EOF > "$HOME/.config/hypr/pywal-colors.conf"
# Auto-generated

col.active_border = rgba($active_rgb,1)
col.inactive_border = rgba($inactive_rgb,1)
EOF

