import AppKit
@preconcurrency import ApplicationServices

@MainActor
struct ActionExecutor {
    var hasPermission: Bool { AXIsProcessTrusted() }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func execute(_ shortcut: Shortcut, browserOnly: Bool) -> String? {
        guard hasPermission else { return "Allow Accessibility access to send shortcuts." }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return "Switch to the app you want to control."
        }
        if browserOnly {
            let browsers: Set<String> = ["com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
                "com.microsoft.edgemac", "com.brave.Browser", "company.thebrowser.Browser"]
            guard let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                  browsers.contains(app) else { return "Browser mode: switch to a supported browser." }
        }
        guard shortcut.keyCode < 128,
              let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else {
            return "The keyboard shortcut could not be created."
        }
        var flags: CGEventFlags = []
        if shortcut.command { flags.insert(.maskCommand) }
        if shortcut.option { flags.insert(.maskAlternate) }
        if shortcut.control { flags.insert(.maskControl) }
        if shortcut.shift { flags.insert(.maskShift) }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return nil
    }
}
