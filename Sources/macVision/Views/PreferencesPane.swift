import SwiftUI
import AVFoundation
import AppKit

struct PreferencesPane: View {
    let appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var appearance = appState.presentation
        PaneHeading(title: "Settings", subtitle: "A utility that settles into your Mac.")
        VStack(alignment: .leading, spacing: 10) {
            SectionCaption(title: "General")
            VisionPanel {
                VStack(spacing: 10) {
                    PreferenceRow(title: "Launch at login", subtitle: "Open macVision with the camera off.") {
                        Toggle("Launch at login", isOn: Binding(get: { appearance.loginEnabled }, set: { appearance.setLoginEnabled($0) }))
                            .labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    Divider()
                    PreferenceRow(title: "Global activation shortcut", subtitle: "Activate or stop capture from any app.") {
                        Keycaps(keys: ["⌃", "⌥", "⌘", "G"])
                    }
                    Divider()
                    PreferenceRow(title: "First-run walkthrough") {
                        Button("Show again") { appState.showsOnboarding = true }.controlSize(.small)
                    }
                    if let message = appearance.loginMessage { Text(message).font(.caption).foregroundStyle(.orange) }
                }
            }
        }
        VStack(alignment: .leading, spacing: 10) {
            SectionCaption(title: "Appearance & feedback")
            VisionPanel {
                VStack(spacing: 10) {
                    PreferenceRow(title: "Appearance") {
                        Picker("Appearance", selection: $appearance.appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }.pickerStyle(.segmented).labelsHidden().frame(width: 200)
                    }
                    Divider()
                    PreferenceRow(title: "Reduce transparency", subtitle: "Use solid surfaces for greater contrast.") {
                        Toggle("Reduce transparency", isOn: $appearance.reduceTransparency).labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    Divider()
                    PreferenceRow(title: "Reduce motion", subtitle: "Also respects your macOS accessibility preference.") {
                        Toggle("Reduce motion", isOn: $appearance.reduceMotion).labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    Divider()
                    PreferenceRow(title: "Notch feedback", subtitle: "Brief gesture confirmations, without taking focus.") {
                        Toggle("Notch feedback", isOn: $appearance.showHUD).labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                }
            }
        }
        PermissionControls(appState: appState)
        HStack(spacing: 10) {
            AppMark(size: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text("macVision").font(.system(size: 11, weight: .medium))
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0") · On-device hand tracking")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
        .onChange(of: scenePhase) { _, phase in if phase == .active { appearance.refreshLoginStatus() } }
    }
}

struct PermissionControls: View {
    let appState: AppState
    @State private var permission = CameraPermission()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionCaption(title: "Permissions")
            VisionPanel {
                VStack(spacing: 12) {
                    PreferenceRow(title: "Camera", subtitle: "For recognizing your hand. Frames are never saved.") {
                        if permission.status == .authorized {
                            Label("Allowed", systemImage: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(VisionStyle.green)
                        } else {
                            Button(permission.status == .notDetermined ? "Allow camera" : "Open Settings") {
                                if permission.status == .notDetermined { Task { await permission.requestAccess() } }
                                else { openPrivacy("Camera") }
                            }.controlSize(.small).disabled(permission.isRequesting)
                        }
                    }
                    Divider()
                    PreferenceRow(title: "Accessibility", subtitle: "Only needed to send keyboard shortcuts.") {
                        if appState.accessibilityGranted {
                            Label("Allowed", systemImage: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(VisionStyle.green)
                        } else {
                            Button("Allow access", action: appState.requestAccessibility).controlSize(.small)
                        }
                    }
                }
            }
            Button("Refresh permissions", systemImage: "arrow.clockwise") {
                permission.refresh(); appState.refreshPermissions()
            }.buttonStyle(.plain).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .task { permission.refresh(); appState.refreshPermissions() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { permission.refresh(); appState.refreshPermissions() }
        }
    }

    private func openPrivacy(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
