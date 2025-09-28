#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Installing systemd service and timer for automatic updates..."

cp "$SCRIPT_DIR/auto-update.service" /etc/systemd/system/
cp "$SCRIPT_DIR/auto-update.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable auto-update.timer
systemctl start auto-update.timer

echo "Service installed successfully!"
echo "The system will now check for updates daily with a random delay up to 1 hour."
echo ""
echo "To check status: sudo systemctl status auto-update.timer"
echo "To view logs: sudo journalctl -u auto-update.service"
echo "To disable: sudo systemctl disable auto-update.timer"