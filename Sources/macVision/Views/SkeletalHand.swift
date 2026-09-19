import SwiftUI

/// An instructional diagram, separate from the camera's measured landmarks.
struct SkeletalHand: View, @MainActor Animatable {
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
            for (index, chain) in chains.enumerated() {
                let active = index == 0 || index == selected
                let points = chain.enumerated().map { joint, p in
                    let blend = active && joint > 1 ? closure * Double(joint - 1) / 3 : 0
                    return point(CGPoint(x: p.x + (target.x - p.x) * blend, y: p.y + (target.y - p.y) * blend))
                }
                var path = Path()
                path.addLines(points)
                context.stroke(path, with: .color(active ? VisionStyle.green.opacity(0.8) : .primary.opacity(0.25)),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                for (joint, p) in points.enumerated() {
                    let radius: CGFloat = joint == 4 && active ? 4.5 : 2.8
                    let dot = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                    context.fill(dot, with: .color(active ? VisionStyle.green : .primary.opacity(0.65)))
                }
            }
            var palm = Path()
            palm.addLines(chains.dropFirst().map { point($0[1]) })
            context.stroke(palm, with: .color(.primary.opacity(0.2)), lineWidth: 1)
        }
        .aspectRatio(0.85, contentMode: .fit)
        .accessibilityLabel("Skeletal illustration of a thumb and \(finger.title.lowercased()) pinch")
    }
}
