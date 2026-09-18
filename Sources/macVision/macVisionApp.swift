import SwiftUI


// The main app struct that initializes the menu bar extra
@main 
struct macVisionApp: App {
    @State private var appState = AppState() //Track the status of macVision
    @State private var hudController = HUDController() //Control the HUD in the status bar top right

    var body: some Scene {
        Window("macVision", id: "main"){
            MainWindowView(appState : appState)
        }
        .defaultSize(width: 700, height: 740)

        MenuBarExtra{
            MenuBarView(appState : appState)
        }label:{
            Image(
                systemName: appState.isActive ? "eye.fill" : "eye"
            )
            .accessibilityLabel("macVision")
            .onChange(of: appState.isActive, initial: true){
                _, isActive in

                if isActive {
                    hudController.show()
                }else{
                    hudController.hide()
                }
            }
        }

        Settings { 
            SettingsView(appState : appState)
        }
    }
}
