// Settings of macVision, use for future gestures, activations, and general purpose, etc.
import SwiftUI

struct SettingsView : View{ 
    let appState: AppState

    var body: some View { 
        VStack(alignment: .leading, spacing : 16) {
            Text("macVision").font(.title).bold()

            Text(appState.isActive ? "Status: Active" : "Status: Off")
                .foregroundStyle(.secondary)
            
            Button(appState.isActive ? "Deactivate" : "Activate") {
                appState.toggleActivation()
            }
        }
        .padding(24)
        .frame(width: 360, height: 180)
    }
}