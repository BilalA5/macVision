#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if pgrep -x macVision >/dev/null; then
    echo "Quit the running macVision from its menu-bar menu, then run this script again." >&2
    exit 1
fi
APP_DIR="$("$PROJECT_DIR/scripts/build-app.sh" debug)"
open "$APP_DIR"
