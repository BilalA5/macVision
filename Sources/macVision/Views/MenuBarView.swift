import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let appState: AppState
    @State private var hoveredItem: String?

    private var canEnableActions: Bool {
        appState.isActive && appState.accessibilityGranted && !appState.showsOnboarding && !appState.calibration.isCollecting
    }
    private var actionHint: String {
        if appState.actionsEnabled { return "Shortcuts are ready" }
        if !appState.isActive { return "Activate the camera first" }
        if !appState.accessibilityGranted { return "Accessibility access required" }
        if appState.showsOnboarding || appState.calibration.isCollecting { return "Paused during setup" }
        return "Practice without sending shortcuts"
    }
    private var powerTitle: String {
        appState.isStarting ? "Cancel" : appState.isActive ? "Deactivate" : "Activate"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                AppMark(size: 26)
                Text("macVision").font(.system(size: 14, weight: .semibold)).tracking(-0.3)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(appState.isActive ? VisionStyle.accent : Color.secondary).frame(width: 5, height: 5)
                    Text(appState.modeTitle).font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(VisionStyle.surface, in: Capsule())
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 4).padding(.top, 4)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(appState.isStarting ? "Connecting camera" : appState.isActive ? "Camera running" : "Ready when you are")
                            .font(.system(size: 12, weight: .medium))
                        Text(appState.isActive ? "Processing on this Mac" : "Start with a simple gesture")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button(action: appState.toggleActivation) {
                        Label(powerTitle, systemImage: "power")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent).controlSize(.regular)
                    .buttonBorderShape(.capsule)
                    .tint(appState.isActive ? Color.secondary : VisionStyle.accent)
                    .accessibilityLabel("\(powerTitle) macVision")
                }
                Rectangle().fill(VisionStyle.hairline).frame(height: 1)
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Gesture actions").font(.system(size: 12, weight: .medium))
                        Text(actionHint).font(.system(size: 10)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Toggle("Gesture actions", isOn: Binding(get: { appState.actionsEnabled }, set: { appState.setActionsEnabled($0) }))
                        .toggleStyle(.switch).controlSize(.mini).labelsHidden()
                        .disabled(!appState.actionsEnabled && !canEnableActions)
                        .help(actionHint)
                }
                if appState.isActive && !appState.accessibilityGranted {
                    Button("Allow Accessibility access", action: appState.requestAccessibility)
                        .controlSize(.small).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(scheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary.opacity(contrast == .increased ? 0.3 : 0.07)))

            VStack(spacing: 2) {
                menuItem("Open macVision", symbol: "macwindow") { open(.overview) }
                menuItem("Practice & calibration", symbol: "viewfinder") { open(.practice) }
                menuItem("Settings", symbol: "slider.horizontal.3") { open(.settings) }
            }

            HStack(spacing: 6) {
                Text("Activate").font(.system(size: 10)).foregroundStyle(.secondary)
                Text("⌃ ⌥ ⌘ G").font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Control Option Command G")
                Spacer()
                Button { appState.deactivate(); NSApplication.shared.terminate(nil) } label: {
                    Text("Quit").font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 6).contentShape(Rectangle())
                }.buttonStyle(.plain).help("Quit macVision")
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .overlay(alignment: .top) { Rectangle().fill(VisionStyle.hairline).frame(height: 1) }
        }
        .padding(12)
        .frame(width: 312)
        .background(VisionStyle.canvas(scheme).opacity(systemReduceTransparency || appState.presentation.reduceTransparency ? 1 : 0.94))
        .tint(VisionStyle.accent)
        .accentColor(VisionStyle.accent)
        .preferredColorScheme(appState.presentation.colorScheme)
    }

    private func menuItem(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 13)).frame(width: 18).foregroundStyle(.secondary)
                Text(title).font(.system(size: 12, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 9).frame(height: 36).contentShape(Rectangle())
            .background(hoveredItem == title ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hoveredItem = $0 ? title : nil }
    }

    private func open(_ section: AppSection) {
        appState.selectedSection = section
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
