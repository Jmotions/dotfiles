#!/bin/bash
# === generate_powermenu_css.sh ===
# Generates GTK CSS for powermenu using current Pywal colors

WAL_COLORS="$HOME/.cache/wal/colors"
CSS_OUTPUT="$HOME/.config/cpmenu/powermenu.css"  # adjust path if needed

# Function to convert hex to RGB
hex2rgb() {
    local hex=${1#"#"}
    local r g b
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "$r,$g,$b"
}

# Read colors from wal
BACKGROUND=$(hex2rgb $(sed -n '1p' $WAL_COLORS))
FOREGROUND=$(hex2rgb $(sed -n '8p' $WAL_COLORS))
BUTTON=$(hex2rgb $(sed -n '6p' $WAL_COLORS))       # color4-rgb
HOVER=$(hex2rgb $(sed -n '5p' $WAL_COLORS))        # color3-rgb

# Write GTK CSS
cat > "$CSS_OUTPUT" <<EOF
/* Powermenu GTK CSS auto-generated from Pywal */

window {
    background-color: rgba($BACKGROUND,0.3);
}

button {
    border-radius: 0;
    border: 1px solid rgba($FOREGROUND,0.7);
    color: rgba($FOREGROUND,0.9);
    background-color: rgba($BUTTON,0.5);
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
    text-decoration-color: rgba($FOREGROUND,0.9);
}

button:focus, button:active, button:hover {
    background-color: rgba($HOVER,0.8);
    outline: none;
    -gtk-cursor: pointer;
}

/* Icons */
#lock { background-image: image(url("/usr/share/cpmenu/assets/lock.svg"), url("/usr/local/share/cpmenu/assets/lock.svg")); }
#logout { background-image: image(url("/usr/share/cpmenu/assets/logout.svg"), url("/usr/local/share/cpmenu/assets/logout.svg")); }
#suspend { background-image: image(url("/usr/share/cpmenu/assets/suspend.svg"), url("/usr/local/share/cpmenu/assets/suspend.svg")); }
#hibernate { background-image: image(url("/usr/share/cpmenu/assets/hibernate.svg"), url("/usr/local/share/cpmenu/assets/hibernate.svg")); }
#shutdown { background-image: image(url("/usr/share/cpmenu/assets/shutdown.svg"), url("/usr/local/share/cpmenu/assets/shutdown.svg")); }
#reboot { background-image: image(url("/usr/share/cpmenu/assets/reboot.svg"), url("/usr/local/share/cpmenu/assets/reboot.svg")); }
EOF

echo "Powermenu CSS generated at $CSS_OUTPUT"
