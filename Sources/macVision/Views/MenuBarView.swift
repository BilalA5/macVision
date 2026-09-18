import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let appState: AppState

    var body: some View {
        Text("macVision: \(appState.statusText)")

        Button((appState.isActive || appState.isStarting) ? "Deactivate" : "Activate"){
            appState.toggleActivation()
        }

        if appState.isActive {
            Button(appState.actionsEnabled ? "Pause actions" : "Enable actions") {
                appState.setActionsEnabled(!appState.actionsEnabled)
            }
            Text(appState.lastActionText)
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
            appState.deactivate()
            NSApplication.shared.terminate(nil)
        }
    }
}