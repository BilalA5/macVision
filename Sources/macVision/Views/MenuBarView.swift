import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AppMark(size: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text("macVision").font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 5) {
                        Circle().fill(appState.isActive ? VisionStyle.green : Color.secondary).frame(width: 5, height: 5)
                        Text(appState.modeTitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: appState.toggleActivation) {
                    Image(systemName: "power").font(.system(size: 14)).frame(width: 28, height: 28)
                }.buttonStyle(.bordered).help(appState.isActive ? "Deactivate" : "Activate")
            }.padding(14)
            Divider()
            VStack(spacing: 2) {
                menuItem(appState.actionsEnabled ? "Pause actions" : "Enable actions", symbol: appState.actionsEnabled ? "pause" : "checkmark") {
                    appState.setActionsEnabled(!appState.actionsEnabled)
                }.disabled(!appState.isActive)
                menuItem("Open macVision", symbol: "macwindow") { open(.overview) }
                menuItem("Practice & calibration", symbol: "viewfinder") { open(.practice) }
                menuItem("Settings", symbol: "slider.horizontal.3") { open(.settings) }
            }.padding(6)
            Divider()
            HStack {
                Keycaps(keys: ["⌃", "⌥", "⌘", "G"])
                Spacer()
                Button("Quit") { appState.deactivate(); NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
            }.padding(12)
        }
        .frame(width: 270)
        .tint(VisionStyle.green)
        .preferredColorScheme(appState.presentation.colorScheme)
    }

    private func menuItem(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18).foregroundStyle(.secondary)
                Text(title).font(.system(size: 12))
                Spacer()
            }.padding(.horizontal, 8).frame(height: 32).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func open(_ section: AppSection) {
        appState.selectedSection = section
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
