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
                        appState.isActive ? "Active" : "Off",
                        systemImage: appState.isActive
                            ? "eye.fill"
                            : "eye"
                    )

                    Spacer()

                    Button(
                        appState.isActive ? "Deactivate" : "Activate"
                    ) {
                        appState.toggleActivation()
                    }
                }

                Divider()

                CameraSetupView()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera preview")
                        .font(.headline)

                    if appState.handTracking.isEnabled {
                        Text(appState.handTracking.handDetected ? "Hand detected" : "No hand detected")
                        Text("Confident joints : \(appState.handTracking.confidentJointCount)/21")
                        Text("Processing : \(appState.handTracking.processingMilliseconds, specifier : "%.1f") ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }else{
                        Text("Hand Tracking disabled")
                        .foregroundStyle(.secondary)
                    }

                    ZStack {
                        Color.black

                        CameraPreview(camera: appState.camera)
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
            }
            .padding(28)
        }
        .frame(minWidth: 480, minHeight: 360)
    }
}