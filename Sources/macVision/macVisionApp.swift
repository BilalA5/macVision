import SwiftUI


// The main app struct that initializes the menu bar extra
@main 
struct macVisionApp: App {
    @State private var appState = AppState() //Track the status of macVision

    var body: some Scene {
        MenuBarExtra(
            "macVision",
            systemImage: appState.isActive ? "eye.fill" : "eye"
        ) {

            SettingsLink {
                Text("Settings")
            }

            
            Text(appState.isActive ? "macVision on" : "macVision off")
            Button(appState.isActive ? "Deactivate" : "Activate") { //Toggle on or off
                appState.toggleActivation()
            }

            Divider()

            Button("Quit") { //Quit macVision
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView(appState: appState)
        }
        
    }
}
