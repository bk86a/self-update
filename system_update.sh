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

log "Updating package lists..."
apt-get update

log "Checking for available upgrades..."
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

if [ "$UPGRADES" -eq 0 ]; then
    log "No updates available"
    exit 0
fi

log "Found $UPGRADES packages to upgrade"

log "Performing system upgrade..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Performing distribution upgrade..."
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Raspberry Pi specific: Update firmware if available
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    if command -v rpi-update >/dev/null 2>&1; then
        log "Updating Raspberry Pi firmware..."
        SKIP_BACKUP=1 rpi-update
    fi
fi

log "Cleaning up..."
apt-get autoremove -y
apt-get autoclean

log "Update completed successfully"

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