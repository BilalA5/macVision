import SwiftUI
import AppKit

@MainActor
final class HUDController {
    private var panel: NSPanel?
    private let state = HUDVisualState()
    private var dismissal: Task<Void, Never>?

    func show(_ message: HUDMessage, preferences: PresentationSettings) {
        dismissal?.cancel()
        guard preferences.showHUD else { hide(); return }
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main else { return }
        let top = screen.safeAreaInsets.top
        let notchWidth: CGFloat
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea, top > 0 {
            notchWidth = right.minX - left.maxX
        } else { notchWidth = 190 }
        state.hasNotch = top > 0
        state.notchHeight = top
        state.notchWidth = notchWidth
        state.reduceMotion = preferences.reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        state.message = message

        let hud: NSPanel
        if let panel { hud = panel }
        else {
            hud = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            hud.contentView = NSHostingView(rootView: StatusHUDView(state: state))
            hud.backgroundColor = .clear
            hud.isOpaque = false
            hud.hasShadow = false
            hud.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
            hud.hidesOnDeactivate = false
            hud.ignoresMouseEvents = true
            hud.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel = hud
        }
        let width = max(400, notchWidth + 80)
        let height = (state.hasNotch ? top : 0) + 60
        let y = state.hasNotch ? screen.frame.maxY - height : screen.visibleFrame.maxY - height - 8
        hud.setFrame(NSRect(x: screen.frame.midX - width / 2, y: y, width: width, height: height), display: true)
        hud.orderFrontRegardless()
        dismissal = Task { @MainActor [weak self] in
            do {
                await Task.yield()
                guard !Task.isCancelled else { return }
                self?.state.expanded = true
                try await Task.sleep(for: .seconds(1.8))
                guard let self else { return }
                self.state.expanded = false
                try await Task.sleep(for: .milliseconds(350))
                self.panel?.orderOut(nil)
            } catch { }
        }
    }

    func hide() {
        dismissal?.cancel()
        state.expanded = false
        panel?.orderOut(nil)
    }
}
