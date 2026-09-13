import SwiftUI
import AppKit

struct MenuBarView: View {
    let appState: AppState

    var body: some View {
        Text(appState.isActive ? "macVision Active" : "macVision Off")

        Button(appState.isActive ? "Deactivate" : "Activate"){
            appState.toggleActivation()
        }

        Divider()

        SettingsLink{
            Text("Settings")
        }

        Divider()

        Button("Quit macVision"){
            NSApplication.shared.terminate(nil)
        }
    }
}