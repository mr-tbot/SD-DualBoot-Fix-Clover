@echo off
REM Steam Deck Dual Boot - Bootloader Backup Script for Windows
REM This script backs up the EFI bootloader configuration for Clover dual-boot
REM Run this script as Administrator before any OS updates

setlocal enabledelayedexpansion

echo ================================================
echo Steam Deck Dual Boot - Bootloader Backup
echo ================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator
    echo Right-click the script and select "Run as administrator"
    pause
    exit /b 1
)

REM Configuration
set "BACKUP_DIR=%USERPROFILE%\.bootloader-backups"
REM Note: Timestamp format assumes standard Windows date format (locale-dependent)
REM For systems with different regional settings, adjust the substring indices accordingly
set "TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "BACKUP_PATH=%BACKUP_DIR%\backup_%TIMESTAMP%"
set "EFI_MOUNT=B:"

REM Create backup directory
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
mkdir "%BACKUP_PATH%"

REM Find and mount EFI partition
echo [*] Searching for EFI partition...
for /f "tokens=2 delims=:" %%a in ('mountvol ^| findstr /i "EFI"') do set EFI_VOL=%%a
if defined EFI_VOL (
    set "EFI_VOL=\\?\Volume{!EFI_VOL:~1,-1!}\"
    echo [+] Found EFI partition
) else (
    REM Try alternative method using diskpart
    REM Note: This fallback method may not work reliably on all systems
    REM If you encounter issues, ensure the EFI partition is properly mounted
    echo [*] Trying alternative EFI detection method...
    echo list volume > "%TEMP%\diskpart.txt"
    for /f "tokens=2,3" %%a in ('diskpart /s "%TEMP%\diskpart.txt" ^| findstr /i "FAT.*EFI"') do (
        set "EFI_VOL=\\?\Volume{%%a}\"
    )
    del "%TEMP%\diskpart.txt"
    if defined EFI_VOL (
        echo [+] Found EFI partition using alternative method
    ) else (
        echo [ERROR] Could not find EFI partition using any method
        echo Please ensure your system has an accessible EFI partition
        pause
        exit /b 1
    )
)

echo [*] Mounting EFI partition to %EFI_MOUNT%...
mountvol %EFI_MOUNT% %EFI_VOL% 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to mount EFI partition
    echo Please ensure your system has an accessible EFI partition
    pause
    exit /b 1
)

echo [+] EFI partition mounted successfully
echo.

REM Backup EFI directory
echo [*] Backing up EFI bootloader files...
if exist "%EFI_MOUNT%\EFI" (
    xcopy "%EFI_MOUNT%\EFI" "%BACKUP_PATH%\EFI\" /E /I /H /Y >nul
    echo [+] EFI directory backed up
) else (
    echo [WARNING] No EFI directory found
)

REM Check for Clover
if exist "%EFI_MOUNT%\EFI\CLOVER" (
    echo [+] Clover bootloader configuration backed up
)

REM Backup Boot directory
if exist "%EFI_MOUNT%\Boot" (
    xcopy "%EFI_MOUNT%\Boot" "%BACKUP_PATH%\Boot\" /E /I /H /Y >nul
    echo [+] Boot directory backed up
)

REM Create backup info file
(
echo Backup Date: %date% %time%
echo Computer: %COMPUTERNAME%
echo OS: %OS%
echo User: %USERNAME%
) > "%BACKUP_PATH%\backup_info.txt"

REM Unmount EFI partition
mountvol %EFI_MOUNT% /D >nul 2>&1

echo.
echo [SUCCESS] Backup completed successfully!
echo Backup location: %BACKUP_PATH%
echo.
echo To restore this backup, run: restore-bootloader.bat (as Administrator)
echo.

REM Clean old backups (keep last 10)
echo [*] Cleaning old backups (keeping last 10)...
set count=0
for /f "skip=10 delims=" %%d in ('dir /b /ad /o-d "%BACKUP_DIR%\backup_*" 2^>nul') do (
    rd /s /q "%BACKUP_DIR%\%%d" 2>nul
)
echo [+] Old backups cleaned
echo.

pause
exit /b 0
