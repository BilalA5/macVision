import SwiftUI

/// An instructional diagram, separate from the camera's measured landmarks.
struct HandIllustration: View, @MainActor Animatable {
    var closure: Double = 0
    var finger: PinchFinger = .index
    var animatableData: Double {
        get { closure }
        set { closure = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let chains: [[CGPoint]] = [
                [.init(x: 0.48, y: 0.87), .init(x: 0.32, y: 0.68), .init(x: 0.22, y: 0.55), .init(x: 0.16, y: 0.42), .init(x: 0.12, y: 0.32)],
                [.init(x: 0.48, y: 0.87), .init(x: 0.36, y: 0.52), .init(x: 0.32, y: 0.32), .init(x: 0.30, y: 0.19), .init(x: 0.29, y: 0.10)],
                [.init(x: 0.48, y: 0.87), .init(x: 0.49, y: 0.49), .init(x: 0.49, y: 0.27), .init(x: 0.49, y: 0.13), .init(x: 0.49, y: 0.05)],
                [.init(x: 0.48, y: 0.87), .init(x: 0.62, y: 0.52), .init(x: 0.65, y: 0.32), .init(x: 0.67, y: 0.19), .init(x: 0.68, y: 0.12)],
                [.init(x: 0.48, y: 0.87), .init(x: 0.73, y: 0.59), .init(x: 0.79, y: 0.44), .init(x: 0.82, y: 0.34), .init(x: 0.84, y: 0.26)]
            ]
            let selected = (PinchFinger.allCases.firstIndex(of: finger) ?? 0) + 1
            let target = CGPoint(x: (chains[0][4].x + chains[selected][4].x) / 2, y: 0.44)
            func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * size.width, y: p.y * size.height) }
            let posed = chains.enumerated().map { index, chain in
                chain.enumerated().map { joint, p in
                    let active = index == 0 || index == selected
                    let blend = active && joint > 1 ? closure * Double(joint - 1) / 3 : 0
                    return point(CGPoint(x: p.x + (target.x - p.x) * blend, y: p.y + (target.y - p.y) * blend))
                }
            }
            // A continuous palm and rounded fingers provide the recognizable silhouette.
            var silhouette = Path()
            silhouette.move(to: point(CGPoint(x: 0.28, y: 0.57)))
            silhouette.addQuadCurve(to: point(CGPoint(x: 0.37, y: 0.46)), control: point(CGPoint(x: 0.28, y: 0.46)))
            silhouette.addQuadCurve(to: point(CGPoint(x: 0.74, y: 0.55)), control: point(CGPoint(x: 0.69, y: 0.43)))
            silhouette.addCurve(to: point(CGPoint(x: 0.62, y: 0.85)), control1: point(CGPoint(x: 0.78, y: 0.72)), control2: point(CGPoint(x: 0.68, y: 0.80)))
            silhouette.addLine(to: point(CGPoint(x: 0.61, y: 0.94)))
            silhouette.addLine(to: point(CGPoint(x: 0.40, y: 0.94)))
            silhouette.addLine(to: point(CGPoint(x: 0.39, y: 0.84)))
            silhouette.addCurve(to: point(CGPoint(x: 0.28, y: 0.57)), control1: point(CGPoint(x: 0.28, y: 0.78)), control2: point(CGPoint(x: 0.23, y: 0.68)))
            silhouette.closeSubpath()
            let handColor = Color(white: 0.76)
            context.fill(silhouette, with: .color(handColor))
            for (index, points) in posed.enumerated() {
                var fingerPath = Path()
                fingerPath.addLines(Array(points.dropFirst()))
                context.stroke(fingerPath, with: .color(handColor), style: StrokeStyle(
                    lineWidth: size.width * (index == 4 ? 0.09 : 0.115), lineCap: .round, lineJoin: .round))
            }
            for index in [0, selected] {
                let points = posed[index]
                // Only the active fingertips carry an accent; no visible bone network.
                let tip = points[4]
                let radius: CGFloat = 3.5
                context.fill(Path(ellipseIn: CGRect(x: tip.x - radius, y: tip.y - radius,
                                                    width: radius * 2, height: radius * 2)), with: .color(VisionStyle.accent))
                let joint = points[2]
                var crease = Path()
                crease.move(to: CGPoint(x: joint.x - 2.5, y: joint.y))
                crease.addLine(to: CGPoint(x: joint.x + 2.5, y: joint.y))
                context.stroke(crease, with: .color(.black.opacity(0.12)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
        }
        .aspectRatio(0.85, contentMode: .fit)
        .accessibilityLabel("Hand illustration of a thumb and \(finger.title.lowercased()) pinch")
    }
}
