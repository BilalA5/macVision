import SwiftUI

struct MainWindowView: View {
    let appState: AppState



    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("macVision")
                    .font(.largeTitle)
                    .bold()

                HStack {
                    Label(
                        appState.statusText,
                        systemImage: appState.isActive
                            ? "eye.fill"
                            : "eye"
                    )

                    Spacer()

                    Button(
                        (appState.isActive || appState.isStarting) ? "Deactivate" : "Activate"
                    ) {
                        appState.toggleActivation()
                    }
                }

                if let error = appState.errorMessage {
                    Text(error).foregroundStyle(.red)
                }

                if !appState.settings.preferences.onboardingComplete {
                    GroupBox("Welcome to macVision") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Allow camera access and activate.\n2. Check the green points and practice a pinch.\n3. Review your shortcuts, grant Accessibility access, then enable actions.")
                            Text("Calibration is optional. Camera frames are processed locally and are not saved.")
                                .font(.caption).foregroundStyle(.secondary)
                            Button("Finish setup") { appState.settings.finishOnboarding() }
                                .disabled(!appState.isActive || !appState.handTracking.handDetected)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                CameraSetupView()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera preview")
                        .font(.headline)

                    if appState.handTracking.isEnabled {
                        Text(appState.handTracking.pinchStatusText)
                            .font(.headline)
                        Text(appState.handTracking.handDetected ? "Hand detected" : "No hand detected")
                        Text("Confident joints : \(appState.handTracking.confidentJointCount)/21")
                        Text("Processing : \(appState.handTracking.processingMilliseconds, specifier : "%.1f") ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let frame = appState.handTracking.latestFrame, let pinch = PinchMeasurement(frame : frame) {
                            Text("Pinch ratio : \(pinch.ratio, specifier : "%.2f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }else{
                            Text("Not enough landmarks to calculate pinch ratio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }else{
                        Text("Hand Tracking disabled")
                        .foregroundStyle(.secondary)
                    }

                    ZStack {
                        Color.black

                        CameraPreview(camera: appState.camera, handFrame : appState.handTracking.latestFrame)
                            .opacity(appState.isActive ? 1 : 0)

                        if !appState.isActive {
                            Text("Activate macVision to view the camera.")
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                    .frame(height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Sit normally and check whether you can bring your hand into view comfortably.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                CalibrationView(appState: appState)
                Divider()
                GestureControlsView(appState: appState)
            }
            .padding(28)
        }
        .frame(minWidth: 640, minHeight: 480)
    }
}
