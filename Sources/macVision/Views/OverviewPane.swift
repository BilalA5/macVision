import SwiftUI

struct OverviewPane: View {
    let appState: AppState
    @State private var diagnosticsOpen = false

    var body: some View {
        PaneHeading(title: "Overview", subtitle: "A little less reaching. A little more flow.")
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 9) {
                        if appState.isStarting { ProgressView().controlSize(.small) }
                        else {
                            Circle().fill(appState.errorMessage != nil && !appState.isActive ? .red : appState.isActive ? VisionStyle.green : .secondary)
                                .frame(width: 8, height: 8)
                        }
                        Text(appState.modeTitle).font(.system(size: 20, weight: .semibold)).tracking(-0.4)
                    }
                    Text(appState.modeDescription).font(.system(size: 12)).foregroundStyle(.secondary)
                        .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: appState.toggleActivation) {
                    Label(appState.isStarting ? "Cancel" : appState.isActive ? "Deactivate" : "Activate", systemImage: "power")
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .tint(appState.isActive ? .gray : VisionStyle.green)
            }
            HStack(spacing: 8) {
                Text("From any app").font(.system(size: 11)).foregroundStyle(.secondary)
                Keycaps(keys: ["⌃", "⌥", "⌘", "G"])
                if !appState.activationShortcutAvailable {
                    Text("Unavailable — use the menu bar").font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 8)

        VisionPanel {
            VStack(alignment: .leading, spacing: 12) {
                PreferenceRow(title: "Enable actions", subtitle: "Send your gesture shortcuts to the foreground app.") {
                    Toggle("Enable actions", isOn: Binding(get: { appState.actionsEnabled }, set: { appState.setActionsEnabled($0) }))
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                        .disabled(!appState.isActive || !appState.accessibilityGranted)
                }
                if !appState.accessibilityGranted {
                    Divider()
                    HStack(spacing: 10) {
                        Image(systemName: "lock.open").foregroundStyle(.secondary)
                        Text("Accessibility access is needed to send shortcuts.").font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button("Allow access", action: appState.requestAccessibility).controlSize(.small)
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionCaption(title: "Recent gestures")
                Spacer()
                Button("Practice", systemImage: "arrow.up.right") { appState.selectedSection = .practice }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if appState.recentActivity.isEmpty {
                VisionPanel {
                    HStack(spacing: 14) {
                        Image(systemName: "hand.pinch").font(.system(size: 24, weight: .light)).foregroundStyle(.secondary)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your next move starts here").font(.system(size: 12, weight: .medium))
                            Text("Activate, open your fingers, then try a pinch and release.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 12)
                }
            } else {
                VisionPanel {
                    VStack(spacing: 12) {
                        ForEach(appState.recentActivity) { activity in
                            HStack(spacing: 12) {
                                Image(systemName: activity.gesture.symbol).frame(width: 24).foregroundStyle(VisionStyle.green)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.gesture.title).font(.system(size: 12, weight: .medium))
                                    Text(activity.detail).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(activity.date, style: .time).font(.system(size: 10)).monospacedDigit().foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkle").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("Set it once. Keep your flow.").font(.system(size: 12, weight: .medium))
                Text("Your bindings and optional calibration stay saved. Close this window and macVision keeps working in the menu bar.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(3)
            }
        }.padding(.horizontal, 4)
        DisclosureGroup("Diagnostics", isExpanded: $diagnosticsOpen) {
            HStack {
                Text("Vision processing")
                Spacer()
                Text("\(appState.handTracking.processingMilliseconds, specifier: "%.1f") ms").monospacedDigit()
            }.font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            Text("Processing time is not end-to-end gesture latency.")
                .font(.caption2).foregroundStyle(.tertiary).frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11)).foregroundStyle(.secondary)
    }
}
