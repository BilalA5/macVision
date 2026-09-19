import SwiftUI
import AppKit

/// Renders our own views to files without capturing the user's screen or enabling capture.
@main
struct RenderUI {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".build/ui-previews")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        UserDefaults.standard.setVolatileDomain(["ui.reduceTransparency": true, "ui.appearance": "system"],
                                                forName: UserDefaults.argumentDomain)
        let app = AppState(enableSystemServices: false)
        app.hasPresentedOnboarding = true
        for scheme in [ColorScheme.dark, .light] {
            let mode = scheme == .dark ? "dark" : "light"
            for section in AppSection.allCases {
                app.selectedSection = section
                let root = MainWindowView(appState: app).environment(\.colorScheme, scheme).preferredColorScheme(scheme)
                try render(root, size: NSSize(width: 860, height: 680), to: output.appendingPathComponent("\(section.rawValue)-\(mode).png"))
            }
            try render(OnboardingView(appState: app).environment(\.colorScheme, scheme), size: NSSize(width: 520, height: 560),
                       to: output.appendingPathComponent("onboarding-\(mode).png"))
            try render(MenuBarView(appState: app).environment(\.colorScheme, scheme), size: NSSize(width: 300, height: 330),
                       to: output.appendingPathComponent("menu-\(mode).png"))
            let preferences = ScrollView {
                VStack(alignment: .leading, spacing: 24) { PreferencesPane(appState: app) }.padding(28)
            }.background(VisionStyle.canvas(scheme)).environment(\.colorScheme, scheme)
            try render(preferences, size: NSSize(width: 630, height: 980), to: output.appendingPathComponent("preferences-full-\(mode).png"))
        }
        try render(GestureGuide(gesture: .right, finger: .middle, reduceMotion: true)
            .padding(24).frame(width: 380).background(VisionStyle.canvas(.dark)).environment(\.colorScheme, .dark),
            size: NSSize(width: 380, height: 360), to: output.appendingPathComponent("skeletal-guide.png"))
        app.selectedSection = .gestures
        try render(MainWindowView(appState: app).environment(\.colorScheme, .dark), size: NSSize(width: 800, height: 600),
                   to: output.appendingPathComponent("minimum-window.png"))
        let hud = HUDVisualState()
        hud.expanded = true
        hud.message = HUDMessage(text: "Next tab", symbol: "checkmark", tone: .success,
                                 keycaps: ["⌃", "⇥"], detail: "Shortcut sent", isAction: true)
        hud.repeatCount = 3
        try render(StatusHUDView(state: hud).background(Color(white: 0.2)), size: NSSize(width: 400, height: 100), to: output.appendingPathComponent("notch-hud.png"))
        for variant in ["collapsed", "permission", "pill", "reduced"] {
            hud.expanded = variant != "collapsed"
            hud.hasNotch = variant != "pill"
            hud.reduceMotion = variant == "reduced"
            hud.repeatCount = 1
            hud.message = variant == "permission"
                ? HUDMessage(text: "Camera permission required", symbol: "lock", tone: .error, detail: "Allow access in System Settings")
                : HUDMessage(text: "Ready to practice", symbol: "hand.pinch", detail: "Actions paused")
            try render(StatusHUDView(state: hud).background(Color(white: 0.2)), size: NSSize(width: 400, height: 110),
                       to: output.appendingPathComponent("notch-\(variant).png"))
        }
    }

    @MainActor static func render<V: View>(_ view: V, size: NSSize, to url: URL) throws {
        let host = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return }
        try png.write(to: url)
        window.orderOut(nil)
        print(url.lastPathComponent)
    }
}
