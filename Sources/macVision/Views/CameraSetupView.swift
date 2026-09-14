import SwiftUI
import AVFoundation

struct CameraSetupView: View {
    @State private var permission = CameraPermission()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Camera Setup")
                .font(.headline)

            switch permission.status {
            case .notDetermined:
                Text("Allow camera access so macVision can recognize your hand gestures.")
                    .foregroundStyle(.secondary)

                Button("Allow Camera Access") {
                    Task {
                        await permission.requestAccess()
                    }
                }
                .disabled(permission.isRequesting)

            case .authorized:
                Label(
                    "Camera Access Granted",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

                Text("Use Activate to start camera capture and Deactivate to stop it.")
                    .foregroundStyle(.secondary)

            case .denied:
                Label(
                    "Camera Access Denied",
                    systemImage: "camera.fill"
                )

                Text("Enable macVision in System Settings → Privacy & Security → Camera.")
                    .foregroundStyle(.secondary)

            case .restricted:
                Text("Camera access is restricted on this device. Check device restrictions.")
                    .foregroundStyle(.secondary)

            @unknown default:
                Text("Camera permission status is unavailable.")
                    .foregroundStyle(.secondary)
            } 

            Button("Refresh Status") {
                permission.refresh()
            }
            .font(.caption)
        } 
        .fixedSize(horizontal: false, vertical: true)
        .task {
            permission.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                permission.refresh()
            }
        }
    }
}