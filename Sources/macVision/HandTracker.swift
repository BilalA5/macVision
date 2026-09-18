import AVFoundation
import Vision
import OSLog

struct TrackingSample: Sendable {
    let generation: UUID
    let sequence: UInt64
    let frame: HandFrame?
    let pinchState: PinchRecognizer.State
    let gesture: GestureKind?
    let processingMilliseconds: Double
    let capturedAt: Double
}

/// Mutable Vision/recognizer state belongs exclusively to processingQueue.
final class HandTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let processingQueue = DispatchQueue(label: "macVision.handTracking", qos: .userInitiated)
    private let request = VNDetectHumanHandPoseRequest()
    private let receive: @MainActor @Sendable (TrackingSample) -> Void
    private let deliverySlot = DispatchSemaphore(value: 1)
    private var engine = GestureEngine()
    private var generation: UUID?
    private var sequence: UInt64 = 0
    private var lastProcessed = -Double.infinity
    private var lastPublished = -Double.infinity

    init(receive: @escaping @MainActor @Sendable (TrackingSample) -> Void) {
        self.receive = receive
        super.init()
        // Two visible hands are treated as ambiguous; never switch silently between them.
        request.maximumHandCount = 2
    }

    func configure(generation: UUID?, preferences: GesturePreferences = GesturePreferences()) {
        processingQueue.async { [self] in
            self.generation = generation
            engine = GestureEngine(closeThreshold: preferences.closeThreshold,
                                   openThreshold: preferences.openThreshold)
            lastProcessed = -.infinity
            lastPublished = -.infinity
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        dispatchPrecondition(condition: .onQueue(processingQueue))
        guard let generation else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastProcessed >= 1.0 / 30 else { return }
        lastProcessed = now
        let timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        let hostTime = CMTimeGetSeconds(CMClockGetTime(CMClockGetHostTimeClock()))
        let age = hostTime - timestamp
        guard age.isFinite, age >= -0.05, age < 0.20 else { engine.reset(); return }
        var frame: HandFrame?
        do {
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
            try handler.perform([request])
            if let hands = request.results, hands.count == 1, let hand = hands.first {
                frame = try makeFrame(from: hand, sampleBuffer: sampleBuffer)
            }
        } catch {
            // A failed observation is tracking loss, never a completed gesture.
            frame = nil
        }
        let gesture = engine.update(frame: frame, timestamp: timestamp)
        let finished = ProcessInfo.processInfo.systemUptime
        guard gesture != nil || finished - lastPublished >= 1.0 / 15 else { return }
        // Bounded delivery: never accumulate stale MainActor work behind a busy UI.
        guard deliverySlot.wait(timeout: .now()) == .success else { return }
        lastPublished = finished
        sequence &+= 1
        let sample = TrackingSample(generation: generation, sequence: sequence, frame: frame,
                                    pinchState: engine.state, gesture: gesture,
                                    processingMilliseconds: (finished - now) * 1_000,
                                    capturedAt: now - max(0, age))
        Task { @MainActor [receive, deliverySlot] in
            defer { deliverySlot.signal() }
            receive(sample)
        }
    }

    private func makeFrame(
        from hand: VNHumanHandPoseObservation,
        sampleBuffer: CMSampleBuffer
    ) throws -> HandFrame? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let timestamp = CMTimeGetSeconds(
            CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )

        guard timestamp.isFinite else {
            return nil
        }

        let points = try hand.recognizedPoints(.all)

        let jointMapping: [
            (HandJoint, VNHumanHandPoseObservation.JointName)
        ] = [
            (.wrist, .wrist),

            (.thumbCMC, .thumbCMC),
            (.thumbMP, .thumbMP),
            (.thumbIP, .thumbIP),
            (.thumbTip, .thumbTip),

            (.indexMCP, .indexMCP),
            (.indexPIP, .indexPIP),
            (.indexDIP, .indexDIP),
            (.indexTip, .indexTip),

            (.middleMCP, .middleMCP),
            (.middlePIP, .middlePIP),
            (.middleDIP, .middleDIP),
            (.middleTip, .middleTip),

            (.ringMCP, .ringMCP),
            (.ringPIP, .ringPIP),
            (.ringDIP, .ringDIP),
            (.ringTip, .ringTip),

            (.littleMCP, .littleMCP),
            (.littlePIP, .littlePIP),
            (.littleDIP, .littleDIP),
            (.littleTip, .littleTip)
        ]

        var landmarks: [HandJoint: HandLandmark] = [:]
        landmarks.reserveCapacity(21)

        for (joint, visionJoint) in jointMapping {
            guard let point = points[visionJoint],
                  point.location.x.isFinite,
                  point.location.y.isFinite else {
                continue
            }

            landmarks[joint] = HandLandmark(
                x: Double(point.location.x),
                y: Double(point.location.y),
                confidence: point.confidence
            )
        }

        return HandFrame(
            timeStamp: timestamp,
            imageWidth: CVPixelBufferGetWidth(imageBuffer),
            imageHeight: CVPixelBufferGetHeight(imageBuffer),
            landmarks: landmarks
        )
    }

}
