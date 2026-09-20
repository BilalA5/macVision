import SwiftUI
import Observation

@MainActor @Observable
final class HUDVisualState {
    var message = HUDMessage(text: "Ready to practice", symbol: "hand.pinch")
    var expanded = false
    var repeatCount = 1
    var notchWidth: CGFloat = 190
    var notchHeight: CGFloat = 32
    var hasNotch = true
    var reduceMotion = false
}

/// Interpolates the silhouette, preserving round corners instead of stretching them.
struct NotchSurface: Shape {
    var progress: CGFloat
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let hasNotch: Bool
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let t = min(1, max(0, progress))
        let width = notchWidth + (rect.width - notchWidth) * t
        let height = notchHeight + (rect.height - notchHeight) * t
        let x = rect.midX - width / 2
        if !hasNotch {
            return Path(roundedRect: CGRect(x: x, y: 0, width: width, height: height), cornerRadius: 22)
        }
        let shoulder = 9 * t
        let radius = min(20, height / 2)
        let left = x + shoulder
        let right = x + width - shoulder
        var p = Path()
        p.move(to: CGPoint(x: x, y: 0))
        p.addLine(to: CGPoint(x: x + width, y: 0))
        p.addQuadCurve(to: CGPoint(x: right, y: shoulder), control: CGPoint(x: right, y: 0))
        p.addLine(to: CGPoint(x: right, y: height - radius))
        p.addQuadCurve(to: CGPoint(x: right - radius, y: height), control: CGPoint(x: right, y: height))
        p.addLine(to: CGPoint(x: left + radius, y: height))
        p.addQuadCurve(to: CGPoint(x: left, y: height - radius), control: CGPoint(x: left, y: height))
        p.addLine(to: CGPoint(x: left, y: shoulder))
        p.addQuadCurve(to: CGPoint(x: x, y: 0), control: CGPoint(x: left, y: 0))
        p.closeSubpath()
        return p
    }
}

struct StatusHUDView: View {
    let state: HUDVisualState
    private var tint: Color {
        switch state.message.tone { case .success: VisionStyle.green; case .neutral: .white.opacity(0.85); case .error: .orange }
    }
    private var width: CGFloat { max(360, state.notchWidth + 64) }
    private var height: CGFloat { (state.hasNotch ? state.notchHeight : 0) + 60 }
    private var surface: NotchSurface {
        NotchSurface(progress: state.expanded || state.reduceMotion ? 1 : 0,
                     notchWidth: state.notchWidth, notchHeight: state.hasNotch ? state.notchHeight : 44,
                     hasNotch: state.hasNotch)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Opaque black, without a rim or material, blends into the hardware cutout.
            surface.fill(Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1))
            HStack(spacing: 12) {
                ZStack {
                    if let progress = state.message.progress {
                        Circle().stroke(.white.opacity(0.12), lineWidth: 2)
                        Circle().trim(from: 0, to: min(1, max(0, progress)))
                            .stroke(VisionStyle.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    Image(systemName: state.message.symbol)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(tint)
                    .frame(width: 29, height: 29)
                    .background(.white.opacity(0.08), in: Circle())
                }.frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.message.text).font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white).lineLimit(1).truncationMode(.tail)
                    if !state.message.keycaps.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(state.message.keycaps.enumerated()), id: \.offset) { _, key in
                                Text(key).font(.system(size: 10, weight: .medium))
                                    .frame(minWidth: 16, minHeight: 17)
                                    .padding(.horizontal, 2)
                                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                            }
                            Text(state.message.detail ?? "Shortcut sent")
                                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
                        }.foregroundStyle(.white.opacity(0.85))
                    } else if let detail = state.message.detail {
                        Text(detail).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let progress = state.message.progress {
                    Text("\(Int(min(1, max(0, progress)) * 100))%")
                        .font(.system(size: 12, weight: .medium).monospacedDigit()).foregroundStyle(.white.opacity(0.7))
                } else if state.repeatCount > 1 {
                    Text("×\(state.repeatCount)").font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, 26)
            .frame(width: width, height: 60)
            .padding(.top, state.hasNotch ? state.notchHeight : 0)
            .offset(y: state.expanded || state.reduceMotion ? 0 : -6)
            .opacity(state.expanded ? 1 : 0)
            .mask(surface)
        }
        .frame(width: width, height: height, alignment: .top)
        .opacity(state.expanded || (state.hasNotch && !state.reduceMotion) ? 1 : 0)
        .animation(state.reduceMotion ? .linear(duration: 0.12) :
            .timingCurve(0.32, 0.72, 0, 1, duration: state.expanded ? 0.22 : 0.18), value: state.expanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
    }
}
