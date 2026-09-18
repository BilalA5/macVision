import SwiftUI
import AppKit

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: Shortcut?
    let onRecord: (Shortcut) -> Void
    let onBegin: () -> Void

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.bezelStyle = .rounded
        button.target = button
        button.action = #selector(RecorderButton.beginRecording)
        return button
    }

    func updateNSView(_ button: RecorderButton, context: Context) {
        button.onRecord = onRecord
        button.onBegin = onBegin
        button.shortcutTitle = shortcut?.displayName ?? "Record shortcut"
        if !button.recording { button.title = button.shortcutTitle }
    }
}

final class RecorderButton: NSButton {
    var onRecord: ((Shortcut) -> Void)?
    var onBegin: (() -> Void)?
    var shortcutTitle = "Record shortcut"
    private(set) var recording = false
    override var acceptsFirstResponder: Bool { true }

    @objc func beginRecording() {
        onBegin?()
        recording = true
        title = "Press shortcut (Esc cancels)"
        window?.makeFirstResponder(self)
    }

    override func resignFirstResponder() -> Bool {
        recording = false
        title = shortcutTitle
        return super.resignFirstResponder()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard recording, window?.firstResponder === self else { return super.performKeyEquivalent(with: event) }
        keyDown(with: event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard recording else { super.keyDown(with: event); return }
        guard !event.isARepeat else { return }
        if event.keyCode == 53 {
            recording = false
            title = shortcutTitle
            return
        }
        guard event.keyCode < 128 else { return }
        let special: [UInt16: String] = [48: "Tab", 49: "Space", 36: "Return", 51: "Delete",
            123: "←", 124: "→", 125: "↓", 126: "↑", 116: "Page Up", 121: "Page Down",
            115: "Home", 119: "End"]
        let label = special[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
        let flags = event.modifierFlags
        recording = false
        onRecord?(Shortcut(keyCode: event.keyCode, label: label,
                           command: flags.contains(.command), option: flags.contains(.option),
                           control: flags.contains(.control), shift: flags.contains(.shift)))
    }
}
