import Foundation

/// A completed gesture is emitted only on deliberate release. Loss of tracking cancels it.
struct GestureEngine: Sendable {
    private let finger: PinchFinger
    private var pinch: PinchRecognizer
    private var origin: (x: Double, y: Double, scale: Double, time: Double)?
    private var previousWrist: (x: Double, y: Double)?
    private var displacement = (x: 0.0, y: 0.0)
    private var lastGestureTime = -Double.infinity
    private(set) var state: PinchRecognizer.State = .waitingForRelease

    init(closeThreshold: Double = 0.25, openThreshold: Double = 0.40, finger: PinchFinger = .index) {
        self.finger = finger
        pinch = PinchRecognizer(closeThreshold: closeThreshold, openThreshold: openThreshold)
    }

    mutating func reset() {
        _ = pinch.reset()
        state = pinch.state
        origin = nil
        previousWrist = nil
        displacement = (0, 0)
    }

    mutating func update(frame: HandFrame?, timestamp: Double) -> GestureKind? {
        guard let frame, let measurement = PinchMeasurement(frame: frame, finger: finger),
              let wrist = frame.reliableLandmark(.wrist, minimumConfidence: 0.6),
              let base = frame.reliableLandmark(.middleMCP, minimumConfidence: 0.6) else {
            reset()
            return nil
        }
        let x = wrist.x * Double(frame.imageWidth)
        let y = wrist.y * Double(frame.imageHeight)
        let scale = hypot(x - base.x * Double(frame.imageWidth), y - base.y * Double(frame.imageHeight))
        // Reject tiny/edge-on hands and abrupt jumps that may be a different hand.
        guard scale >= 20, x.isFinite, y.isFinite else { reset(); return nil }
        if let previousWrist, hypot(x - previousWrist.x, y - previousWrist.y) > scale * 1.5 {
            reset()
            return nil
        }
        previousWrist = (x, y)
        let event = pinch.update(measurement: measurement, timestamp: timestamp)
        state = pinch.state
        if let origin {
            // Front-camera image x is reversed relative to the user's left/right.
            displacement = (-(x - origin.x) / origin.scale, (y - origin.y) / origin.scale)
            if timestamp - origin.time > 3 {
                reset()
                return nil
            }
        }
        switch event {
        case .began:
            origin = (x, y, scale, timestamp)
            displacement = (0, 0)
        case .cancelled:
            reset()
        case .ended:
            guard let origin else { return nil }
            let duration = timestamp - origin.time
            self.origin = nil
            guard timestamp - lastGestureTime >= 0.4 else { return nil }
            let dx = displacement.x
            let dy = displacement.y
            let distance = hypot(dx, dy)
            let result: GestureKind
            if distance >= 0.8 {
                // Diagonal/ambiguous movements should not become a surprise action.
                if abs(dx) >= abs(dy) * 1.4 { result = dx > 0 ? .right : .left }
                else if abs(dy) >= abs(dx) * 1.4 { result = dy > 0 ? .up : .down }
                else { return nil }
            } else if distance <= 0.35 {
                result = duration >= 0.65 ? .hold : .pinch
            } else { return nil }
            lastGestureTime = timestamp
            return result
        case nil:
            break
        }
        return nil
    }
}
