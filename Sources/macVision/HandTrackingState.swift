import Observation

@MainActor
@Observable

final class HandTrackingState {
    private(set) var isEnabled = false
    private(set) var handDetected = false

    private(set) var confidentJointCount = 0
    private(set) var processingMilliseconds: Double = 0

    func setEnabled(_ enabled : Bool) {
        isEnabled = enabled
        resetResults()
    }

    func update(handDetected: Bool, confidentJoinCount: Int, processingMilliseconds: Double){
        guard isEnabled else {
            return
        }

        self.handDetected = handDetected
        self.confidentJoinCount = confidentJoinCount
        self.processingMilliseconds = processingMilliseconds
    }

    private func resetResults() {
        handDetected = false
        confidentJointCount = 0
        processingMilliseconds = 0
    }
}