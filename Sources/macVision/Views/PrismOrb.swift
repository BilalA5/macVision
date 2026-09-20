import SwiftUI

/// Original native rendering inspired by the public glass-and-ribbon reference.
struct PrismOrb: View {
    var active: Bool
    var engaged = true
    var reduceMotion = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var visible = false
    private var animates: Bool { visible && active && engaged && !reduceMotion && !systemReduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animates)) { timeline in
            let phase = animates ? timeline.date.timeIntervalSinceReferenceDate * 0.6 : 0
            Canvas { context, size in
                let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
                let circle = Path(ellipseIn: bounds)
                context.clip(to: circle)
                context.fill(circle, with: .radialGradient(Gradient(colors: [Color(white: 0.025), .black]),
                    center: CGPoint(x: size.width * 0.35, y: size.height * 0.25), startRadius: 0, endRadius: size.width * 0.8))
                // Broad translucent folds converge at the refracted edges of the sphere.
                // A filled ribbon retains volume at small sizes; stroked waves look like wires.
                let w = size.width
                let h = size.height
                let left = CGPoint(x: w * 0.045, y: h * (0.43 + sin(phase) * 0.065))
                let right = CGPoint(x: w * 0.955, y: h * (0.54 - sin(phase) * 0.055))
                let palette: [Color] = active
                    ? [Color(red: 1, green: 0.83, blue: 0.13), .yellow,
                       Color(red: 1, green: 0.3, blue: 0.68), .pink, .purple, .blue,
                       Color(red: 0.28, green: 0.12, blue: 0.86)]
                    : [.gray, .white, .gray, .gray, .white, .gray, .white]
                for band in 0..<7 {
                    let t = Double(band) / 6
                    let crest = 0.25 + t * 0.38 + sin(phase + t * 2) * 0.055
                    let belly = crest + 0.14 + sin(t * .pi) * 0.16
                    var ribbon = Path()
                    ribbon.move(to: left)
                    ribbon.addCurve(to: right,
                        control1: CGPoint(x: w * 0.35, y: h * crest),
                        control2: CGPoint(x: w * 0.63, y: h * (crest + 0.01)))
                    ribbon.addCurve(to: left,
                        control1: CGPoint(x: w * 0.67, y: h * belly),
                        control2: CGPoint(x: w * 0.34, y: h * (belly + 0.06)))
                    ribbon.closeSubpath()
                    let shading = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [.white.opacity(0.9), palette[band],
                                          palette[min(6, band + 1)], .cyan.opacity(0.8)]),
                        startPoint: left, endPoint: right)
                    context.drawLayer { light in
                        light.addFilter(.blur(radius: w * 0.04))
                        light.opacity = 0.65
                        light.fill(ribbon, with: shading)
                    }
                    context.drawLayer { fold in
                        fold.addFilter(.blur(radius: w * 0.012))
                        fold.opacity = 0.52
                        fold.fill(ribbon, with: shading)
                    }
                }
                var goldEdge = Path()
                goldEdge.move(to: left)
                goldEdge.addCurve(to: right,
                    control1: CGPoint(x: w * 0.35, y: h * (0.25 + sin(phase) * 0.055)),
                    control2: CGPoint(x: w * 0.63, y: h * (0.26 + sin(phase) * 0.055)))
                context.drawLayer { edge in
                    edge.addFilter(.blur(radius: w * 0.006))
                    edge.stroke(goldEdge, with: .linearGradient(Gradient(colors: [.white.opacity(0.8), active ? .yellow : .gray, .white.opacity(0.1)]),
                        startPoint: left, endPoint: right), style: StrokeStyle(lineWidth: w * 0.013, lineCap: .round))
                }
                // Narrow white caustic across the centre binds the spectral folds together.
                var caustic = Path()
                caustic.move(to: left)
                caustic.addCurve(to: right,
                    control1: CGPoint(x: w * 0.36, y: h * (0.43 + sin(phase) * 0.04)),
                    control2: CGPoint(x: w * 0.7, y: h * (0.49 - sin(phase) * 0.04)))
                context.drawLayer { light in
                    light.addFilter(.blur(radius: w * 0.018))
                    light.stroke(caustic, with: .linearGradient(Gradient(colors: [.white, .pink.opacity(0.2), .cyan, .white]),
                        startPoint: left, endPoint: right), style: StrokeStyle(lineWidth: w * 0.026, lineCap: .round))
                }
                // Highlights follow the sphere, with a dark centre and a second lower reflection.
                context.stroke(circle, with: .linearGradient(Gradient(colors: [.white.opacity(0.04), .white.opacity(0.02), Color(red: 0.6, green: 0.66, blue: 0.8).opacity(0.45)]),
                    startPoint: .zero, endPoint: CGPoint(x: w * 0.65, y: h)), lineWidth: w * 0.006)
                for lower in [false, true] {
                    var glint = Path()
                    glint.addArc(center: CGPoint(x: w / 2, y: h / 2), radius: w * 0.475,
                        startAngle: .degrees(lower ? 30 : 205), endAngle: .degrees(lower ? 133 : 291), clockwise: false)
                    let highlight = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [.white.opacity(0), .white.opacity(lower ? 0.5 : 1), .white.opacity(0)]),
                        startPoint: CGPoint(x: w * 0.12, y: 0), endPoint: CGPoint(x: w * (lower ? 0.94 : 0.68), y: 0))
                    context.drawLayer { reflection in
                        reflection.addFilter(.blur(radius: w * 0.009))
                        reflection.stroke(glint, with: highlight, style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))
                    }
                    context.stroke(glint, with: highlight, style: StrokeStyle(lineWidth: w * 0.006, lineCap: .round))
                }
            }
        }
        .saturation(active ? 1 : 0)
        .opacity(active ? 1 : 0.55)
        .background(WindowVisibility { visible = $0 }.frame(width: 0, height: 0))
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct ActiveEdgeGlow: View {
    var reduceMotion = false
    var engaged = true
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !engaged || reduceMotion || systemReduceMotion)) { timeline in
            let angle = !engaged || reduceMotion || systemReduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10) * 36
            let colors: [Color] = [Color(red: 0.42, green: 0.82, blue: 0.97),
                Color(red: 0.53, green: 0.55, blue: 0.96), Color(red: 0.82, green: 0.48, blue: 0.88),
                Color(red: 1, green: 0.57, blue: 0.62), Color(red: 1, green: 0.75, blue: 0.43),
                Color(red: 0.42, green: 0.82, blue: 0.97)]
            let spectrum = AngularGradient(colors: colors, center: .center, angle: .degrees(angle))
            ZStack {
                // Superimposed translucent bands approximate a smooth 52 pt inward falloff
                // without blurring an entire display-sized offscreen texture every frame.
                ForEach(1..<27) { band in
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(spectrum, lineWidth: CGFloat(band) * 2)
                        .opacity(0.038 * exp(-Double(band) / 10))
                }
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(spectrum, lineWidth: 2).opacity(0.65)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.23), lineWidth: 0.75)
            }.padding(0.5).clipped()
        }
        .opacity(engaged ? 1 : 0.5)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
