import SwiftUI
import Observation

@MainActor @Observable
final class HUDVisualState {
    var message = HUDMessage(text: "Ready to practice", symbol: "hand.pinch")
    var expanded = false
    var notchWidth: CGFloat = 190
    var notchHeight: CGFloat = 32
    var hasNotch = true
    var reduceMotion = false
}

struct StatusHUDView: View {
    let state: HUDVisualState
    private var tint: Color {
        switch state.message.tone { case .success: VisionStyle.green; case .neutral: .white.opacity(0.65); case .error: .orange }
    }
    private var width: CGFloat { max(340, state.notchWidth + 40) }
    private var height: CGFloat { (state.hasNotch ? state.notchHeight : 0) + 42 }
    private var surface: some View {
        UnevenRoundedRectangle(topLeadingRadius: state.hasNotch ? 0 : 16,
                               bottomLeadingRadius: 18, bottomTrailingRadius: 18,
                               topTrailingRadius: state.hasNotch ? 0 : 16)
            .scaleEffect(x: state.expanded ? 1 : state.notchWidth / width,
                         y: state.expanded ? 1 : max(1, state.notchHeight) / height,
                         anchor: .top)
    }

    var body: some View {
        // Fixed layout keeps both edges equidistant from the screen center throughout motion.
        ZStack(alignment: .top) {
            surface.foregroundStyle(.black)
            HStack(spacing: 10) {
                Image(systemName: state.message.symbol)
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(tint)
                Text(state.message.text).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white).lineLimit(1).truncationMode(.tail)
            }
            .padding(.horizontal, 18)
            .frame(width: width, height: 42)
            .padding(.top, state.hasNotch ? state.notchHeight : 0)
            .offset(y: state.expanded || state.reduceMotion ? 0 : -12)
            .opacity(state.expanded ? 1 : 0)
            .mask(surface)
        }
        .frame(width: width, height: height, alignment: .top)
        .opacity(state.hasNotch || state.expanded ? 1 : 0)
        .animation(state.reduceMotion ? nil : .timingCurve(0.23, 1, 0.32, 1, duration: 0.25), value: state.expanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
    }
}
