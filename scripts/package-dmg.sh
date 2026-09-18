#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$("$PROJECT_DIR/scripts/build-app.sh" release)"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/macVision-dmg.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
cp -R "$APP_DIR" "$STAGING_DIR/macVision.app"
ln -s /Applications "$STAGING_DIR/Applications"
mkdir -p "$PROJECT_DIR/dist"
hdiutil create -volname macVision -srcfolder "$STAGING_DIR" -ov -format UDZO "$PROJECT_DIR/dist/macVision.dmg"
echo "Created dist/macVision.dmg. Public distribution also requires Developer ID signing and notarization."
