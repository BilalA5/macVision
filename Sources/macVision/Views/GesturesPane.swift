import SwiftUI

struct GesturesPane: View {
    let appState: AppState
    var body: some View {
        HStack(alignment: .top) {
            PaneHeading(title: "Gestures", subtitle: "Small movements. Shortcuts that feel like yours.")
            Spacer()
            Button("Restore defaults", systemImage: "arrow.counterclockwise") {
                appState.setActionsEnabled(false)
                appState.settings.restoreBrowserBindings()
            }.controlSize(.small)
        }
        VStack(spacing: 0) {
            ForEach(GestureKind.allCases) { gesture in
                GestureBindingRow(appState: appState, gesture: gesture)
                if gesture != GestureKind.allCases.last { Divider().padding(.leading, 64) }
            }
        }
        .padding(.horizontal, 16)
        .background(VisionStyle.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(VisionStyle.hairline))
        VStack(alignment: .leading, spacing: 10) {
            SectionCaption(title: "Where gestures work")
            VisionPanel {
                VStack(spacing: 10) {
                    PreferenceRow(title: "Browser-only mode", subtitle: "Only send shortcuts when a supported browser is frontmost.") {
                        Toggle("Browser-only mode", isOn: Binding(
                            get: { appState.settings.preferences.browserOnly },
                            set: { appState.setActionsEnabled(false); appState.settings.setBrowserOnly($0) }
                        )).labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    Divider()
                    Text("Safari · Chrome · Arc · Firefox · Brave · Edge")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        Label("Shortcuts follow the focused app or text field. Changing a binding pauses actions.", systemImage: "info.circle")
            .font(.system(size: 11)).foregroundStyle(.secondary)
        if let message = appState.settings.storageMessage { Text(message).font(.caption).foregroundStyle(.orange) }
    }
}

private struct GestureBindingRow: View {
    let appState: AppState
    let gesture: GestureKind
    @State private var editing = false
    private var shortcut: Shortcut? { appState.settings.preferences.bindings[gesture.rawValue] }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: gesture.symbol).font(.system(size: 19, weight: .light))
                .frame(width: 34, height: 38)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 5) {
                Text(gesture.title).font(.system(size: 12, weight: .medium))
                Text(shortcut?.actionTitle ?? "No action assigned").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button { editing = true } label: {
                if let shortcut { Keycaps(keys: shortcut.keycaps) }
                else { Text("Assign shortcut").font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            .buttonStyle(.plain)
            .help("Edit shortcut for \(gesture.title)")
            .popover(isPresented: $editing, arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(gesture.title).font(.headline)
                    Text("Click Record, then press your shortcut. Escape cancels.")
                        .font(.caption).foregroundStyle(.secondary)
                    ShortcutRecorder(shortcut: shortcut, onRecord: {
                        appState.settings.bind(gesture, to: $0)
                        editing = false
                    }, onBegin: { appState.setActionsEnabled(false) })
                    .frame(width: 250, height: 32)
                    Button("Done") { editing = false }.frame(maxWidth: .infinity, alignment: .trailing)
                }.padding(20)
            }
            Menu {
                Button("Record shortcut…") { editing = true }
                Divider()
                ForEach(GestureKind.allCases) { preset in
                    if let binding = GesturePreferences.browserBindings[preset.rawValue] {
                        Button(binding.actionTitle) { assign(binding) }
                    }
                }
                Divider()
                Button("Clear binding") { assign(nil) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 24, height: 28)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel("Options for \(gesture.title)")
        }
        .padding(.vertical, 12)
    }

    private func assign(_ shortcut: Shortcut?) {
        appState.setActionsEnabled(false)
        appState.settings.bind(gesture, to: shortcut)
    }
}
