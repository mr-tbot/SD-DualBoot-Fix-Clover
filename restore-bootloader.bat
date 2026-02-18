@echo off
REM Steam Deck Dual Boot - Bootloader Restore Script for Windows
REM This script restores the EFI bootloader configuration for Clover dual-boot
REM Run this script as Administrator if your bootloader gets corrupted

setlocal enabledelayedexpansion

echo ================================================
echo Steam Deck Dual Boot - Bootloader Restore
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
set "EFI_MOUNT=B:"

REM Check if backup directory exists
if not exist "%BACKUP_DIR%" (
    echo [ERROR] No backups found at %BACKUP_DIR%
    echo Please run backup-bootloader.bat first to create a backup
    pause
    exit /b 1
)

REM List available backups
echo Available backups:
echo.
set count=0
for /f "delims=" %%d in ('dir /b /ad /o-d "%BACKUP_DIR%\backup_*" 2^>nul') do (
    set "backup[!count!]=%%d"
    set /a count+=1
    if exist "%BACKUP_DIR%\%%d\backup_info.txt" (
        for /f "tokens=1* delims=:" %%a in ('type "%BACKUP_DIR%\%%d\backup_info.txt" ^| findstr "Backup Date"') do (
            echo   [!count!] %%d - %%b
        )
    ) else (
        echo   [!count!] %%d
    )
)

if %count%==0 (
    echo [ERROR] No backups found
    pause
    exit /b 1
)

echo.
set /p "BACKUP_NUM=Enter backup number to restore (or 'q' to quit): "

if /i "%BACKUP_NUM%"=="q" (
    echo Restore cancelled
    pause
    exit /b 0
)

REM Validate input
if not defined backup[%BACKUP_NUM%] (
    echo [ERROR] Invalid backup number
    pause
    exit /b 1
)

set "RESTORE_PATH=%BACKUP_DIR%\!backup[%BACKUP_NUM%]!"
echo.
echo [*] Selected backup: !backup[%BACKUP_NUM%]!
if exist "%RESTORE_PATH%\backup_info.txt" (
    type "%RESTORE_PATH%\backup_info.txt"
)

echo.
echo [WARNING] This will overwrite your current bootloader configuration!
set /p "CONFIRM=Continue with restore? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Restore cancelled
    pause
    exit /b 0
)

REM Find and mount EFI partition
echo.
echo [*] Searching for EFI partition...
for /f "tokens=2 delims=:" %%a in ('mountvol ^| findstr /i "EFI"') do set EFI_VOL=%%a
if defined EFI_VOL (
    set "EFI_VOL=\\?\Volume{!EFI_VOL:~1,-1!}\"
    echo [+] Found EFI partition
) else (
    REM Try alternative method using diskpart
    echo list volume > "%TEMP%\diskpart.txt"
    for /f "tokens=2,3" %%a in ('diskpart /s "%TEMP%\diskpart.txt" ^| findstr /i "FAT.*EFI"') do (
        set "EFI_VOL=\\?\Volume{%%a}\"
    )
    del "%TEMP%\diskpart.txt"
)

echo [*] Mounting EFI partition to %EFI_MOUNT%...
mountvol %EFI_MOUNT% %EFI_VOL% 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to mount EFI partition
    pause
    exit /b 1
)

echo [+] EFI partition mounted successfully
echo.

REM Create emergency backup
set "EMERGENCY_BACKUP=%BACKUP_DIR%\emergency_before_restore_%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "EMERGENCY_BACKUP=%EMERGENCY_BACKUP: =0%"
mkdir "%EMERGENCY_BACKUP%"
echo [*] Creating emergency backup of current state...
if exist "%EFI_MOUNT%\EFI" (
    xcopy "%EFI_MOUNT%\EFI" "%EMERGENCY_BACKUP%\EFI\" /E /I /H /Y >nul 2>&1
)
if exist "%EFI_MOUNT%\Boot" (
    xcopy "%EFI_MOUNT%\Boot" "%EMERGENCY_BACKUP%\Boot\" /E /I /H /Y >nul 2>&1
)
echo [+] Emergency backup created at: %EMERGENCY_BACKUP%
echo.

REM Restore EFI directory
if exist "%RESTORE_PATH%\EFI" (
    echo [*] Restoring EFI bootloader files...
    rd /s /q "%EFI_MOUNT%\EFI" 2>nul
    xcopy "%RESTORE_PATH%\EFI" "%EFI_MOUNT%\EFI\" /E /I /H /Y >nul
    echo [+] EFI directory restored
) else (
    echo [WARNING] No EFI directory in backup
)

REM Restore Boot directory
if exist "%RESTORE_PATH%\Boot" (
    echo [*] Restoring Boot directory...
    rd /s /q "%EFI_MOUNT%\Boot" 2>nul
    xcopy "%RESTORE_PATH%\Boot" "%EFI_MOUNT%\Boot\" /E /I /H /Y >nul
    echo [+] Boot directory restored
)

REM Unmount EFI partition
mountvol %EFI_MOUNT% /D >nul 2>&1

echo.
echo [SUCCESS] Bootloader restore completed successfully!
echo.
echo [!] Please reboot your system to verify the bootloader is working
echo.
echo Emergency backup saved to: %EMERGENCY_BACKUP%
echo.

pause
exit /b 0
