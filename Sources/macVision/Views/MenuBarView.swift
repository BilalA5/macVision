import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let appState: AppState

    var body: some View {
        Text(appState.isActive ? "macVision Active" : "macVision Off")

        Button(appState.isActive ? "Deactivate" : "Activate"){
            appState.toggleActivation()
        }

        Divider()

        Button("Open macVision"){
            openWindow(id: "main")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }

        SettingsLink{
            Text("Settings")
        }

        Divider()

        Button("Quit macVision"){
            NSApplication.shared.terminate(nil)
        }
    }
}