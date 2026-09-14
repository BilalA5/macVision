import AVFoundation
import OSLog

final class CameraManager : @unchecked Sendable {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "macVision.camera")
    private let logger = Logger(subsystem: "com.macVision.app", category: "Camera")

    private var isConfigured = false

    @MainActor
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session : session)
        previewLayer.videoGravity = .resizeAspect
        return previewLayer
    }

    func start() {
        queue.async { [self] in
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else{
                logger.error("Camera permission ahs not been granted.")
                return
            }

            guard !session.isRunning else {
                return
            }

            do {
                if !isConfigured {
                    try configure()
                }

                session.startRunning()

                if session.isRunning {
                    logger.info("Camera session started successfully.")
                }else{
                    logger.error("Failed to start camera session.")
                }
            }catch{
                logger.error("Camera setup failed : \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        queue.async { [self] in
            guard session.isRunning else {
                return
            }
        }

        session.stopRunning()
        logger.info("Camera session stopped.")
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device : device)
        let output = AVCaptureVideoDataOutput()

        output.alwaysDiscardsLateVideoFrames = true

        session.beginConfiguration()

        defer { session.commitConfiguration() }

        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }

        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }

        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw CameraError.cannotAddOutput
        }

        session.addOutput(output)
        isConfigured = true
            
    }
}

private enum CameraError: LocalizedError {
    case noCamera
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noCamera:
            return "No camera is available."
        case .cannotAddInput:
            return "The camera input could not be connected."
        case .cannotAddOutput:
            return "The video output could not be connected."
        }
    }
}
