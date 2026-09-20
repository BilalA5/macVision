import AVFoundation

/// Capture configuration and start/stop operations are serialized on queue.
final class CameraManager: @unchecked Sendable {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "macVision.camera")
    private let handTracker: HandTracker
    private let failure: @MainActor @Sendable (UUID, String) -> Void
    private var isConfigured = false
    private var generation: UUID?
    private var observers: [NSObjectProtocol] = []

    init(receive: @escaping @MainActor @Sendable (TrackingSample) -> Void,
         failure: @escaping @MainActor @Sendable (UUID, String) -> Void) {
        handTracker = HandTracker(receive: receive)
        self.failure = failure
        for name in [AVCaptureSession.runtimeErrorNotification,
                     AVCaptureSession.wasInterruptedNotification,
                     AVCaptureSession.didStopRunningNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) {
                [weak self] _ in self?.captureFailed(force: name != AVCaptureSession.didStopRunningNotification)
            })
        }
    }

    deinit { observers.forEach(NotificationCenter.default.removeObserver) }

    @MainActor
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspect
        return layer
    }

    func start(generation: UUID, preferences: GesturePreferences,
               completion: @escaping @MainActor @Sendable (UUID, String?) -> Void) {
        queue.async { [self] in
            self.generation = generation
            do {
                guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                    throw CameraError.message("Allow camera access in System Settings → Privacy & Security → Camera.")
                }
                if !isConfigured { try configure() }
                handTracker.configure(generation: generation, preferences: preferences)
                if !session.isRunning { session.startRunning() }
                guard session.isRunning else {
                    throw CameraError.message("The camera could not start. Check whether it is available, then try again.")
                }
                Task { @MainActor in completion(generation, nil) }
            } catch {
                handTracker.configure(generation: nil)
                self.generation = nil
                if session.isRunning { session.stopRunning() }
                let message = error.localizedDescription
                Task { @MainActor in completion(generation, message) }
            }
        }
    }

    func stop() {
        queue.async { [self] in
            generation = nil
            handTracker.configure(generation: nil)
            if session.isRunning { session.stopRunning() }
        }
    }

    private func captureFailed(force: Bool) {
        queue.async { [self] in
            // Ignore notifications from an intentional stop or an old session.
            guard let generation, force || !session.isRunning else { return }
            self.generation = nil
            handTracker.configure(generation: nil)
            Task { @MainActor [failure] in
                failure(generation, "Camera capture stopped or was interrupted. Activate macVision to retry.")
            }
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraError.message("No camera is available.")
        }
        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        // Keep the camera's native bi-planar format instead of requesting RGB conversion.
        if output.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        }
        output.setSampleBufferDelegate(handTracker, queue: handTracker.processingQueue)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
        guard session.canAddInput(input) else { throw CameraError.message("The camera input could not be connected.") }
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw CameraError.message("The video output could not be connected.")
        }
        session.addOutput(output)
        if let connection = output.connection(with: .video), connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
        isConfigured = true
    }
}

private enum CameraError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let text) = self { text } else { nil }
    }
}
