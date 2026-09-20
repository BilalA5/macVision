import SwiftUI
import AppKit

/// Keeps decorative rendering asleep when its own window is hidden or fully covered.
struct WindowVisibility: NSViewRepresentable {
    var onChange: (Bool) -> Void
    func makeNSView(context: Context) -> VisibilityProbe {
        let view = VisibilityProbe()
        view.onChange = onChange
        return view
    }
    func updateNSView(_ view: VisibilityProbe, context: Context) { view.onChange = onChange }
    static func dismantleNSView(_ view: VisibilityProbe, coordinator: ()) { view.stop() }
}

final class VisibilityProbe: NSView {
    var onChange: ((Bool) -> Void)?
    private var observation: NSObjectProtocol?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stop()
        guard let window else { return }
        observation = NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification,
            object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.publish() }
            }
        Task { @MainActor [weak self] in self?.publish() }
    }
    private func publish() { onChange?(window?.occlusionState.contains(.visible) == true) }
    func stop() {
        if let observation { NotificationCenter.default.removeObserver(observation) }
        observation = nil
    }
}
