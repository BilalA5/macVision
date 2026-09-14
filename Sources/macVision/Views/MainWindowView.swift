import SwiftUI

struct MainWindowView: View {
    let appState : AppState
    

    var body: some View {
        Text("macVision")
        .font(.largeTitle)
        .bold()

        HStack {
            Label(
                appState.isActive ? "Active" : "Off",
                systemImage: appState.isActive ? "eye.fill" : "eye"
            )

            Spacer()

            Button(appState.isActive ? "Deactivate" : "Activate") {
                appState.toggleActivation()
            }
        }

        Divider()

        CameraSetupView()

        Spacer()

        .padding(28)
        .frame(minWidth: 480, minHeight: 320)
    }
}