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
                .onChange(of: appState.showsControlGlow, initial: true) { _, _ in updateGlow() }
                .onChange(of: appState.isGestureEngaged) { _, _ in updateGlow() }
                .onChange(of: appState.presentation.reduceMotion) { _, _ in updateGlow() }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in updateGlow() }
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
    private func updateGlow() {
        glowController.update(enabled: appState.showsControlGlow,
                              reduceMotion: appState.presentation.reduceMotion,
                              engaged: appState.isGestureEngaged)
    }

}
