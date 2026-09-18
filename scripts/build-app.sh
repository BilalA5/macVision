#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
CONFIGURATION="${1:-debug}"
case "$CONFIGURATION" in debug|release) ;; *) echo "Use debug or release" >&2; exit 1;; esac
swift build -c "$CONFIGURATION" >&2
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$PROJECT_DIR/build/macVision.app"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/macVision" "$APP_DIR/Contents/MacOS/macVision"
cp Support/Info.plist "$APP_DIR/Contents/Info.plist"
SIGN_IDENTITY="${MACVISION_SIGN_IDENTITY:--}"
if [ "$SIGN_IDENTITY" = "-" ]; then
    codesign --force --sign - "$APP_DIR" >&2
else
    codesign --force --options runtime --entitlements Support/macVision.entitlements --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR" >&2
fi
codesign --verify --strict "$APP_DIR" >&2
printf '%s\n' "$APP_DIR"
