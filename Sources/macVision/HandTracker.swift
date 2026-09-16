import AVFoundation
import Vision 
import OSLog

final class HandTracker:
    NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    @unchecked Sendable {
        let processingQueue = DispatchQueue(label : "macVision.handTracking", qos : .userInitiated)

        private let request = VNDetectHumanHandPoseRequest()
        private let state : HandTrackingState

        private(set) var processingMilliseconds: Double = 0

        private let logger = Logger(subsystem: "com.macvision.app", category : "HandTracking")

        init(state : HandTrackingState) {
            self.state = state
            super.init()

            request.maximumHandCount = 1
        }

        func captureOutput(
            _ output : AVCaptureOutput,
            didOutput sampleBuffer : CMSampleBuffer,
            from connection : AVCaptureConnection
        ){
            dispatchPrecondition(condition: .onQueue(processingQueue))

            let startTime = ProcessInfo.processInfo.systemUptime

            let handler = VNImageRequestHandler(
                cmSampleBuffer : sampleBuffer,
                orientation : .up,
                options : [:]
            )

            do {
                try handler.perform([request])

                let hand = request.results?.first
                var confidentJointCount = 0

                if let hand {
                    let points = try hand.recognizedPoints(.all)

                    confidentJointCount = points.values.filter {
                        $0.confidence >= 0.5
                    }.count
                }

                let elapsedMilliseconds = (ProcessInfo.processInfo.systemUptime - startTime) * 1_000_000

                publish(
                    handDetected : hand != nil,
                    confidentJointCount : confidentJointCount,
                    processingMilliseconds : elapsedMilliseconds
                )
            } catch {
                logger.error("Hand detection failed : \(error.localizedDescription, privacy : .public)")

                publish(
                    handDetected : false,
                    confidentJointCount : 0,
                    processingMilliseconds : (ProcessInfo.processInfo.systemUptime - startTime) * 1_000_000
                )
            }
        }

        private func publish(
            handDetected : Bool,
            confidentJointCount : Int,
            processingMilliseconds : Double
        ) {
            Task {@MainActor [state] in
                state.update(
                    handDetected : handDetected,
                    confidentJointCount : confidentJointCount,
                    processingMilliseconds : processingMilliseconds
                )
            }
        }
    }