#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/system_update.sh"

if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "Error: Update script not found at $UPDATE_SCRIPT"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Running with sudo..."
    exec sudo "$UPDATE_SCRIPT" "$@"
else
    exec "$UPDATE_SCRIPT" "$@"
fi