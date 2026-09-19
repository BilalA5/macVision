import Foundation
import Observation

enum GestureKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case pinch, hold, left, right, up, down
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pinch: "Pinch and release"
        case .hold: "Hold and release"
        case .left: "Pinch left"
        case .right: "Pinch right"
        case .up: "Pinch up"
        case .down: "Pinch down"
        }
    }
}

struct Shortcut: Codable, Equatable, Sendable {
    var keyCode: UInt16
    var label: String
    var command = false
    var option = false
    var control = false
    var shift = false

    var displayName: String {
        (control ? "⌃" : "") + (option ? "⌥" : "") +
        (shift ? "⇧" : "") + (command ? "⌘" : "") + label
    }
}

struct GesturePreferences: Codable, Sendable {
    var version = 1
    var bindings: [String: Shortcut] = Self.browserBindings
    var browserOnly = true
    static let browserBindings: [String: Shortcut] = [
        "pinch": Shortcut(keyCode: 48, label: "Tab", control: true),
        "hold": Shortcut(keyCode: 48, label: "Tab", control: true, shift: true),
        "left": Shortcut(keyCode: 33, label: "[", command: true),
        "right": Shortcut(keyCode: 30, label: "]", command: true),
        "up": Shortcut(keyCode: 116, label: "Page Up"),
        "down": Shortcut(keyCode: 121, label: "Page Down")
    ]
    var closeThreshold = 0.25
    var openThreshold = 0.40
    var pinchFinger: PinchFinger? = nil
    var selectedFinger: PinchFinger { pinchFinger ?? .index }
    var hasCalibration = false
    var onboardingComplete = false

    var isValid: Bool {
        version == 1 && closeThreshold.isFinite && openThreshold.isFinite &&
        closeThreshold > 0 && closeThreshold < openThreshold && openThreshold < 3 &&
        bindings.allSatisfy { GestureKind(rawValue: $0.key) != nil && $0.value.keyCode < 128 }
    }
}

@MainActor @Observable
final class GestureSettings {
    private(set) var preferences: GesturePreferences
    private(set) var storageMessage: String?
    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "macVision.gesturePreferences.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey) {
            if let saved = try? JSONDecoder().decode(GesturePreferences.self, from: data), saved.isValid {
                preferences = saved
            } else {
                preferences = GesturePreferences()
                storageMessage = "Saved settings could not be read. Defaults are in use."
            }
        } else {
            preferences = GesturePreferences()
        }
    }

    func bind(_ gesture: GestureKind, to shortcut: Shortcut?) {
        preferences.bindings[gesture.rawValue] = shortcut
        save()
    }

    func setBrowserOnly(_ enabled: Bool) {
        preferences.browserOnly = enabled
        save()
    }

    func restoreBrowserBindings() {
        preferences.bindings = GesturePreferences.browserBindings
        preferences.browserOnly = true
        save()
    }

    func calibrate(closed: Double, open: Double) -> Bool {
        guard closed.isFinite, open.isFinite, closed >= 0, open <= 3,
              open - closed >= 0.20 else { return false }
        let gap = open - closed
        preferences.closeThreshold = max(0.05, closed + gap * 0.25)
        preferences.openThreshold = closed + gap * 0.65
        preferences.hasCalibration = true
        save()
        return true
    }

    func selectFinger(_ finger: PinchFinger) {
        guard preferences.selectedFinger != finger else { return }
        preferences.pinchFinger = finger
        resetCalibration()
    }

    func resetCalibration() {
        preferences.closeThreshold = 0.25
        preferences.openThreshold = 0.40
        preferences.hasCalibration = false
        save()
    }

    func finishOnboarding() {
        preferences.onboardingComplete = true
        save()
    }

    private func save() {
        do {
            defaults.set(try JSONEncoder().encode(preferences), forKey: Self.storageKey)
            storageMessage = nil
        } catch {
            storageMessage = "Settings could not be saved: \(error.localizedDescription)"
        }
    }
}
