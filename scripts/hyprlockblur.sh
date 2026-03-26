#!/bin/bash
# lock-blur.sh
SC=/tmp/lock.png
BLUR=/tmp/lock_blur.png

grim "$SC" && convert "$SC" -blur 0x8 "$BLUR"
hyprlock
