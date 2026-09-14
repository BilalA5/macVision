import AVFoundation
import Observation

@MainActor
@Observable
final class CameraPermission {
    private(set) var status = AVCaptureDevice.authorizationStatus(for : .video)

    private(set) var isRequesting = false

    func refresh() {
        status = AVCaptureDevice.authorizationStatus(for : .video)
    }

    func requestAccess() async {
        refresh()

        guard status == .notDetermined, !isRequesting else {
            return
        }
        isRequesting = true
        defer { isRequesting = false }

        _ = await AVCaptureDevice.requestAccess(for : .video)
        refresh()
    }
}