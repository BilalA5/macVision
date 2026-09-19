import SwiftUI

struct PracticePane: View {
    let appState: AppState
    @State private var expanded = false
    @State private var diagnostics = false

    private var guidance: String {
        if !appState.isActive { return appState.isStarting ? "Starting camera…" : "Your camera is off" }
        if !appState.handTracking.handDetected { return "Bring one hand into view" }
        if appState.handTracking.latestFrame.flatMap({ PinchMeasurement(frame: $0, finger: appState.settings.preferences.selectedFinger) }) == nil {
            return "Keep your whole hand visible"
        }
        return appState.handTracking.pinchStatusText
    }

    var body: some View {
        HStack(alignment: .top) {
            PaneHeading(title: "Practice", subtitle: "Get comfortable. Actions stay paused here.")
            Spacer()
            Button(expanded ? "Circular view" : "Full preview", systemImage: expanded ? "circle" : "arrow.up.left.and.arrow.down.right") {
                expanded.toggle()
            }.controlSize(.small)
        }
        VisionPanel {
        VStack(spacing: 20) {
            CameraStage(appState: appState, circular: !expanded)
                .frame(height: expanded ? 280 : 232)
            VStack(spacing: 8) {
                Text(guidance).font(.system(size: 16, weight: .medium))
                Text(appState.isActive ? "Open your fingers, pinch gently, then release." : appState.errorMessage ?? "Sit comfortably, then activate to see your hand landmarks.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                if !appState.isActive {
                    Button(appState.isStarting ? "Cancel" : "Activate camera", action: appState.toggleActivation)
                        .buttonStyle(.borderedProminent).padding(.top, 4)
                    if appState.errorMessage != nil {
                        Button("Review permissions") { appState.selectedSection = .settings }
                            .buttonStyle(.plain).font(.caption).foregroundStyle(VisionStyle.green)
                    }
                } else {
                    StatusBadge(title: "Actions paused", color: .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        PinchFingerPicker(appState: appState)
        DisclosureGroup("Learn the movement") {
            GestureGuide(gesture: .pinch, finger: appState.settings.preferences.selectedFinger,
                         reduceMotion: appState.presentation.reduceMotion).padding(.top, 12)
        }.font(.caption)
        CalibrationCard(appState: appState)
        DisclosureGroup("Tracking details", isExpanded: $diagnostics) {
            HStack(spacing: 32) {
                metric("Confident joints", "\(appState.handTracking.confidentJointCount)/21")
                metric("Pinch ratio", appState.handTracking.latestFrame.flatMap { PinchMeasurement(frame: $0, finger: appState.settings.preferences.selectedFinger) }
                    .map { String(format: "%.2f", $0.ratio) } ?? "—")
                metric("Vision processing", String(format: "%.1f ms", appState.handTracking.processingMilliseconds))
            }.padding(.top, 12)
        }
        .font(.system(size: 11)).foregroundStyle(.secondary)
        Label("Camera frames stay on your Mac and are never recorded.", systemImage: "lock.shield")
            .font(.system(size: 11)).foregroundStyle(.secondary)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 14, weight: .medium)).monospacedDigit().foregroundStyle(.primary)
            Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}

struct CameraStage: View {
    let appState: AppState
    var circular = true
    @Environment(\.colorScheme) private var scheme
    private var tracking: Bool { appState.isActive && appState.handTracking.latestFrame.flatMap { PinchMeasurement(frame: $0, finger: appState.settings.preferences.selectedFinger) } != nil }

    var body: some View {
        GeometryReader { geometry in
            let width = circular ? min(geometry.size.height, 240) : geometry.size.width
            let shape = circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 12))
            ZStack {
                RadialGradient(colors: [Color(white: 0.13), Color(white: 0.055)], center: .topLeading, startRadius: 0, endRadius: 280)
                if appState.isActive {
                    CameraPreview(camera: appState.camera, handFrame: appState.handTracking.latestFrame, finger: appState.settings.preferences.selectedFinger)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: appState.isStarting ? "viewfinder" : "camera")
                            .font(.system(size: 30, weight: .ultraLight)).foregroundStyle(.white.opacity(0.45))
                        if appState.isStarting { ProgressView().controlSize(.small).colorScheme(.dark) }
                        else { Text("Camera off").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4)) }
                    }
                }
            }
            .frame(width: width, height: geometry.size.height)
            .clipShape(shape)
            .overlay(shape
                .stroke(tracking ? VisionStyle.green.opacity(0.8) : Color.primary.opacity(0.15), lineWidth: tracking ? 2 : 1))
            .padding(3)
            .overlay {
                if circular {
                    Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        .frame(width: width + 12, height: geometry.size.height + 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel(appState.isActive ? "Live camera preview with hand landmarks" : "Camera is off")
    }
}

struct CalibrationCard: View {
    let appState: AppState
    var body: some View {
        VisionPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Personal calibration").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("OPTIONAL").font(.system(size: 9, weight: .semibold)).tracking(0.8).foregroundStyle(.secondary)
                }
                Text(appState.calibration.message).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
                HStack(spacing: 16) {
                    step("1", "Open fingers", done: appState.calibration.canCaptureClosed)
                    Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(.tertiary)
                    step("2", "Closed pinch", done: appState.calibration.phase == .complete)
                    Spacer()
                }
                if appState.calibration.isCollecting {
                    ProgressView(value: Double(appState.calibration.sampleCount), total: Double(CalibrationSession.requiredSamples)).tint(VisionStyle.green)
                    HStack {
                        Text("Hold steady…").font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        Spacer()
                        Button("Cancel", action: appState.calibration.cancel).controlSize(.small)
                    }
                } else {
                    HStack {
                        Button(appState.calibration.canCaptureClosed && appState.calibration.phase != .complete ? "Capture closed pinch" : "Calibrate") {
                            appState.beginCalibration(open: !appState.calibration.canCaptureClosed || appState.calibration.phase == .complete)
                        }.buttonStyle(.borderedProminent).disabled(!appState.isActive)
                        if appState.calibration.canCaptureClosed {
                            Button("Start again") { appState.beginCalibration(open: true) }.disabled(!appState.isActive)
                        }
                        Spacer()
                        if appState.settings.preferences.hasCalibration {
                            Button("Reset", action: appState.resetCalibration).buttonStyle(.plain).foregroundStyle(.secondary)
                        }
                    }
                    .controlSize(.small)
                }
                if appState.settings.preferences.hasCalibration {
                    Label("Personal sensitivity saved. No need to repeat each session.", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10)).foregroundStyle(VisionStyle.green)
                }
            }
        }
    }

    private func step(_ number: String, _ title: String, done: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(done ? VisionStyle.green.opacity(0.15) : Color.primary.opacity(0.05)).frame(width: 22, height: 22)
                if done { Image(systemName: "checkmark").font(.system(size: 9, weight: .semibold)).foregroundStyle(VisionStyle.green) }
                else { Text(number).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary) }
            }
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
}

struct PinchFingerPicker: View {
    let appState: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Pinch thumb with", selection: Binding(
                get: { appState.settings.preferences.selectedFinger },
                set: { appState.selectPinchFinger($0) }
            )) {
                ForEach(PinchFinger.allCases) { finger in Text(finger.title).tag(finger) }
            }.pickerStyle(.segmented)
            Text("Saved for everyday use. Changing fingers resets sensitivity and pauses actions.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
