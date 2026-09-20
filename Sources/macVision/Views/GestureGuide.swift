import SwiftUI

struct GestureGuide: View {
    let gesture: GestureKind
    let finger: PinchFinger
    var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var replay = 0
    @State private var closure = 0.0
    @State private var displacement: CGFloat = 0
    @State private var instruction = "Open your fingers"
    private var reduced: Bool { reduceMotion || systemReduceMotion }
    private var direction: CGSize {
        switch gesture {
        case .left: CGSize(width: -28, height: 0)
        case .right: CGSize(width: 28, height: 0)
        case .up: CGSize(width: 0, height: -24)
        case .down: CGSize(width: 0, height: 24)
        default: .zero
        }
    }
    private var steps: String {
        switch gesture {
        case .pinch: "Open → pinch → release"
        case .hold: "Open → pinch → hold → release"
        case .left: "Pinch → move left → release"
        case .right: "Pinch → move right → release"
        case .up: "Pinch → move up → release"
        case .down: "Pinch → move down → release"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                SectionCaption(title: "Gesture guide")
                Spacer()
                Text("Thumb + \(finger.title.lowercased())").font(.caption).foregroundStyle(.secondary)
            }
            HandIllustration(closure: reduced ? 0.65 : closure, finger: finger)
                .frame(height: 164)
                .offset(x: direction.width * displacement, y: direction.height * displacement)
                .frame(maxWidth: .infinity).frame(height: 216)
                .background(VisionStyle.surface, in: RoundedRectangle(cornerRadius: VisionStyle.radius))
            Text(reduced ? gesture.title : instruction).font(.system(size: 13, weight: .medium))
            Text(steps).font(.system(size: 11)).foregroundStyle(.secondary)
            HStack {
                Text("Illustration · no shortcuts sent").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button("Replay", systemImage: "arrow.clockwise") { replay += 1 }
                    .controlSize(.small).disabled(reduced)
            }
        }
        .task(id: replay) {
            guard replay > 0, !reduced else { return }
            closure = 0; displacement = 0; instruction = "Open your fingers"
            do {
                try await Task.sleep(for: .milliseconds(450))
                instruction = "Pinch gently"
                withAnimation(.easeInOut(duration: 0.25)) { closure = 1 }
                try await Task.sleep(for: .milliseconds(350))
                if gesture == .hold {
                    instruction = "Hold the pinch"
                    try await Task.sleep(for: .milliseconds(750))
                } else if direction != .zero {
                    instruction = "Move \(gesture.rawValue) while pinching"
                    withAnimation(.easeInOut(duration: 0.25)) { displacement = 1 }
                    try await Task.sleep(for: .milliseconds(450))
                }
                instruction = "Release to finish"
                withAnimation(.easeOut(duration: 0.2)) { closure = 0 }
                try await Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.2)) { displacement = 0 }
                instruction = "Try it in Practice"
            } catch { }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { reset() } }
        .onChange(of: reduced) { _, _ in reset() }
        .onChange(of: finger) { _, _ in reset() }
    }

    private func reset() {
        replay = 0; closure = 0; displacement = 0; instruction = "Open your fingers"
    }
}
