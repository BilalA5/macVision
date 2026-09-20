#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
mkdir -p .build/core-tests .build/module-cache
swiftc -swift-version 6 -parse-as-library \
    -module-cache-path "$PROJECT_DIR/.build/module-cache" \
    Sources/macVision/CalibrationSession.swift \
    Sources/macVision/LatestFrameMailbox.swift \
    Sources/macVision/TrackingDeliveryGate.swift \
    Sources/macVision/HandFrame.swift \
    Sources/macVision/PinchMeasurement.swift \
    Sources/macVision/PinchRecognizer.swift \
    Sources/macVision/GestureEngine.swift \
    Sources/macVision/GestureSettings.swift \
    Tests/macVisionTests/*.swift \
    -o .build/core-tests/runner
.build/core-tests/runner
