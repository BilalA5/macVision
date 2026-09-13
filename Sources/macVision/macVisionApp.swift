import SwiftUI


// The main app struct that initializes the menu bar extra
@main 
struct macVisionApp: App {
    @State private var isActive = false //Track the status of macVision

    var body: some Scene {
        MenuBarExtra(
            "macVision",
            systemImage: isActive ? "eye.fill" : "eye"
        ) {
            Text(isActive ? "macVision on" : "macVision off")
            Button(isActive ? "Deactivate" : "Activate") { //Toggle on or off
                isActive.toggle()
            }

            Divider()

            Button("Quit") { //Quit macVision
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
