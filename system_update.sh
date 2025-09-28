#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/system_update.log"
LOCK_FILE="/var/lock/system_update.lock"
REBOOT_REQUIRED_FILE="/var/run/reboot-required"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    rm -f "$LOCK_FILE"
    log "Cleanup completed"
}

trap cleanup EXIT

if [ -f "$LOCK_FILE" ]; then
    log "Update already in progress (lock file exists)"
    exit 1
fi

touch "$LOCK_FILE"

log "=== Starting system update ==="

if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Detect system type and log for troubleshooting
ARCHITECTURE=$(uname -m)
DISTRO_ID=$(lsb_release -si 2>/dev/null || echo "Unknown")
DISTRO_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
log "System: $DISTRO_ID $DISTRO_VERSION ($ARCHITECTURE)"

# Check if this is a Raspberry Pi
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    log "Detected: $PI_MODEL"
fi

log "Checking for broken package manager state..."
# Fix any interrupted package operations
if dpkg --audit 2>/dev/null | grep -q .; then
    log "Found interrupted package operations, fixing..."
    dpkg --configure -a
fi

# Remove apt lock files if they exist (from previous crashes)
LOCK_FILES_REMOVED=0
for lock_file in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock; do
    if [ -f "$lock_file" ]; then
        if ! fuser "$lock_file" >/dev/null 2>&1; then
            log "Removing stale lock file: $lock_file"
            rm -f "$lock_file"
            LOCK_FILES_REMOVED=$((LOCK_FILES_REMOVED + 1))
        fi
    fi
done

if [ $LOCK_FILES_REMOVED -eq 0 ]; then
    log "No stale lock files found (system clean)"
fi

log "Updating package lists..."
UPDATE_START=$(date +%s)
# Retry apt update up to 3 times in case of temporary failures
for attempt in 1 2 3; do
    if apt-get update; then
        UPDATE_END=$(date +%s)
        UPDATE_DURATION=$((UPDATE_END - UPDATE_START))
        log "Package lists updated successfully (${UPDATE_DURATION}s)"
        break
    else
        log "apt update failed (attempt $attempt/3)"
        if [ $attempt -eq 3 ]; then
            log "ERROR: Failed to update package lists after 3 attempts"
            exit 1
        fi
        log "Retrying in 5 seconds..."
        sleep 5
    fi
done

log "Checking for available upgrades..."
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

if [ "$UPGRADES" -eq 0 ]; then
    log "No updates available - system is up to date"
    log "=== Update process finished ==="
    exit 0
fi

log "Found $UPGRADES packages to upgrade"
UPGRADE_START=$(date +%s)

log "Performing system upgrade..."
if ! DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; then
    log "WARNING: Some packages failed to upgrade, attempting to fix..."
    apt-get install -f -y
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
fi

log "Performing distribution upgrade..."
if ! DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y; then
    log "WARNING: Distribution upgrade had issues, attempting to fix..."
    apt-get install -f -y
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
fi

# Raspberry Pi specific: Firmware update (only if explicitly enabled)
# Note: rpi-update is NOT recommended for regular use and can break your system
# Only enable if you have specific firmware issues to resolve
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    if [ "${RPI_UPDATE_FIRMWARE:-false}" = "true" ] && command -v rpi-update >/dev/null 2>&1; then
        log "WARNING: Updating Raspberry Pi firmware (experimental/bleeding edge)"
        log "This may cause instability - only use if you have specific firmware issues"
        SKIP_BACKUP=1 rpi-update
    else
        log "Skipping firmware update (use RPI_UPDATE_FIRMWARE=true to enable - NOT recommended)"
    fi
fi

log "Cleaning up..."
apt-get autoremove -y
apt-get autoclean

UPGRADE_END=$(date +%s)
UPGRADE_DURATION=$((UPGRADE_END - UPGRADE_START))
log "Update completed successfully (${UPGRADE_DURATION}s total upgrade time)"

if [ -f "$REBOOT_REQUIRED_FILE" ]; then
    log "REBOOT REQUIRED - System will restart in 30 seconds"
    log "Cancel with: sudo pkill -f system_update.sh"

    for i in {30..1}; do
        echo -ne "\rRestarting in $i seconds... (Ctrl+C to cancel)"
        sleep 1
    done

    log "Initiating system reboot..."
    reboot
else
    log "No reboot required"
fi

log "=== Update process finished ==="