
private func hand(_ time: Double, ratio: Double, x: Double = 0.5, y: Double = 0.4) -> HandFrame {
    HandFrame(timeStamp: time, imageWidth: 1000, imageHeight: 1000, landmarks: [
        .wrist: HandLandmark(x: x, y: y, confidence: 1),
        .middleMCP: HandLandmark(x: x, y: y + 0.1, confidence: 1),
        .thumbTip: HandLandmark(x: x, y: y + 0.15, confidence: 1),
        .indexTip: HandLandmark(x: x + ratio * 0.1, y: y + 0.15, confidence: 1)
    ])
}

private func armAndPinch(_ engine: inout GestureEngine) {
    for t in [0.0, 0.03, 0.07] { _ = engine.update(frame: hand(t, ratio: 0.7), timestamp: t) }
    for t in [0.10, 0.13, 0.17] { _ = engine.update(frame: hand(t, ratio: 0.1), timestamp: t) }
}

func pinchRequiresOpeningAndEmitsOnceOnRelease() {
    var engine = GestureEngine()
    for t in [0.0, 0.03, 0.07] {
        expect(engine.update(frame: hand(t, ratio: 0.1), timestamp: t) == nil)
    }
    expect(engine.state == .waitingForRelease)
    engine.reset()
    armAndPinch(&engine)
    expect(engine.state == .pinched)
    expect(engine.update(frame: hand(0.21, ratio: 0.7), timestamp: 0.21) == nil)
    expect(engine.update(frame: hand(0.28, ratio: 0.7), timestamp: 0.28) == .pinch)
    expect(engine.update(frame: hand(0.35, ratio: 0.7), timestamp: 0.35) == nil)
}

func lossCancelsWithoutActionAndRequiresRearming() {
    var engine = GestureEngine()
    armAndPinch(&engine)
    expect(engine.update(frame: nil, timestamp: 0.2) == nil)
    expect(engine.state == .waitingForRelease)
    expect(engine.update(frame: hand(0.23, ratio: 0.1), timestamp: 0.23) == nil)
    expect(engine.update(frame: hand(0.30, ratio: 0.1), timestamp: 0.30) == nil)
    expect(engine.state == .waitingForRelease)
}

func directionalPinchDoesNotAlsoEmitTap() {
    var engine = GestureEngine()
    armAndPinch(&engine)
    expect(engine.update(frame: hand(0.21, ratio: 0.1, x: 0.55), timestamp: 0.21) == nil)
    expect(engine.update(frame: hand(0.25, ratio: 0.1, x: 0.60), timestamp: 0.25) == nil)
    expect(engine.update(frame: hand(0.29, ratio: 0.7, x: 0.60), timestamp: 0.29) == nil)
    expect(engine.update(frame: hand(0.36, ratio: 0.7, x: 0.60), timestamp: 0.36) == .left)
    expect(engine.update(frame: hand(0.40, ratio: 0.7, x: 0.60), timestamp: 0.40) == nil)
}

func holdOnlyCompletesOnRelease() {
    var engine = GestureEngine()
    armAndPinch(&engine)
    for step in 2...9 {
        let t = Double(step) / 10
        expect(engine.update(frame: hand(t, ratio: 0.1), timestamp: t) == nil)
    }
    expect(engine.update(frame: hand(0.95, ratio: 0.7), timestamp: 0.95) == nil)
    expect(engine.update(frame: hand(1.02, ratio: 0.7), timestamp: 1.02) == .hold)
}

func staleOrDuplicateTimeCancelsPinch() {
    var engine = GestureEngine()
    armAndPinch(&engine)
    expect(engine.update(frame: hand(0.17, ratio: 0.1), timestamp: 0.17) == nil)
    expect(engine.state == .waitingForRelease)
    engine = GestureEngine()
    armAndPinch(&engine)
    expect(engine.update(frame: hand(1, ratio: 0.7), timestamp: 1) == nil)
    expect(engine.state == .waitingForRelease)
}

func ambiguousDiagonalAndHandJumpCancel() {
    var engine = GestureEngine()
    armAndPinch(&engine)
    _ = engine.update(frame: hand(0.21, ratio: 0.1, x: 0.56, y: 0.46), timestamp: 0.21)
    _ = engine.update(frame: hand(0.25, ratio: 0.7, x: 0.57, y: 0.47), timestamp: 0.25)
    expect(engine.update(frame: hand(0.32, ratio: 0.7, x: 0.57, y: 0.47), timestamp: 0.32) == nil)
    engine = GestureEngine()
    armAndPinch(&engine)
    expect(engine.update(frame: hand(0.21, ratio: 0.1, x: 0.9), timestamp: 0.21) == nil)
    expect(engine.state == .waitingForRelease)
}

func pinchRatioAccountsForImageAspectAndRejectsMissingJoints() {
    let frame = hand(0, ratio: 0.2)
    expect(abs((PinchMeasurement(frame: frame)?.ratio ?? -1) - 0.2) < 0.0001)
    let empty = HandFrame(timeStamp: 0, imageWidth: 1280, imageHeight: 720, landmarks: [:])
    expect(PinchMeasurement(frame: empty) == nil)
}
