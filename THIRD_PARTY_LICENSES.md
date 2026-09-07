# Third-party software & attributions

SD-DualBoot-Fix-Clover is MIT-licensed (see [LICENSE](LICENSE)). It is a set of
shell/batch scripts and documentation — no bundled third-party source, no
binaries, no submodules, no vendored trees. Everything below is invoked from
the tools the operating system already provides, or is a file that already
exists on the user's own machine.

## Invoked at run time (nothing bundled)

### GNU coreutils / util-linux / findutils / grep / awk (SteamOS side)
- **License:** GPL-2.0-or-later / GPL-3.0-or-later depending on the tool and distro build
- **Role:** `backup-bootloader.sh` and `restore-bootloader.sh` call `lsblk`, `fdisk`, `mount`, `umount`, `cp`, `rm`, `ln`, `mkdir`, `find`, `sort`, `grep`, `awk`, `date`, `hostname`. Subprocess only.

### Windows built-in utilities
- **Tools:** `mountvol`, `diskpart`, `xcopy`, `net session`
- **License:** Proprietary — part of Windows.
- **Role:** the `.bat` scripts drive these on the Windows side. Subprocess only.

### Clover EFI bootloader
- **License:** Mixed GPL-2.0 / BSD (upstream)
- **Role:** **not distributed.** The scripts only copy the user's *own* already-installed `/EFI/CLOVER` files into a backup on the user's own machine and restore them. No Clover code ships in this repository.

## Note on backups
The backups these scripts create contain Microsoft `bootmgfw.efi`, Clover EFI
binaries and Valve boot files from your own EFI system partition. That copy is
yours to keep and restore on your own machine; do not upload a backup folder
anywhere public — redistributing those binaries is not yours to do.

## Trademarks
"Clover" is the Clover EFI bootloader project; "Steam Deck" and "SteamOS" are
trademarks of Valve Corporation; "Windows" of Microsoft Corporation. Independent
community tool, not endorsed by or affiliated with any of them.
