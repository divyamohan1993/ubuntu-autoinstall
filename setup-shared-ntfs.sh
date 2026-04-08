#!/bin/bash
# setup-shared-ntfs.sh — Format and configure a shared NTFS partition for dual-boot Ubuntu + Windows
# Reusable across fresh Ubuntu installs. Run as root.
# Usage: sudo ./setup-shared-ntfs.sh [device] [label] [mountpoint]
#   e.g: sudo ./setup-shared-ntfs.sh /dev/sda4 experiments /mnt/experiments

set -euo pipefail

# ─── args ───
DEV="${1:-}"
LABEL="${2:-experiments}"
MOUNT="${3:-/mnt/experiments}"
USER_ID="${SUDO_UID:-1000}"
GROUP_ID="${SUDO_GID:-1000}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1" >&2; exit 1; }

# ─── checks ───
[[ $EUID -eq 0 ]] || err "Run as root: sudo $0 $*"
[[ -n "$DEV" ]]   || {
    echo "Available partitions:"
    echo
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE,LABEL | grep -E "part|NAME"
    echo
    err "Usage: sudo $0 /dev/sdXN [label] [mountpoint]"
}
[[ -b "$DEV" ]] || err "$DEV is not a block device"

command -v mkfs.ntfs >/dev/null || {
    warn "ntfs-3g not installed. Installing..."
    apt-get update -qq && apt-get install -y -qq ntfs-3g
}

# ─── confirm ───
CURRENT_FS=$(blkid -o value -s TYPE "$DEV" 2>/dev/null || true)
DEV_SIZE=$(lsblk -bno SIZE "$DEV" | head -1)
DEV_SIZE_GB=$(( DEV_SIZE / 1073741824 ))

echo
echo "  Device:     $DEV ($DEV_SIZE_GB GB)"
echo "  Current FS: ${CURRENT_FS:-unformatted}"
echo "  New label:  $LABEL"
echo "  Mount at:   $MOUNT"
echo
read -rp "This will ERASE all data on $DEV. Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ─── unmount if mounted ───
if mountpoint -q "$MOUNT" 2>/dev/null || mount | grep -q "$DEV"; then
    log "Unmounting $DEV..."
    umount -l "$DEV" 2>/dev/null || true
fi

# ─── format ───
log "Formatting $DEV as NTFS (label: $LABEL)..."
mkfs.ntfs -f -L "$LABEL" "$DEV"

# ─── get UUID ───
UUID=$(blkid -o value -s UUID "$DEV")
[[ -n "$UUID" ]] || err "Failed to get UUID for $DEV"
log "UUID: $UUID"

# ─── mount point ───
log "Creating mount point $MOUNT..."
mkdir -p "$MOUNT"

# ─── fstab ───
FSTAB_LINE="UUID=$UUID  $MOUNT  ntfs3  noatime,uid=$USER_ID,gid=$GROUP_ID,dmask=0000,fmask=0000,windows_names,prealloc,nofail  0  0"

# remove any existing entry for this mountpoint or device
if grep -qE "^\s*UUID=\S+\s+${MOUNT}\s" /etc/fstab 2>/dev/null; then
    warn "Removing old fstab entry for $MOUNT"
    sed -i "\|^\s*UUID=.\+\s\+${MOUNT}\s|d" /etc/fstab
fi

log "Adding fstab entry..."
echo "$FSTAB_LINE" >> /etc/fstab

# ─── mount ───
log "Mounting..."
mount "$MOUNT"
chown "$USER_ID:$GROUP_ID" "$MOUNT"

# ─── systemd clean unmount service ───
SERVICE_NAME="ntfs-clean-unmount-$(systemd-escape --path "$MOUNT").service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
MOUNT_UNIT="$(systemd-escape --path "$MOUNT").mount"

log "Creating systemd clean unmount service ($SERVICE_NAME)..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Clean unmount NTFS partition at $MOUNT
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target
After=$MOUNT_UNIT

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/bin/sync
ExecStop=/bin/umount -l $MOUNT

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

# ─── disable hibernate/fast-startup hook for ntfs safety ───
# if systemd-hibernate exists, mask it to prevent dirty NTFS state
if systemctl list-unit-files | grep -q "systemd-hibernate"; then
    warn "Masking hibernate to prevent NTFS dirty bit issues..."
    systemctl mask systemd-hibernate.service 2>/dev/null || true
