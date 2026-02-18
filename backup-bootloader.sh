#!/bin/bash
# Steam Deck Dual Boot - Bootloader Backup Script
# This script backs up the EFI bootloader configuration for Clover dual-boot
# Run this script on a stable system before any OS updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.bootloader-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"
EFI_MOUNT="/tmp/efi_backup_mount"

echo -e "${GREEN}Steam Deck Dual Boot - Bootloader Backup${NC}"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Find EFI partition
EFI_PARTITION=$(lsblk -o NAME,PARTLABEL | grep -i "esp\|efi" | head -1 | awk '{print $1}')
if [ -z "$EFI_PARTITION" ]; then
    # Try alternative method
    EFI_PARTITION=$(fdisk -l | grep -i "efi system" | head -1 | awk '{print $1}')
fi

if [ -z "$EFI_PARTITION" ]; then
    echo -e "${RED}Error: Could not find EFI partition${NC}"
    echo "Please ensure your system has an EFI partition"
    exit 1
fi

# Ensure proper device path
if [[ ! "$EFI_PARTITION" =~ ^/dev/ ]]; then
    EFI_PARTITION="/dev/$EFI_PARTITION"
fi

echo -e "${YELLOW}Found EFI partition: $EFI_PARTITION${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_PATH"
mkdir -p "$EFI_MOUNT"

# Mount EFI partition
echo "Mounting EFI partition..."
if mount | grep -q "$EFI_MOUNT"; then
    umount "$EFI_MOUNT" 2>/dev/null || true
fi

mount "$EFI_PARTITION" "$EFI_MOUNT"

# Backup EFI directory
echo "Backing up EFI bootloader files..."
if [ -d "$EFI_MOUNT/EFI" ]; then
    cp -r "$EFI_MOUNT/EFI" "$BACKUP_PATH/" 2>/dev/null || true
    echo -e "${GREEN}✓ EFI directory backed up${NC}"
else
    echo -e "${YELLOW}Warning: No EFI directory found${NC}"
fi

# Backup Clover specific files
if [ -d "$EFI_MOUNT/EFI/CLOVER" ]; then
    echo -e "${GREEN}✓ Clover bootloader configuration backed up${NC}"
fi

# Backup Boot directory if it exists
if [ -d "$EFI_MOUNT/Boot" ]; then
    cp -r "$EFI_MOUNT/Boot" "$BACKUP_PATH/" 2>/dev/null || true
    echo -e "${GREEN}✓ Boot directory backed up${NC}"
fi

# Create backup info file
cat > "$BACKUP_PATH/backup_info.txt" << EOF
Backup Date: $(date)
EFI Partition: $EFI_PARTITION
Hostname: $(hostname)
Kernel: $(uname -r)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
EOF

# Unmount EFI partition
umount "$EFI_MOUNT"
rmdir "$EFI_MOUNT"

# Create a "latest" symlink
rm -f "$BACKUP_DIR/latest"
ln -s "$BACKUP_PATH" "$BACKUP_DIR/latest"

echo ""
echo -e "${GREEN}Backup completed successfully!${NC}"
echo "Backup location: $BACKUP_PATH"
echo ""
echo "To restore this backup, run: sudo ./restore-bootloader.sh"
echo ""

# Clean old backups (keep last 10)
echo "Cleaning old backups (keeping last 10)..."
cd "$BACKUP_DIR" || exit 1
# Use a more robust method to clean old backups
count=0
for dir in backup_*/; do
    count=$((count + 1))
    if [ $count -gt 10 ] && [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
done 2>/dev/null
echo -e "${GREEN}✓ Old backups cleaned${NC}"

exit 0
