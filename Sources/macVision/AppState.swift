import Observation

enum ActivationState {
    case off // macVision is off
    case idle //macVision is on but not in use
    case active //macVision is in use
}

@MainActor
@Observable
final class AppState {
    @ObservationIgnored
    let camera = CameraManager()

    private(set) var activationState : ActivationState = .off //default state off

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
        camera.start()
    }

    func deactivate() {
        activationState = .off
        camera.stop()
    }
}