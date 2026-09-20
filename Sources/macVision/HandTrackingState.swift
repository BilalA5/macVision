import Observation
import Foundation

@MainActor
@Observable

final class HandTrackingState {
    private(set) var isEnabled = false
    private(set) var handDetected = false

    private(set) var confidentJointCount = 0
    private(set) var processingMilliseconds: Double = 0
    private(set) var frameAgeMilliseconds: Double = 0
    private(set) var deliveredFPS: Double = 0
    @ObservationIgnored private var lastDeliveryTime: Double?

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
        pinchState: PinchRecognizer.State = .waitingForRelease,
        capturedAt: Double? = nil,
        deliveredAt: Double = ProcessInfo.processInfo.systemUptime
    ) {
        guard isEnabled else {
            return
        }

        if let capturedAt { frameAgeMilliseconds = max(0, deliveredAt - capturedAt) * 1_000 }
        if let previous = lastDeliveryTime, deliveredAt > previous {
            let rate = 1 / (deliveredAt - previous)
            deliveredFPS = deliveredFPS == 0 ? rate : deliveredFPS * 0.8 + rate * 0.2
        }
        lastDeliveryTime = deliveredAt
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
        frameAgeMilliseconds = 0
        deliveredFPS = 0
        lastDeliveryTime = nil
        latestFrame = nil
        pinchState = .waitingForRelease
    }
}
