# System Auto-Update Scripts

A comprehensive solution for keeping your Linux system up-to-date with automatic restart detection and optional automation.

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
6. **Firmware Update**: Updates Raspberry Pi firmware (Pi devices only)
7. **Cleanup**: Removes unnecessary packages and cleans cache
8. **Restart Detection**: Checks if system restart is required
9. **Automatic Restart**: Initiates restart with cancellable countdown

## Safety Features

- **Root Check**: Ensures script runs with proper privileges
- **Lock File**: Prevents multiple simultaneous update operations
- **Error Handling**: Exits safely on errors with proper cleanup
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
- Updates Raspberry Pi firmware via `rpi-update` (if available)
- Handles ARM architecture specifics
- Logs hardware detection for troubleshooting

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

## Security Considerations

- Script requires root privileges for system updates
- Lock file prevents concurrent executions
- Non-interactive mode prevents hanging on prompts
- Comprehensive logging for audit trails

## License

This project is provided as-is for system administration purposes. Use at your own discretion and ensure you have proper backups before running automated updates on critical systems.