import observation

enum ActivationState {
    case off // macVision is off
    case idle //macVision is on but not in use
    case active //macVision is in use
}

@Observable
final class AppState {
    var activationState: ActivationState = .off //default state off

    var isActive: Bool {
        activationState == .active
    }

    func toggleActivation() {
        activationState = isActive ? .off : .active
    }
}