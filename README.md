# System Auto-Update Scripts

A comprehensive solution for keeping your Linux system up-to-date with automatic restart detection and optional automation.

## Installation

### Quick Install from GitHub

```bash
# Clone the repository
git clone https://github.com/bk86a/self-update.git

# Navigate to the directory
cd self-update

# Make scripts executable (if needed)
chmod +x *.sh

# Run your first update
./quick_update.sh
```

### Alternative: Download ZIP

If you don't have git installed:

```bash
# Download and extract
wget https://github.com/bk86a/self-update/archive/main.zip
unzip main.zip
cd self-update-main

# Make scripts executable
chmod +x *.sh

# Run update
./quick_update.sh
```

## Features

- **Safe Updates**: Handles package updates, distribution upgrades, and cleanup
- **Automatic Restart Detection**: Detects when system restart is required and handles it automatically
- **Comprehensive Logging**: All operations logged to `/var/log/system_update.log`
- **Lock Mechanism**: Prevents concurrent update operations
- **Flexible Usage**: Run manually or set up automated daily updates
- **Cancellable Restart**: 30-second countdown allows cancellation of automatic restart

## Files Overview

| File | Purpose |
|------|---------|
| `system_update.sh` | Main update script with restart detection |
| `quick_update.sh` | Convenient wrapper that handles sudo automatically |
| `auto-update.service` | Systemd service definition for automation |
| `auto-update.timer` | Daily timer with randomized delay |
| `install_service.sh` | Installer for automated service |

## Quick Start

### Manual Updates

Run updates whenever needed:

```bash
./quick_update.sh
```

The script will:
1. Check for available updates
2. Install all updates
3. Clean up unnecessary packages
4. Automatically restart if required (with 30-second warning)

### Automated Daily Updates

Set up automatic daily updates:

```bash
sudo ./install_service.sh
```

This installs a systemd timer that runs updates daily with a randomized delay (up to 1 hour).

## Detailed Usage

### Manual Execution

```bash
# Run with automatic sudo handling
./quick_update.sh

# Or run directly as root
sudo ./system_update.sh
```

### Automation Management

```bash
# Install automated updates
sudo ./install_service.sh

# Check status
sudo systemctl status auto-update.timer

# View logs
sudo journalctl -u auto-update.service

# Disable automation
sudo systemctl disable auto-update.timer
sudo systemctl stop auto-update.timer
```

## What the Script Does

1. **System Detection**: Identifies hardware (including Raspberry Pi models) and OS version
2. **Package List Update**: Refreshes package repositories
3. **Upgrade Check**: Identifies available updates
4. **System Upgrade**: Installs package updates
5. **Distribution Upgrade**: Handles distribution-level updates
6. **Firmware Update**: Optional Pi firmware update (disabled by default)
7. **Cleanup**: Removes unnecessary packages and cleans cache
8. **Restart Detection**: Checks if system restart is required
9. **Automatic Restart**: Initiates restart with cancellable countdown

## Safety Features

- **Root Check**: Ensures script runs with proper privileges
- **Lock File**: Prevents multiple simultaneous update operations
- **Error Handling**: Exits safely on errors with proper cleanup
- **Package Recovery**: Automatically fixes interrupted package operations
- **Lock File Recovery**: Removes stale apt lock files from crashed processes
- **Retry Logic**: Retries failed operations with exponential backoff
- **Logging**: Comprehensive logging of all operations
- **Cancellable Restart**: 30-second countdown allows manual cancellation

## Log Files

- **Main Log**: `/var/log/system_update.log`
- **Service Logs**: `sudo journalctl -u auto-update.service`

## Requirements

- Ubuntu/Debian-based Linux distribution (including Raspberry Pi OS)
- Root privileges (sudo access)
- `apt` package manager

### Raspberry Pi Compatibility

This script is fully compatible with Raspberry Pi devices running Raspberry Pi OS (Raspbian). The script automatically:

- Detects Raspberry Pi hardware
- Updates system packages via `apt`
- **Firmware updates are DISABLED by default** (see below)
- Handles ARM architecture specifics
- Logs hardware detection for troubleshooting

### Raspberry Pi Firmware Updates

**⚠️ IMPORTANT:** The script does NOT update Pi firmware by default because:
- `rpi-update` installs bleeding-edge, experimental firmware
- It can make your Pi unstable or unbootable
- Regular `apt` updates include stable firmware updates

**Only enable firmware updates if you have specific firmware issues:**

```bash
# Enable firmware updates (NOT recommended for most users)
RPI_UPDATE_FIRMWARE=true ./quick_update.sh

# Or set as environment variable
export RPI_UPDATE_FIRMWARE=true
./quick_update.sh
```

**Tested on:**
- Raspberry Pi OS (32-bit and 64-bit)
- All Raspberry Pi models (Pi 1, 2, 3, 4, 5, Zero series)

## Customization

### Modify Update Schedule

Edit the timer in `auto-update.timer`:

```ini
[Timer]
OnCalendar=daily           # Change frequency (daily, weekly, etc.)
RandomizedDelaySec=1h      # Change randomization window
```

### Modify Restart Delay

Edit the countdown in `system_update.sh`:

```bash
for i in {30..1}; do       # Change from 30 seconds to desired time
```

## Troubleshooting

### Check if Updates are Running
```bash
ps aux | grep system_update
```

### View Recent Logs
```bash
sudo tail -f /var/log/system_update.log
```

### Check Lock File
```bash
ls -la /var/lock/system_update.lock
```

### Manual Lock Removal (if script crashed)
```bash
sudo rm -f /var/lock/system_update.lock
```

### Fix Broken Package Manager
If apt/dpkg is in a broken state:
```bash
sudo dpkg --configure -a
sudo apt-get install -f
```

### Common Issues on Raspberry Pi
```bash
# If you get "git: command not found"
sudo apt update && sudo apt install -y git

# If you get permission denied
chmod +x *.sh

# Enable firmware updates on Pi (only if needed for specific issues)
RPI_UPDATE_FIRMWARE=true ./quick_update.sh
```

## Security Considerations

- Script requires root privileges for system updates
- Lock file prevents concurrent executions
- Non-interactive mode prevents hanging on prompts
- Comprehensive logging for audit trails
- All operations are logged for security auditing
- No network connections beyond standard package repositories

### Security Best Practices

- **Always review scripts** before running with sudo privileges
- **Test on non-critical systems** first
- **Maintain backups** before running automated updates
- **Monitor logs** in `/var/log/system_update.log`
- **Use automation carefully** - consider your update schedule needs

## License

This project is provided as-is for system administration purposes. Use at your own discretion and ensure you have proper backups before running automated updates on critical systems.

**Disclaimer**: This software is provided "as is" without warranty. Users are responsible for testing and validating the software in their environment before production use.