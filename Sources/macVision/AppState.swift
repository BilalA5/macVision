import Observation

enum ActivationState {
    case off // macVision is off
    case idle //macVision is on but not in use
    case active //macVision is in use
}

@MainActor
@Observable
final class AppState {
    let handTracking = HandTrackingState()


    @ObservationIgnored
    let camera : CameraManager

    private(set) var activationState : ActivationState = .off //default state off

    init() {
        camera = CameraManager(trackingState : handTracking)
    }

    var isActive: Bool {
        activationState == .active
    }

    func toggleActivation() {
        if isActive {
            deactivate()
        }else{
            activate()
        }
    }

    func activate() {
        activationState = .active
        handTracking.setEnabled(true)
        camera.start()
    }

    func deactivate() {
        activationState = .off
        handTracking.setEnabled(false)
        camera.stop()
    }
}