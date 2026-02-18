#!/bin/bash
# Steam Deck Dual Boot - Bootloader Restore Script
# This script restores the EFI bootloader configuration for Clover dual-boot
# Run this script if your bootloader gets corrupted after an OS update

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.bootloader-backups"
EFI_MOUNT="/tmp/efi_restore_mount"

echo -e "${GREEN}Steam Deck Dual Boot - Bootloader Restore${NC}"
echo "==========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: No backups found at $BACKUP_DIR${NC}"
    echo "Please run backup-bootloader.sh first to create a backup"
    exit 1
fi

# List available backups
echo "Available backups:"
echo ""
# Use mapfile to safely read backups into array
mapfile -t BACKUPS < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" -printf "%f\n" | sort -r)
if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No backups found${NC}"
    exit 1
fi

for i in "${!BACKUPS[@]}"; do
    BACKUP_INFO="$BACKUP_DIR/${BACKUPS[$i]}/backup_info.txt"
    if [ -f "$BACKUP_INFO" ]; then
        DATE=$(grep "Backup Date:" "$BACKUP_INFO" | cut -d: -f2-)
        echo "  [$i] ${BACKUPS[$i]} -$DATE"
    else
        echo "  [$i] ${BACKUPS[$i]}"
    fi
done

echo ""
echo -e "${YELLOW}Enter backup number to restore (or 'q' to quit):${NC}"
read -r BACKUP_NUM

if [ "$BACKUP_NUM" = "q" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Validate input
if ! [[ "$BACKUP_NUM" =~ ^[0-9]+$ ]] || [ "$BACKUP_NUM" -ge ${#BACKUPS[@]} ]; then
    echo -e "${RED}Error: Invalid backup number${NC}"
    exit 1
fi

RESTORE_PATH="$BACKUP_DIR/${BACKUPS[$BACKUP_NUM]}"
echo ""
echo -e "${YELLOW}Selected backup: ${BACKUPS[$BACKUP_NUM]}${NC}"
if [ -f "$RESTORE_PATH/backup_info.txt" ]; then
    cat "$RESTORE_PATH/backup_info.txt"
fi

echo ""
echo -e "${RED}WARNING: This will overwrite your current bootloader configuration!${NC}"
echo -e "${YELLOW}Continue with restore? (yes/no):${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Find EFI partition
EFI_PARTITION=$(lsblk -o NAME,PARTLABEL | grep -i "esp\|efi" | head -1 | awk '{print $1}')
if [ -z "$EFI_PARTITION" ]; then
    # Try alternative method
    EFI_PARTITION=$(fdisk -l | grep -i "efi system" | head -1 | awk '{print $1}')
fi

if [ -z "$EFI_PARTITION" ]; then
    echo -e "${RED}Error: Could not find EFI partition${NC}"
    exit 1
fi

# Ensure proper device path
if [[ ! "$EFI_PARTITION" =~ ^/dev/ ]]; then
    EFI_PARTITION="/dev/$EFI_PARTITION"
fi

echo ""
echo -e "${YELLOW}Found EFI partition: $EFI_PARTITION${NC}"
echo ""

# Create mount point
mkdir -p "$EFI_MOUNT"

# Mount EFI partition
echo "Mounting EFI partition..."
if mount | grep -q "$EFI_MOUNT"; then
    umount "$EFI_MOUNT" 2>/dev/null || true
fi

mount "$EFI_PARTITION" "$EFI_MOUNT"

# Create a backup of current state before restore
EMERGENCY_BACKUP="$BACKUP_DIR/emergency_before_restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EMERGENCY_BACKUP"
echo "Creating emergency backup of current state..."
cp -r "$EFI_MOUNT/EFI" "$EMERGENCY_BACKUP/" 2>/dev/null || true
cp -r "$EFI_MOUNT/Boot" "$EMERGENCY_BACKUP/" 2>/dev/null || true
echo -e "${GREEN}✓ Emergency backup created at: $EMERGENCY_BACKUP${NC}"
echo ""

# Restore EFI directory
if [ -d "$RESTORE_PATH/EFI" ]; then
    echo "Restoring EFI bootloader files..."
    # Remove old EFI directory
    rm -rf "$EFI_MOUNT/EFI" 2>/dev/null || true
    # Copy backup
    cp -r "$RESTORE_PATH/EFI" "$EFI_MOUNT/"
    echo -e "${GREEN}✓ EFI directory restored${NC}"
else
    echo -e "${YELLOW}Warning: No EFI directory in backup${NC}"
fi

# Restore Boot directory
if [ -d "$RESTORE_PATH/Boot" ]; then
    echo "Restoring Boot directory..."
    rm -rf "$EFI_MOUNT/Boot" 2>/dev/null || true
    cp -r "$RESTORE_PATH/Boot" "$EFI_MOUNT/"
    echo -e "${GREEN}✓ Boot directory restored${NC}"
fi

# Sync filesystem
sync

# Unmount EFI partition
umount "$EFI_MOUNT"
rmdir "$EFI_MOUNT"

echo ""
echo -e "${GREEN}Bootloader restore completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Please reboot your system to verify the bootloader is working${NC}"
echo ""
echo "Emergency backup saved to: $EMERGENCY_BACKUP"
echo ""

exit 0
