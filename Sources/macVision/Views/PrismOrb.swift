import SwiftUI

/// Original native rendering inspired by the public glass-and-ribbon reference.
struct PrismOrb: View {
    var active: Bool
    var reduceMotion = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var visible = false
    private var animates: Bool { visible && active && !reduceMotion && !systemReduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animates)) { timeline in
            let phase = animates ? timeline.date.timeIntervalSinceReferenceDate * 0.6 : 0
            Canvas { context, size in
                let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
                let circle = Path(ellipseIn: bounds)
                context.clip(to: circle)
                context.fill(circle, with: .radialGradient(Gradient(colors: [Color(white: 0.17), .black]),
                    center: CGPoint(x: size.width * 0.35, y: size.height * 0.25), startRadius: 0, endRadius: size.width * 0.8))
                let colors: [Color] = active ? [.pink, .purple, .blue, .cyan, .yellow] : [.gray, .white.opacity(0.5), .gray]
                for band in 0..<5 {
                    let t = Double(band) / 4
                    var ribbon = Path()
                    ribbon.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.54))
                    ribbon.addCurve(to: CGPoint(x: size.width * 0.92, y: size.height * 0.5),
                        control1: CGPoint(x: size.width * 0.32, y: size.height * (0.25 + t * 0.52 + sin(phase + t * 3) * 0.08)),
                        control2: CGPoint(x: size.width * 0.67, y: size.height * (0.72 - t * 0.48 + cos(phase + t * 2) * 0.07)))
                    context.drawLayer { glow in
                        glow.addFilter(.blur(radius: size.width * 0.055))
                        glow.stroke(ribbon, with: .linearGradient(Gradient(colors: [colors[band % colors.count], colors[(band + 2) % colors.count]]),
                            startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)),
                            style: StrokeStyle(lineWidth: size.width * 0.12, lineCap: .round))
                    }
                    context.stroke(ribbon, with: .color(colors[band % colors.count].opacity(0.65)),
                        style: StrokeStyle(lineWidth: size.width * 0.018, lineCap: .round))
                }
                context.stroke(circle, with: .linearGradient(Gradient(colors: [.white.opacity(0.65), .white.opacity(0.02), .white.opacity(0.12)]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 1)
                var glint = Path()
                glint.addArc(center: CGPoint(x: size.width / 2, y: size.height / 2), radius: size.width * 0.475,
                             startAngle: .degrees(215), endAngle: .degrees(270), clockwise: false)
                context.stroke(glint, with: .color(.white.opacity(0.65)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .background(WindowVisibility { visible = $0 }.frame(width: 0, height: 0))
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct ActiveEdgeGlow: View {
    var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion || systemReduceMotion)) { timeline in
            let angle = reduceMotion || systemReduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10) * 36
            let spectrum = AngularGradient(colors: [.cyan, .blue, .purple, .pink, .orange, .cyan], center: .center, angle: .degrees(angle))
            ZStack {
                ForEach(1..<13) { band in
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(spectrum, lineWidth: CGFloat(band) * 2)
                        .opacity(0.025)
                }
                RoundedRectangle(cornerRadius: 22).strokeBorder(spectrum, lineWidth: 1.5).opacity(0.8)
            }.padding(1).clipped()
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
