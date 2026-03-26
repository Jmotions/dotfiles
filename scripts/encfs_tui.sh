#!/bin/bash

# encfs_tui.sh - TUI script to manage EncFS using fsel

ENCRYPTED_DIR="$HOME/.encrypted_data"
MOUNT_DIR="$HOME/my_secure_folder"

# Create directories if they don't exist
mkdir -p "$ENCRYPTED_DIR"
mkdir -p "$MOUNT_DIR"

# Use fsel to present options
SELECTION=$(echo -e "Mount\nUnmount" | fsel --dmenu)

# Execute command based on selection
case "$SELECTION" in
    Mount)
        echo "Mounting EncFS..."
        encfs "$ENCRYPTED_DIR" "$MOUNT_DIR"
        ;;
    Unmount)
        echo "Unmounting EncFS..."
        fusermount -u "$MOUNT_DIR"
        ;;
    *)
        echo "No option selected."
        ;;
esac
