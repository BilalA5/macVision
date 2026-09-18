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
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: state.hasNotch ? 0 : 16,
                                       bottomLeadingRadius: 18, bottomTrailingRadius: 18,
                                       topTrailingRadius: state.hasNotch ? 0 : 16)
                    .fill(.black)
                HStack(spacing: 10) {
                    Image(systemName: state.message.symbol).font(.system(size: 14, weight: .medium)).foregroundStyle(tint)
                    Text(state.message.text).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white).lineLimit(1).truncationMode(.tail)
                }
                .padding(.horizontal, 18)
                .frame(height: 42)
                .padding(.top, state.hasNotch ? state.notchHeight : 0)
                .opacity(state.expanded ? 1 : 0)
            }
            .frame(width: state.expanded ? max(340, state.notchWidth + 40) : state.hasNotch ? state.notchWidth : 220,
                   height: state.expanded ? (state.hasNotch ? state.notchHeight : 0) + 42 : state.hasNotch ? state.notchHeight : 0)
            .clipped()
            .opacity(state.hasNotch || state.expanded ? 1 : 0)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(state.reduceMotion ? nil : .spring(response: 0.30, dampingFraction: 0.86), value: state.expanded)
        .accessibilityElement(children: .combine)
    }
}
