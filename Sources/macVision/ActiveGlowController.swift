import AppKit
import SwiftUI

@MainActor
final class ActiveGlowController {
    private var panel: NSPanel?

    func update(enabled: Bool, reduceMotion: Bool) {
        guard enabled, let screen = NSScreen.main else {
            // Remove the hosted timeline as well as the window so hidden glow does no work.
            panel?.orderOut(nil)
            panel?.contentView = nil
            return
        }
        let window: NSPanel
        if let panel { window = panel }
        else {
            window = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.hidesOnDeactivate = false
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel = window
        }
        window.contentView = NSHostingView(rootView: ActiveEdgeGlow(reduceMotion: reduceMotion))
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
    }
}
