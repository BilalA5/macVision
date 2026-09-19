import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    let appState: AppState
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @State private var hoveredItem: String?

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
                }.buttonStyle(.bordered).help(appState.isStarting ? "Cancel camera startup" : appState.isActive ? "Deactivate" : "Activate")
                    .accessibilityLabel(appState.isStarting ? "Cancel camera startup" : appState.isActive ? "Deactivate macVision" : "Activate macVision")
            }.padding(16)
            Divider()
            VStack(spacing: 2) {
                menuItem(appState.actionsEnabled ? "Pause actions" : "Enable actions", symbol: appState.actionsEnabled ? "pause" : "checkmark") {
                    appState.setActionsEnabled(!appState.actionsEnabled)
                }.disabled(!appState.isActive || !appState.accessibilityGranted || appState.showsOnboarding || appState.calibration.isCollecting)
                if appState.isActive && !appState.accessibilityGranted {
                    menuItem("Allow Accessibility access", symbol: "lock.open") { appState.requestAccessibility() }
                }
                menuItem("Open macVision", symbol: "macwindow") { open(.overview) }
                menuItem("Practice & calibration", symbol: "viewfinder") { open(.practice) }
                menuItem("Settings", symbol: "slider.horizontal.3") { open(.settings) }
            }.padding(8)
            Divider()
            HStack {
                Keycaps(keys: ["⌃", "⌥", "⌘", "G"])
                Spacer()
                Button("Quit") { appState.deactivate(); NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 5).contentShape(Rectangle())
            }.padding(12)
        }
        .frame(width: 270)
        .background(VisionStyle.canvas(scheme).opacity(systemReduceTransparency || appState.presentation.reduceTransparency ? 1 : 0.88))
        .tint(VisionStyle.green)
        .preferredColorScheme(appState.presentation.colorScheme)
    }

    private func menuItem(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18).foregroundStyle(.secondary)
                Text(title).font(.system(size: 13))
                Spacer()
            }.padding(.horizontal, 8).frame(height: 34).contentShape(Rectangle())
                .background(hoveredItem == title ? Color.primary.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 6))
        }.buttonStyle(.plain)
            .onHover { hoveredItem = $0 ? title : nil }
    }

    private func open(_ section: AppSection) {
        appState.selectedSection = section
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
