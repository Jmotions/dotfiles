#!/bin/bash
# ==============================================
# Prepare Windows EFI Boot from Linux
# ==============================================
# Usage: sudo ./win_efi_prep.sh
# Requirements: ntfs-3g, efibootmgr, wimlib (optional if extracting from install.wim)
# ==============================================

set -e

# -----------------------------
# Paths / Devices (edit if needed)
# -----------------------------
WIN_PART="/run/media/jahmad/98C2A275C2A256F2"   # existing mount of Windows NTFS
ESP_PART="/mnt/esp"                               # existing mount of EFI partition
WIN_ISO="/run/media/jahmad/ESD-USB"              # Windows ISO mount path

# -----------------------------
# Step 0: Check mounts
# -----------------------------
if [ ! -d "$WIN_PART" ]; then
    echo "Error: Windows partition not mounted at $WIN_PART"
    exit 1
fi

if [ ! -d "$ESP_PART" ]; then
    echo "Error: ESP not mounted at $ESP_PART"
    exit 1
fi

# -----------------------------
# Step 1: Create EFI directory
# -----------------------------
sudo mkdir -p "$WIN_PART/boot/efi/EFI/Microsoft/Boot"
echo "Created EFI directory..."

# -----------------------------
# Step 2: Copy EFI files from ISO
# -----------------------------
if [ -d "$WIN_ISO/efi" ]; then
    sudo cp -r "$WIN_ISO/efi/." "$WIN_PART/boot/efi/EFI/Microsoft/Boot/"
    echo "Copied EFI files from ISO."
else
    echo "Warning: ISO EFI folder not found. Skipping copy."
fi

# -----------------------------
# Step 3: Extract BCD from install.wim (optional)
# -----------------------------
if [ -f "$WIN_ISO/sources/install.wim" ]; then
    sudo pacman -S --noconfirm wimlib 2>/dev/null || echo "wimlib not found, skipping BCD extraction"
    mkdir -p /tmp/win_wim
    sudo wimextract "$WIN_ISO/sources/install.wim" 1 Windows/Boot/EFI/* -d /tmp/win_wim
    sudo cp -r /tmp/win_wim/Windows/Boot/EFI/* "$WIN_PART/boot/efi/EFI/Microsoft/Boot/"
    echo "Extracted BCD from install.wim"
    rm -rf /tmp/win_wim
fi

# -----------------------------
# Step 4: Register UEFI entry
# -----------------------------
sudo efibootmgr -c -d /dev/nvme0n1 -p 2 -L "Windows" -l '\EFI\Microsoft\Boot\bootmgfw.efi'
echo "Registered Windows boot entry in UEFI."

# -----------------------------
# Step 5: Done
# -----------------------------
echo "EFI prep complete. Reboot and check for Windows entry in UEFI menu."
