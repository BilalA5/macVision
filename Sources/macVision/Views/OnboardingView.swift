import SwiftUI

struct OnboardingView: View {
    let appState: AppState
    @State private var step = 0
    @Environment(\.colorScheme) private var scheme

    private let titles = ["Meet your next shortcut.", "Let your hands do the talking.", "Find your rhythm.", "Make it yours."]
    private let subtitles = [
        "A few small gestures. A smoother way around your browser.",
        "macVision processes your camera on this Mac. Your video is never recorded or uploaded.",
        "Open your thumb and index finger, pinch gently, then release. Actions stay off while you practice.",
        "Your browser shortcuts are ready. Start in practice mode, or allow Accessibility access to enable actions later."
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 5) {
                    ForEach(0..<4) { index in
                        Capsule().fill(index == step ? VisionStyle.green : Color.primary.opacity(0.12))
                            .frame(width: index == step ? 20 : 6, height: 5)
                    }
                }
                Text("\(step + 1) of 4").font(.system(size: 11)).monospacedDigit().foregroundStyle(.secondary)
                Spacer()
                Button { appState.showsOnboarding = false } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 24)
                }.buttonStyle(.plain).foregroundStyle(.secondary).accessibilityLabel("Close walkthrough")
            }
            .padding(24)
            ScrollView {
                VStack(spacing: 20) {
                    if step == 0 {
                        AppMark(size: 68).padding(.top, 8)
                    }
                    VStack(spacing: 10) {
                        Text(titles[step]).font(.system(size: 25, weight: .semibold)).tracking(-0.7)
                        Text(subtitles[step]).font(.system(size: 12)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).lineSpacing(4).frame(maxWidth: 380)
                    }
                    switch step {
                    case 0:
                        VStack(alignment: .leading, spacing: 10) {
                            benefit("hand.pinch", "Small, deliberate gestures", "Switch tabs, navigate pages, keep your flow.")
                            benefit("lock.shield", "Entirely on your Mac", "No account, no uploads, no camera recording.")
                            benefit("slider.horizontal.3", "Your shortcuts, your choice", "Adjust bindings once and keep them saved.")
                        }.padding(.vertical, 4)
                    case 1:
                        PermissionControls(appState: appState).padding(.horizontal, 8)
                    case 2:
                        CameraStage(appState: appState).frame(height: 190)
                        Text(appState.handTracking.handDetected ? appState.handTracking.pinchStatusText : "Bring one hand into view")
                            .font(.system(size: 12, weight: .medium))
                        if !appState.isActive {
                            Button(appState.isStarting ? "Cancel" : "Activate camera", action: appState.toggleActivation)
                                .buttonStyle(.borderedProminent)
                        }
                        if let error = appState.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                    default:
                        VisionPanel {
                            VStack(spacing: 14) {
                                ForEach([GestureKind.pinch, .hold, .left, .right], id: \.self) { gesture in
                                    HStack {
                                        Image(systemName: gesture.symbol).frame(width: 24).foregroundStyle(VisionStyle.green)
                                        Text(gesture.title).font(.system(size: 12))
                                        Spacer()
                                        Text(appState.settings.preferences.bindings[gesture.rawValue]?.actionTitle ?? "Unassigned")
                                            .font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }.padding(.horizontal, 8)
                        Text("Calibration is optional. You can revisit it any time.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.horizontal, 28).padding(.bottom, 24)
            }
            Spacer(minLength: 0)
            Divider()
            HStack {
                if step > 0 { Button("Back") { step -= 1 } }
                else { Text("WELCOME TO MACVISION").font(.system(size: 9, weight: .medium)).tracking(1).foregroundStyle(.tertiary) }
                Spacer()
                Button(step == 3 ? "Start using macVision" : "Continue") {
                    if step < 3 { step += 1 }
                    else {
                        appState.settings.finishOnboarding()
                        appState.selectedSection = .overview
                        appState.showsOnboarding = false
                    }
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }.padding(24)
        }
        .frame(width: 520, height: 560)
        .background(VisionStyle.canvas(scheme))
        .tint(VisionStyle.green)
        .onAppear { if appState.actionsEnabled { appState.setActionsEnabled(false) } }
    }

    private func benefit(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 17, weight: .regular)).foregroundStyle(VisionStyle.green)
                .frame(width: 36, height: 36)
                .background(VisionStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VisionStyle.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
