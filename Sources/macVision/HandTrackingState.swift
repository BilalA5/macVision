import Observation

@MainActor
@Observable

final class HandTrackingState {
    private(set) var isEnabled = false
    private(set) var handDetected = false

    private(set) var confidentJointCount = 0
    private(set) var processingMilliseconds: Double = 0

    private(set) var latestFrame : HandFrame?
    private(set) var pinchState: PinchRecognizer.State = .waitingForRelease

    var pinchStatusText: String {
        switch pinchState {
        case .waitingForRelease: "Open your thumb and index finger to get ready"
        case .ready: "Ready to pinch"
        case .pinched: "Pinch held"
        }
    }

    func setEnabled(_ enabled : Bool) {
        isEnabled = enabled
        resetResults()
    }

    func update(
        handDetected: Bool,
        confidentJointCount: Int,
        processingMilliseconds: Double,
        frame: HandFrame? = nil,
        pinchState: PinchRecognizer.State = .waitingForRelease
    ) {
        guard isEnabled else {
            return
        }

        self.handDetected = handDetected
        self.confidentJointCount = confidentJointCount
        self.processingMilliseconds = processingMilliseconds
        self.latestFrame = handDetected ? frame : nil
        self.pinchState = pinchState
    }

    private func resetResults() {
        handDetected = false
        confidentJointCount = 0
        processingMilliseconds = 0
        latestFrame = nil
        pinchState = .waitingForRelease
    }
}
