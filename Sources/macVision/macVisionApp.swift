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

            MenuBarView(appState : appState)
        }

        Settings {
            SettingsView(appState: appState)
        }
        
    }
}
