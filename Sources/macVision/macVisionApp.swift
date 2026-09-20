import SwiftUI

@main
struct macVisionApp: App {
    @State private var appState = AppState()
    @State private var glowController = ActiveGlowController()
    @State private var hudController = HUDController()

    var body: some Scene {
        Window("macVision", id: "main") {
            MainWindowView(appState: appState)
        }
        .defaultSize(width: 860, height: 680)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image(systemName: appState.isActive ? "hand.pinch.fill" : "hand.pinch")
                .accessibilityLabel("macVision")
                .onChange(of: appState.isActive && appState.actionsEnabled && appState.presentation.showActiveGlow) { _, enabled in
                    glowController.update(enabled: enabled, reduceMotion: appState.presentation.reduceMotion)
                }
                .onChange(of: appState.presentation.reduceMotion) { _, reduced in
                    glowController.update(enabled: appState.isActive && appState.actionsEnabled && appState.presentation.showActiveGlow, reduceMotion: reduced)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                    glowController.update(enabled: appState.isActive && appState.actionsEnabled && appState.presentation.showActiveGlow, reduceMotion: appState.presentation.reduceMotion)
                }
                .onChange(of: appState.calibration.sampleCount) { _, _ in presentCalibration() }
                .onChange(of: appState.calibration.phase) { _, _ in presentCalibration() }
                .onChange(of: appState.hudMessage) { _, message in
                    if let message { hudController.show(message, preferences: appState.presentation) }
                }
                .onChange(of: appState.presentation.showHUD) { _, show in
                    if !show { hudController.hide() }
                }
        }
        .menuBarExtraStyle(.window)

        Settings { SettingsView(appState: appState) }
    }
    private func presentCalibration() {
        let calibration = appState.calibration
        let message: HUDMessage
        if calibration.isCollecting {
            message = HUDMessage(text: calibration.phase == .open ? "Open your fingers" : "Hold a gentle pinch",
                                 symbol: "hand.pinch", detail: "Calibrating · hold steady",
                                 progress: Double(calibration.sampleCount) / Double(CalibrationSession.requiredSamples))
        } else {
            message = HUDMessage(text: calibration.phase == .complete ? "Sensitivity saved" : "Calibration",
                                 symbol: calibration.phase == .complete ? "checkmark" : "hand.pinch",
                                 tone: calibration.phase == .complete ? .success : .neutral, detail: calibration.message)
        }
        hudController.show(message, preferences: appState.presentation)
    }

}
