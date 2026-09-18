import SwiftUI

struct GestureControlsView: View {
    let appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gesture actions").font(.headline)
            Text("Pinch and release for the next tab; hold and release for the previous tab. Pinch, move, then release for back/forward or page up/down.")
                .foregroundStyle(.secondary)
            Toggle("Enable actions", isOn: Binding(
                get: { appState.actionsEnabled }, set: { appState.setActionsEnabled($0) }
            ))
            Text(appState.lastActionText).font(.caption)
            Text("Last gesture: \(appState.lastGestureText)").font(.caption)

            if !appState.accessibilityGranted {
                Button("Allow Accessibility access") { appState.requestAccessibility() }
                Text("Camera detection works without this permission. Sending keyboard shortcuts requires it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button("Refresh permissions") { appState.refreshPermissions() }
                .font(.caption)

            Toggle("Only send shortcuts to browsers", isOn: Binding(
                get: { appState.settings.preferences.browserOnly },
                set: {
                    appState.setActionsEnabled(false)
                    appState.settings.setBrowserOnly($0)
                }
            ))
            Text("Supported: Safari, Chrome, Firefox, Edge, Brave and Arc. Shortcuts act on the focused page or field.")
                .font(.caption).foregroundStyle(.secondary)

            ForEach(GestureKind.allCases) { gesture in
                HStack {
                    Text(gesture.title).frame(width: 150, alignment: .leading)
                    ShortcutRecorder(
                        shortcut: appState.settings.preferences.bindings[gesture.rawValue],
                        onRecord: { appState.settings.bind(gesture, to: $0) },
                        onBegin: { appState.setActionsEnabled(false) }
                    )
                    .frame(width: 220, height: 28)
                    Button("Clear") {
                        appState.setActionsEnabled(false)
                        appState.settings.bind(gesture, to: nil)
                    }
                }
            }
            Button("Restore browser shortcuts") {
                appState.setActionsEnabled(false)
                appState.settings.restoreBrowserBindings()
            }
            if let message = appState.settings.storageMessage {
                Text(message).foregroundStyle(.orange)
            }
        }
        .task { appState.refreshPermissions() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appState.refreshPermissions() }
        }
    }
}

struct CalibrationView: View {
    let appState: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice & calibration").font(.headline)
            Text("Keep the green dots aligned with your hand at a comfortable sitting position. Practice works with actions off; calibration is optional.")
                .foregroundStyle(.secondary)
            Text(appState.calibration.message)
            if appState.calibration.isCollecting {
                ProgressView(value: Double(appState.calibration.sampleCount), total: 25)
                Button("Cancel calibration") { appState.calibration.cancel() }
            } else {
                HStack {
                    Button("1. Capture open fingers") { appState.beginCalibration(open: true) }
                    Button("2. Capture closed pinch") { appState.beginCalibration(open: false) }
                }
                .disabled(!appState.isActive)
            }
            HStack {
                Text(appState.settings.preferences.hasCalibration ? "Personal sensitivity saved" : "Using default sensitivity")
                    .font(.caption)
                Button("Reset sensitivity") { appState.resetCalibration() }
            }
        }
    }
}
