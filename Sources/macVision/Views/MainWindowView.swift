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

        VStack(alignment: .leading, spacing: 8){
            Text("Camera setup")
            .font(.headline)

            Text("Camera capture isn't connected yet. This area will help you check that your hands are visible from a comfortable working position")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        .padding(28)
        .frame(minWidth: 480, minHeight: 320)
    }
}