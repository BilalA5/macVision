import SwiftUI

@main
struct macVisionApp: App {
    @State private var appState = AppState()
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
}
