# SD-DualBoot-Fix-Clover

A backup and restore method for users using a Steam Deck dual-booted with SteamOS and Windows. SteamOS and Windows updates can break each other's bootloaders - this set of scripts helps alleviate problems associated with corrupted bootloaders when updates occur.

## Overview

When running a dual-boot setup on Steam Deck with Clover bootloader:
- **SteamOS updates** can overwrite Windows boot entries
- **Windows updates** can overwrite the Clover bootloader
- This results in being unable to boot into one or both operating systems

These scripts provide a simple backup and restore solution that works on **both SteamOS and Windows**.

## Features

- ✅ Backs up complete EFI bootloader configuration
- ✅ Backs up Clover bootloader settings
- ✅ Works on both SteamOS (Linux) and Windows
- ✅ Automatic backup rotation (keeps last 10 backups)
- ✅ Emergency backup before restore operations
- ✅ Simple command-line interface

## Requirements

### SteamOS / Linux
- Root access (sudo privileges)
- Bash shell
- Standard Linux utilities (lsblk, mount, etc.)

### Windows
- Administrator privileges
- Command Prompt or PowerShell
- Windows 10 or later
- **Note**: Windows scripts assume US date/time format. If you use a different regional setting, timestamps may not format correctly, but backups will still function.

## Installation

1. Download or clone this repository to your Steam Deck
2. The scripts are ready to use - no installation needed!

## Usage

### Creating a Backup

**Important:** Always create a backup when your system is working properly, **before** performing any OS updates!

#### On SteamOS / Linux:
```bash
sudo ./backup-bootloader.sh
```

#### On Windows:
1. Right-click `backup-bootloader.bat`
2. Select "Run as administrator"

The backup will be saved to:
- **Linux**: `~/.bootloader-backups/`
- **Windows**: `%USERPROFILE%\.bootloader-backups\`

### Restoring a Backup

If your bootloader gets corrupted after an update, restore from a previous backup:

#### On SteamOS / Linux:
```bash
sudo ./restore-bootloader.sh
```
- Select a backup from the list
- Confirm the restoration
- Reboot your system

#### On Windows:
1. Right-click `restore-bootloader.bat`
2. Select "Run as administrator"
3. Select a backup from the list
4. Confirm the restoration
5. Reboot your system

## Best Practices

1. **Create backups regularly:**
   - Before any SteamOS update
   - Before any Windows update
   - After successfully configuring your dual-boot

2. **Keep multiple backups:**
   - The scripts automatically keep the last 10 backups
   - This gives you multiple restore points

3. **Test after updates:**
   - After any OS update, verify both operating systems still boot
   - If one fails, immediately restore from backup

4. **Emergency backup:**
   - The restore script automatically creates an emergency backup before restoration
   - This provides an additional safety net

## What Gets Backed Up

The scripts back up the following from your EFI partition:
- `/EFI/` directory (all bootloader configurations)
- `/EFI/CLOVER/` (Clover bootloader specific files)
- `/Boot/` directory (boot files)
- System information (date, hostname, OS version)

## Troubleshooting

### "Cannot find EFI partition"
- Ensure your system uses UEFI boot mode (not legacy BIOS)
- Check if your EFI partition is properly formatted (FAT32)
- Verify the partition has the correct flags set
- **Windows**: The primary detection method (mountvol) should work on most systems. If you encounter issues, ensure Windows can access the EFI partition.

### "Permission denied"
- On Linux: Make sure you run with `sudo`
- On Windows: Run as Administrator (right-click → Run as administrator)

### Bootloader still broken after restore
1. Try restoring from an older backup
2. Check if the EFI partition has sufficient space
3. Verify the backup files are not corrupted
4. Consider reinstalling Clover bootloader from scratch

### Scripts won't run on Linux
```bash
chmod +x backup-bootloader.sh restore-bootloader.sh
```

## Safety Features

- **Non-destructive backups**: Original bootloader files are never modified during backup
- **Emergency backups**: Restore script creates a backup before overwriting
- **Confirmation prompts**: Restore requires explicit confirmation
- **Backup validation**: Stores metadata with each backup for verification

## Contributing

Issues, suggestions, and pull requests are welcome! This is a community tool to help Steam Deck dual-boot users.

## License

This project is provided as-is for the Steam Deck community. Use at your own risk.

## Disclaimer

⚠️ **Important:** Always maintain backups of your important data. While these scripts are designed to help recover from bootloader issues, they may not solve all problems. If you're uncomfortable with command-line tools or system administration, consider seeking help from experienced users.

## Known Limitations

- **Windows timestamp format**: The Windows batch scripts use locale-specific date formatting. On systems with non-US regional settings, the backup timestamp format may differ, but functionality is not affected.
- **EFI partition access**: Requires proper UEFI boot configuration and accessible EFI partition on both operating systems.

## Credits

Created for the Steam Deck dual-boot community. Special thanks to users running Clover bootloader configurations.
