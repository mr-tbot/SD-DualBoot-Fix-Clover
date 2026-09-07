# SD-DualBoot-Fix-Clover
A backup and restore method for users using a steam deck - dual booted with SteamOS and Windows.  SteamOS and Windows like to break each other's bootloaders - this set of scripts aims to alleviate the problem associated with corrupted bootloaders when updates occur.  Simply run on a stable system (runs on both SteamOS and Windows)

## License

Released under the [MIT License](LICENSE) — Copyright (c) 2026 mr-tbot.

These scripts are original glue code and **bundle nothing**. They call the tools your OS already ships — `lsblk`, `fdisk`, `mount`, `cp` on SteamOS; `mountvol`, `diskpart`, `xcopy` on Windows — and they copy your *own* already-installed EFI files into a backup folder on your *own* machine. No Clover, Valve or Microsoft code is redistributed by this repository. Full attribution in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

Note that the backups these scripts create *do* contain Microsoft and Clover boot binaries from your ESP. That copy is yours to keep and restore, but please don't upload a backup folder anywhere public — redistributing those binaries is not yours to do.

"Clover" is the Clover EFI bootloader project; "Steam Deck" and "SteamOS" are trademarks of Valve Corporation; "Windows" is a trademark of Microsoft Corporation. This is an independent community tool, not endorsed by or affiliated with any of them.

⚠️ These scripts erase and rewrite your EFI system partition. As the MIT license says in full caps, they come with **absolutely no warranty** — a failed restore can leave your Deck unbootable. Use at your own risk, and keep a way to boot from external media.
