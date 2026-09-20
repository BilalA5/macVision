import Foundation

private func calibrationFrame(_ ratio: Double, finger: PinchFinger = .middle) -> HandFrame {
    HandFrame(timeStamp: 0, imageWidth: 1000, imageHeight: 1000, landmarks: [
        .wrist: HandLandmark(x: 0.5, y: 0.4, confidence: 1),
        .middleMCP: HandLandmark(x: 0.5, y: 0.5, confidence: 1),
        .thumbTip: HandLandmark(x: 0.5, y: 0.6, confidence: 1),
        finger.tip: HandLandmark(x: 0.5 + ratio * 0.1, y: 0.6, confidence: 1)
    ])
}

@MainActor func fingerSelectionAndShortCalibration() throws {
    let name = "macVision.tests.\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let settings = GestureSettings(defaults: defaults)
    // Legacy settings omit the new optional finger field.
    let encoded = try JSONEncoder().encode(GesturePreferences())
    let legacy = try JSONDecoder().decode(GesturePreferences.self, from: encoded)
    expect(legacy.selectedFinger == .index)
    settings.selectFinger(.middle)
    expect(GestureSettings(defaults: defaults).preferences.selectedFinger == .middle)
    expect(PinchMeasurement(frame: calibrationFrame(0.1)) == nil)
    for finger in PinchFinger.allCases {
        expect(PinchMeasurement(frame: calibrationFrame(0.1, finger: finger), finger: finger) != nil)
    }
    var engine = GestureEngine(finger: .middle)
    for t in [0.0, 0.03, 0.07] { _ = engine.update(frame: calibrationFrame(0.8), timestamp: t) }
    for t in [0.1, 0.13, 0.17] { _ = engine.update(frame: calibrationFrame(0.1), timestamp: t) }
    var emitted: GestureKind?
    for t in [0.2, 0.23, 0.27] {
        if let gesture = engine.update(frame: calibrationFrame(0.8), timestamp: t) { emitted = gesture }
    }
    expect(emitted == .pinch)
    let session = CalibrationSession()
    let now = ProcessInfo.processInfo.systemUptime
    session.beginOpen(finger: .middle)
    _ = session.consume(calibrationFrame(0.8), settings: settings, now: now)
    for i in 0..<8 { _ = session.consume(calibrationFrame(0.8), settings: settings, now: now + 0.5 + Double(i) / 15) }
    expect(session.canCaptureClosed)
    session.beginClosed(finger: .middle)
    _ = session.consume(calibrationFrame(0.1), settings: settings, now: now + 2)
    var saved = false
    for i in 0..<8 { saved = session.consume(calibrationFrame(0.1), settings: settings, now: now + 2.5 + Double(i) / 15) }
    expect(saved && settings.preferences.hasCalibration)
    settings.selectFinger(.ring)
    expect(!settings.preferences.hasCalibration)
    session.beginOpen(finger: .ring)
    _ = session.consume(calibrationFrame(0.8, finger: .ring), settings: settings, now: now + 4)
    for i in 0..<8 { _ = session.consume(calibrationFrame(i % 2 == 0 ? 0.3 : 0.9, finger: .ring), settings: settings, now: now + 4.5 + Double(i) / 15) }
    expect(!session.canCaptureClosed)
    _ = session.consume(nil, settings: settings, now: now + 6)
    expect(session.sampleCount == 0)
    session.cancel()
    expect(!session.isCollecting && !session.canCaptureClosed)
}

@MainActor func calibrationCancellationAndTimeoutClearLiveProgress() {
    let name = "macVision.tests.\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let settings = GestureSettings(defaults: defaults)
    settings.selectFinger(.middle)
    let session = CalibrationSession()
    let now = ProcessInfo.processInfo.systemUptime
    session.beginOpen(finger: .middle)
    _ = session.consume(calibrationFrame(0.8), settings: settings, now: now)
    _ = session.consume(calibrationFrame(0.8), settings: settings, now: now + 0.5)
    expect(session.sampleCount == 1 && session.isCollecting)
    session.cancel()
    expect(session.sampleCount == 0 && !session.isCollecting && !session.canCaptureClosed)
    _ = session.consume(calibrationFrame(0.8), settings: settings, now: now + 0.6)
    expect(session.sampleCount == 0) // A late frame must not resurrect a cancelled activity.
    session.beginOpen(finger: .middle)
    _ = session.consume(nil, settings: settings, now: now + 60)
    expect(!session.isCollecting && session.sampleCount == 0)
    expect(session.message.contains("Could not collect"))
    expect(!settings.preferences.hasCalibration)
}