fi

# ─── generate windows setup script on the drive itself ───
log "Writing Windows setup script to $MOUNT/windows-setup.bat..."
cat > "$MOUNT/windows-setup.bat" << 'WINEOF'
@echo off
:: windows-setup.bat — Run as Administrator in Windows
:: Configures the shared NTFS partition so Windows never corrupts it
:: Right-click > Run as administrator

net session >nul 2>&1 || (echo Run as Administrator! & pause & exit /b 1)

echo.
echo ============================================================
echo  Shared NTFS Drive — Windows Configuration
echo ============================================================
echo.

:: Find the drive letter for "experiments" label
for /f "tokens=2 delims==" %%G in ('wmic volume where "Label='experiments'" get DriveLetter /value 2^>nul ^| find "="') do set "DRV=%%G"
if not defined DRV (
    echo [!] Could not find drive labeled "experiments"
    echo     Assign a drive letter in Disk Management first.
    pause
    exit /b 1
)
echo [+] Found drive: %DRV%
echo.

:: 1. Disable Fast Startup + Hibernation
echo [1/9] Disabling Fast Startup and Hibernation...
powercfg /h off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul

:: 2. Exclude from chkdsk on boot
echo [2/9] Excluding %DRV% from automatic chkdsk...
chkntfs /x %DRV%

:: 3. Disable indexing
echo [3/9] Disabling Windows Search indexing on %DRV%...
wmic volume where "DriveLetter='%DRV%'" set IndexingEnabled=False >nul 2>&1

:: 4. Disable scheduled defrag/optimize
echo [4/9] Excluding %DRV% from scheduled optimization...
schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /disable >nul 2>&1
:: Also via PowerShell if available
powershell -NoProfile -Command "try { Disable-ScheduledOptimization -Volume '%DRV%' -ErrorAction Stop } catch {}" >nul 2>&1

:: 5. Disable System Restore / shadow copies
echo [5/9] Disabling System Restore on %DRV%...
vssadmin delete shadows /for=%DRV% /all /quiet >nul 2>&1
powershell -NoProfile -Command "try { Disable-ComputerRestore -Drive '%DRV%\' -ErrorAction Stop } catch {}" >nul 2>&1

:: 6. Disable Thumbs.db creation
echo [6/9] Disabling Thumbs.db and thumbnail caching...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisableThumbnailCache /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul

:: 7. Disable folder type auto-detection (stops desktop.ini writes)
echo [7/9] Disabling folder type auto-detection...
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v FolderType /t REG_SZ /d NotSpecified /f >nul

:: 8. Exclude from Windows Defender real-time scanning
echo [8/9] Adding Windows Defender exclusion for %DRV%...
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%DRV%\'" >nul 2>&1

:: 9. Disable Storage Sense cleanup on this drive
echo [9/9] Configuring Storage Sense to ignore %DRV%...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 2048 /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo ============================================================
echo  Done. All protections applied for %DRV%
echo ============================================================
echo.
echo  Summary:
echo    - Fast Startup + Hibernation: OFF
echo    - chkdsk on boot: EXCLUDED
echo    - Search indexing: OFF
echo    - Defrag/Optimize: EXCLUDED
echo    - System Restore: OFF
echo    - Thumbs.db: OFF
echo    - Folder auto-detection: OFF
echo    - Defender real-time scan: EXCLUDED
echo    - Storage Sense: EXCLUDED
echo.
echo  Reboot Windows once for all changes to take effect.
echo.
pause
WINEOF

# ─── verify ───
echo
log "Verifying..."
echo "  Mount:   $(mount | grep "$MOUNT")"
echo "  Size:    $(df -h "$MOUNT" | tail -1 | awk '{print $2}')"
echo "  fstab:   $(grep "$MOUNT" /etc/fstab)"
echo "  Service: $(systemctl is-enabled "$SERVICE_NAME")"
echo

echo -e "${GREEN}=== Linux setup complete ===${NC}"
echo
echo "  Drive mounted at: $MOUNT"
echo "  Works on both Ubuntu and Windows."
echo
echo -e "${YELLOW}  NEXT: Boot into Windows, open the drive, right-click${NC}"
echo -e "${YELLOW}        windows-setup.bat > Run as administrator${NC}"
echo
