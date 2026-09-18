#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
mkdir -p .build/ui-previews .build/module-cache
sources=()
while IFS= read -r file; do
    [ "$(basename "$file")" = "macVisionApp.swift" ] || sources+=("$file")
done < <(find Sources/macVision -name '*.swift' -type f | sort)
swiftc -swift-version 6 -parse-as-library -module-cache-path .build/module-cache \
    "${sources[@]}" Tools/RenderUI.swift -o .build/ui-previews/render
.build/ui-previews/render "$PROJECT_DIR/.build/ui-previews"
