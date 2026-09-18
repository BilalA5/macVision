import SwiftUI

struct SettingsView: View {
    let appState: AppState
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { PreferencesPane(appState: appState) }
                .padding(28)
        }
        .frame(width: 590, height: 650)
        .background(VisionStyle.canvas(scheme))
        .tint(VisionStyle.green)
        .preferredColorScheme(appState.presentation.colorScheme)
        .sheet(isPresented: Binding(get: { appState.showsOnboarding }, set: { appState.showsOnboarding = $0 })) {
            OnboardingView(appState: appState)
        }
    }
}
