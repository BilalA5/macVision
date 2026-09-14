#!/bin/bash
set -euo pipefail

# find project dir
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# build swift app
swift build

BIN_DIR="$(swift build --show-bin-path)"

# create macOS bundle
APP_DIR="$PROJECT_DIR/build/macVision.app"
mkdir -p "$APP_DIR/Contents/MacOS"

cp "$BIN_DIR/macVision" "$APP_DIR/Contents/MacOS/macVision"
cp "$PROJECT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"

# adhoc signature
codesign --force --sign - "$APP_DIR"

# launch app.
open "$APP_DIR"