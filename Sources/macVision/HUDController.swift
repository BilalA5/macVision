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
        // Keep feedback attached to the physical notch, independent of pointer position.
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens.first else { return }
        let top = screen.safeAreaInsets.top
        let notchWidth: CGFloat
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea, top > 0 {
            notchWidth = right.minX - left.maxX
        } else { notchWidth = 190 }
        state.hasNotch = top > 0
        state.notchHeight = top
        state.notchWidth = notchWidth
        state.reduceMotion = preferences.reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let repeats = panel?.isVisible == true && state.expanded && message.isAction
            && state.message.isAction && state.message.text == message.text
            && state.message.keycaps == message.keycaps
        state.repeatCount = repeats ? state.repeatCount + 1 : 1
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
        let height = (state.hasNotch ? top : 0) + state.contentHeight + 12
        let centerX = screen.auxiliaryTopLeftArea.flatMap { left in
            screen.auxiliaryTopRightArea.map { right in (left.maxX + right.minX) / 2 }
        } ?? screen.frame.midX
        let y = state.hasNotch ? screen.frame.maxY - height : screen.visibleFrame.maxY - height - 8
        hud.setFrame(NSRect(x: centerX - width / 2, y: y, width: width, height: height), display: true)
        let wasVisible = hud.isVisible
        if !wasVisible {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { state.expanded = false }
            hud.contentView?.layoutSubtreeIfNeeded()
        }
        hud.orderFrontRegardless()
        dismissal = Task { @MainActor [weak self] in
            do {
                // Present the collapsed surface before beginning a fresh entrance.
                if !wasVisible { try await Task.sleep(for: .milliseconds(32)) }
                guard !Task.isCancelled else { return }
                self?.state.expanded = true
                if message.progress != nil { return } // Live activities remain until their next state.
                try await Task.sleep(for: .seconds(1.8))
                guard let self else { return }
                self.state.expanded = false
                try await Task.sleep(for: .milliseconds(300))
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
