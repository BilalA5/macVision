import Foundation

@MainActor func preferencesPersistAndClearBindings() throws {
    let name = "macVision.tests.\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let settings = GestureSettings(defaults: defaults)
    settings.bind(.pinch, to: Shortcut(keyCode: 0, label: "A", command: true))
    expect(settings.calibrate(closed: 0.1, open: 0.8))
    settings.finishOnboarding()
    let reloaded = GestureSettings(defaults: defaults)
    expect(reloaded.preferences.bindings["pinch"]?.keyCode == 0)
    expect(reloaded.preferences.hasCalibration)
    expect(reloaded.preferences.onboardingComplete)
    reloaded.bind(.pinch, to: nil)
    expect(GestureSettings(defaults: defaults).preferences.bindings["pinch"] == nil)
}

@MainActor func invalidCalibrationDoesNotReplaceSettings() throws {
    let name = "macVision.tests.\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let settings = GestureSettings(defaults: defaults)
    expect(!settings.calibrate(closed: 0.4, open: 0.45))
    expect(!settings.calibrate(closed: .nan, open: 1))
    expect(!settings.preferences.hasCalibration)
    expect(settings.preferences.closeThreshold == 0.25)
}

@MainActor func corruptPreferencesFallBackWithoutCrashing() throws {
    let name = "macVision.tests.\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    defaults.set(Data("broken".utf8), forKey: "macVision.gesturePreferences.v1")
    let settings = GestureSettings(defaults: defaults)
    expect(settings.storageMessage != nil)
    expect(settings.preferences.isValid)
}
