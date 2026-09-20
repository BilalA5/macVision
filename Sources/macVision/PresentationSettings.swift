import SwiftUI
import Observation
import ServiceManagement

@MainActor @Observable
final class PresentationSettings {
    var appearance: String { didSet { defaults.set(appearance, forKey: "ui.appearance") } }
    var reduceTransparency: Bool { didSet { defaults.set(reduceTransparency, forKey: "ui.reduceTransparency") } }
    var reduceMotion: Bool { didSet { defaults.set(reduceMotion, forKey: "ui.reduceMotion") } }
    var showActiveGlow: Bool { didSet { defaults.set(showActiveGlow, forKey: "ui.showActiveGlow") } }
    var showHUD: Bool { didSet { defaults.set(showHUD, forKey: "ui.showHUD") } }
    private(set) var loginEnabled = false
    private(set) var loginMessage: String?
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let defaults = UserDefaults.standard
        appearance = defaults.string(forKey: "ui.appearance") ?? "system"
        reduceTransparency = defaults.bool(forKey: "ui.reduceTransparency")
        reduceMotion = defaults.bool(forKey: "ui.reduceMotion")
        showActiveGlow = defaults.object(forKey: "ui.showActiveGlow") as? Bool ?? true
        showHUD = defaults.object(forKey: "ui.showHUD") as? Bool ?? true
        refreshLoginStatus()
    }

    var colorScheme: ColorScheme? {
        switch appearance { case "dark": .dark; case "light": .light; default: nil }
    }

    func refreshLoginStatus() {
        loginEnabled = SMAppService.mainApp.status == .enabled
        if SMAppService.mainApp.status == .requiresApproval {
            loginMessage = "Allow macVision in System Settings → General → Login Items."
        }
    }

    func setLoginEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginMessage = nil
        } catch {
            loginMessage = "Login item could not be changed: \(error.localizedDescription)"
        }
        refreshLoginStatus()
    }
}
