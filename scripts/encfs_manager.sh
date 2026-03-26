#!/bin/bash
# encfs_manager.sh - Simple script to manage EncFS

ENCRYPTED_DIR="$HOME/.encrypted_data"
MOUNT_DIR="$HOME/my_secure_folder"

# Create directories if they don't exist
mkdir -p "$ENCRYPTED_DIR"
mkdir -p "$MOUNT_DIR"

case "$1" in
    mount)
        echo "Mounting EncFS..."
        encfs "$ENCRYPTED_DIR" "$MOUNT_DIR"
        ;;
    umount|unmount)
        echo "Unmounting EncFS..."
        fusermount -u "$MOUNT_DIR"
        ;;
    -h|--help)
        echo "EncFS Manager Script"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  mount      Mount the encrypted folder"
        echo "  umount     Unmount the encrypted folder"
        echo "  -h, --help Show this help message"
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage."
        ;;
esac
