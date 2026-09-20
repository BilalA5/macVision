import SwiftUI

/// Native Button semantics with a consistent, legible primary treatment on macOS 14+.
struct VisionPrimaryButtonStyle: ButtonStyle {
    var quiet = false
    var reduceMotion = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(quiet ? Color.primary : .white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(minHeight: 32)
            .background(quiet ? Color.primary.opacity(0.09) : Color(red: 0.38, green: 0.28, blue: 0.80),
                        in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(quiet ? 0 : 0.12), lineWidth: 0.5))
            .opacity(enabled ? (configuration.isPressed ? 0.82 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion && !systemReduceMotion ? 0.98 : 1)
            .animation(reduceMotion || systemReduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}
