import Foundation
import Observation

@MainActor @Observable
final class CalibrationSession {
    static let requiredSamples = 6
    enum Phase { case inactive, open, closed, complete }
    private(set) var phase: Phase = .inactive
    private(set) var sampleCount = 0
    private(set) var message = "Optional: personalize pinch sensitivity once, then keep using it."
    @ObservationIgnored private var samples: [Double] = []
    @ObservationIgnored private var openRatio: Double?
    @ObservationIgnored private var startedAt: Double?
    @ObservationIgnored private var deadline: Double = 0
    @ObservationIgnored private var lastValidAt: Double?
    @ObservationIgnored private var selectedFinger: PinchFinger = .index

    var canCaptureClosed: Bool { openRatio != nil }

    var isCollecting: Bool { phase == .open || phase == .closed }

    func beginOpen(finger: PinchFinger = .index) {
        openRatio = nil
        selectedFinger = finger
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
        lastValidAt = nil
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
            // A blink of low confidence should pause collection, not erase it.
            if now - (lastValidAt ?? -.infinity) > 0.2 {
                samples = []
                sampleCount = 0
                startedAt = nil
            }
            message = "Keep your thumb and selected fingertip visible to the camera."
            return false
        }
        lastValidAt = now
        if phase == .closed, let openRatio, measurement.ratio > openRatio - max(0.2, openRatio * 0.35) {
            samples = []
            sampleCount = 0
            startedAt = nil
            message = "Now touch thumb and \(selectedFinger.title.lowercased()) together."
            return false
        }
        if startedAt == nil { startedAt = now }
        // Give the user time to form the pose after pressing the button.
        guard now - (startedAt ?? now) >= 0.25 else { return false }
        message = "Hold comfortably; capturing your pose…"
        samples.append(measurement.ratio)
        if samples.count > Self.requiredSamples { samples.removeFirst() }
        sampleCount = samples.count
        guard samples.count >= Self.requiredSamples else { return false }
        let ordered = samples.sorted()
        let median = ordered[ordered.count / 2]
        guard ordered[ordered.count - 2] - ordered[1] < 0.25 else {
            // Slide past noisy frames instead of repeatedly restarting the whole pose.
            samples.removeFirst()
            sampleCount = samples.count
            message = "Relax your hand and hold this pose a little longer."
            return false
        }
        if phase == .open {
            openRatio = median
            begin(.closed)
            deadline = now + 12
            message = "Open pose captured. Now touch thumb and \(selectedFinger.title.lowercased()) together."
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
