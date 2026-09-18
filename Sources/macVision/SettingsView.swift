import SwiftUI

struct SettingsView: View {
    let appState: AppState
    var body: some View {
        ScrollView {
            GestureControlsView(appState: appState)
                .padding(24)
        }
        .frame(width: 620, height: 560)
    }
}
