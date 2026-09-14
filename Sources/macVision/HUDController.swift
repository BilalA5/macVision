import SwiftUI
import AppKit

@MainActor
final class HUDController {
    private var panel: NSPanel?

    func show() {
        print("HUD show() called")
        guard let screen = NSScreen.main else {
            return
        }

        let hud: NSPanel

        if let existingPanel = panel {
            hud = existingPanel
        } else {
            hud = NSPanel(
                contentRect: NSRect(
                    x: 0,
                    y: 0,
                    width: 200,
                    height: 44
                ),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            hud.contentView = NSHostingView(
                rootView: StatusHUDView()
            )

            hud.backgroundColor = .clear
            hud.isOpaque = false
            hud.hasShadow = false
            hud.level = .floating
            hud.hidesOnDeactivate = false
            hud.ignoresMouseEvents = true
            hud.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary
            ]

            panel = hud
        }

        let x = screen.visibleFrame.midX - hud.frame.width / 2
        let y = screen.visibleFrame.maxY - hud.frame.height - 12

        hud.setFrameOrigin(NSPoint(x: x, y: y))
        hud.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }
}