import SwiftUI
import AppKit

enum VisionStyle {
    static let green = Color(red: 0.25, green: 0.75, blue: 0.38)
    static let radius: CGFloat = 14
    static let pagePadding: CGFloat = 28
    static let sectionGap: CGFloat = 22
    static let hairline = Color.primary.opacity(0.08)
    static let surface = Color.primary.opacity(0.035)
    static let muted = Color.secondary
    static func canvas(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.115, green: 0.12, blue: 0.135) : Color(red: 0.965, green: 0.965, blue: 0.975)
    }
}

struct GlassMaterial: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) { view.material = material }
}

struct VisionPanel<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: VisionStyle.radius))
            .overlay(RoundedRectangle(cornerRadius: VisionStyle.radius).strokeBorder(Color.primary.opacity(contrast == .increased ? 0.3 : 0.08)))
            .shadow(color: .black.opacity(scheme == .dark ? 0.08 : 0.025), radius: 8, y: 3)
    }
}

struct SectionCaption: View {
    let title: String
    var body: some View {
        Text(title.uppercased()).font(.system(size: 10, weight: .semibold))
            .tracking(1.1).foregroundStyle(.secondary)
    }
}

struct PaneHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 26, weight: .semibold)).tracking(-0.5)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
        }
    }
}

struct StatusBadge: View {
    let title: String
    var color: Color = VisionStyle.green
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(color.opacity(0.1), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct Keycaps: View {
    let keys: [String]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                Text(key).font(.system(size: 11, weight: .medium))
                    .frame(minWidth: 19, minHeight: 22)
                    .padding(.horizontal, 3)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(VisionStyle.hairline))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(keys.joined(separator: " "))
    }
}

struct PreferenceRow<Content: View>: View {
    let title: String
    var subtitle: String = ""
    var symbol: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 14) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 14))
                    .foregroundStyle(.secondary).frame(width: 30, height: 30)
                    .background(VisionStyle.surface, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .medium))
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            content
        }
        .padding(.vertical, 7)
    }
}

struct AppMark: View {
    var size: CGFloat = 32
    var body: some View {
        Image(systemName: "hand.pinch.fill")
            .font(.system(size: size * 0.48, weight: .medium))
            .foregroundStyle(.white.opacity(0.92))
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [Color(white: 0.26), Color(white: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: size * 0.27))
            .overlay(RoundedRectangle(cornerRadius: size * 0.27).strokeBorder(.white.opacity(0.12)))
            .accessibilityHidden(true)
    }
}

extension Shortcut {
    var keycaps: [String] {
        var keys: [String] = []
        if control { keys.append("⌃") }
        if option { keys.append("⌥") }
        if shift { keys.append("⇧") }
        if command { keys.append("⌘") }
        let names = ["Tab": "⇥", "Page Up": "⇞", "Page Down": "⇟", "Return": "↩"]
        keys.append(names[label] ?? label)
        return keys
    }
    var actionTitle: String {
        if self == GesturePreferences.browserBindings["pinch"] { return "Next tab" }
        if self == GesturePreferences.browserBindings["hold"] { return "Previous tab" }
        if self == GesturePreferences.browserBindings["left"] { return "Back" }
        if self == GesturePreferences.browserBindings["right"] { return "Forward" }
        if self == GesturePreferences.browserBindings["up"] { return "Page up" }
        if self == GesturePreferences.browserBindings["down"] { return "Page down" }
        return "Custom shortcut"
    }
}

extension GestureKind {
    var symbol: String {
        switch self {
        case .pinch: "hand.pinch"
        case .hold: "pause"
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        case .down: "arrow.down"
        }
    }
}

struct WindowAppearance: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowConfigurationView { WindowConfigurationView() }
    func updateNSView(_ view: WindowConfigurationView, context: Context) { }
}

final class WindowConfigurationView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .clear
        window?.isOpaque = false
    }
}
