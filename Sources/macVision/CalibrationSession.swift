import Foundation
import Observation

@MainActor @Observable
final class CalibrationSession {
    static let requiredSamples = 8
    enum Phase { case inactive, open, closed, complete }
    private(set) var phase: Phase = .inactive
    private(set) var sampleCount = 0
    private(set) var message = "Optional: personalize pinch sensitivity once, then keep using it."
    @ObservationIgnored private var samples: [Double] = []
    @ObservationIgnored private var openRatio: Double?
    @ObservationIgnored private var startedAt: Double?
    @ObservationIgnored private var deadline: Double = 0

    var canCaptureClosed: Bool { openRatio != nil }

    var isCollecting: Bool { phase == .open || phase == .closed }

    func beginOpen(finger: PinchFinger = .index) {
        openRatio = nil
        begin(.open)
        message = "Hold your thumb and \(finger.title.lowercased()) comfortably apart, with your palm facing the camera."
    }

    func beginClosed(finger: PinchFinger = .index) {
        guard openRatio != nil else { return }
        begin(.closed)
        message = "Touch your thumb and \(finger.title.lowercased()) finger together and hold still."
    }

    private func begin(_ phase: Phase) {
        self.phase = phase
        samples = []
        sampleCount = 0
        startedAt = nil
        deadline = ProcessInfo.processInfo.systemUptime + 12
    }

    func cancel() {
        openRatio = nil
        phase = .inactive
        samples = []
        sampleCount = 0
        message = "Calibration stopped. Your saved sensitivity has not changed."
    }

    func consume(_ frame: HandFrame?, settings: GestureSettings, now: Double = ProcessInfo.processInfo.systemUptime) -> Bool {
        guard isCollecting else { return false }
        guard now <= deadline else {
            cancel()
            message = "Could not collect a stable hand. Try better lighting and keep your whole hand visible."
            return false
        }
        guard let frame, let measurement = PinchMeasurement(frame: frame, finger: settings.preferences.selectedFinger) else {
            samples = []
            sampleCount = 0
            startedAt = nil
            return false
        }
        if startedAt == nil { startedAt = now }
        // Give the user time to form the pose after pressing the button.
        guard now - (startedAt ?? now) >= 0.4 else { return false }
        samples.append(measurement.ratio)
        sampleCount = samples.count
        guard samples.count >= Self.requiredSamples else { return false }
        let ordered = samples.sorted()
        let median = ordered[ordered.count / 2]
        guard ordered[ordered.count - 2] - ordered[1] < 0.25 else {
            samples = []
            sampleCount = 0
            message = "Hold steady; the pinch distance is varying too much."
            return false
        }
        if phase == .open {
            openRatio = median
            phase = .inactive
            message = "Open pose captured. Now choose Capture closed pinch."
            return false
        }
        guard let openRatio, settings.calibrate(closed: median, open: openRatio) else {
            cancel()
            message = "The poses were too similar. Start again with fingers farther apart for the open pose."
            return false
        }
        phase = .complete
        message = "Sensitivity saved. You do not need to calibrate each time."
        return true
    }
}
