import AVFoundation
import Vision
import OSLog

final class HandTracker:
    NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    @unchecked Sendable
{
    let processingQueue = DispatchQueue(
        label: "macVision.handTracking",
        qos: .userInitiated
    )

    private let request = VNDetectHumanHandPoseRequest()
    private let state: HandTrackingState
    // Access these only on processingQueue.
    private var pinchRecognizer = PinchRecognizer()
    private var isTrackingEnabled = false

    private let logger = Logger(
        subsystem: "com.macvision.app",
        category: "HandTracking"
    )

    init(state: HandTrackingState) {
        self.state = state
        super.init()

        request.maximumHandCount = 1
    }

    func setTrackingEnabled(_ enabled: Bool) {
        processingQueue.async { [self] in
            isTrackingEnabled = enabled
            _ = pinchRecognizer.reset()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        dispatchPrecondition(condition: .onQueue(processingQueue))
        guard isTrackingEnabled else { return }

        let startTime = ProcessInfo.processInfo.systemUptime
        var frame: HandFrame?

        do {
            let handler = VNImageRequestHandler(
                cmSampleBuffer: sampleBuffer,
                orientation: .up,
                options: [:]
            )

            try handler.perform([request])

            if let hand = request.results?.first {
                frame = try makeFrame(
                    from: hand,
                    sampleBuffer: sampleBuffer
                )
            }
        } catch {
            logger.error(
                "Hand detection failed: \(error.localizedDescription, privacy: .public)"
            )
        }

        let measurement = frame.flatMap { PinchMeasurement(frame: $0) }
        let event = pinchRecognizer.update(
            measurement: measurement,
            timestamp: CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        )

        if let event {
            logger.debug("Pinch event: \(String(describing: event), privacy: .public)")
        }

        let elapsedMilliseconds =
            (ProcessInfo.processInfo.systemUptime - startTime) * 1_000

        publish(
            frame: frame,
            processingMilliseconds: elapsedMilliseconds,
            pinchState: pinchRecognizer.state
        )
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

    private func publish(
        frame: HandFrame?,
        processingMilliseconds: Double,
        pinchState: PinchRecognizer.State
    ) {
        let confidentJointCount = frame?.landmarks.values.filter {
            $0.confidence >= 0.5
        }.count ?? 0

        Task { @MainActor [state] in
            state.update(
                handDetected: frame != nil,
                confidentJointCount: confidentJointCount,
                processingMilliseconds: processingMilliseconds,
                frame: frame,
                pinchState: pinchState
            )
        }
    }
}
