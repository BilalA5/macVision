import SwiftUI
import AppKit
import AVFoundation
import QuartzCore

struct CameraPreview: NSViewRepresentable {
    let camera: CameraManager
    let handFrame: HandFrame?

    func makeNSView(context: Context) -> CameraPreviewNSView {
        CameraPreviewNSView(
            previewLayer: camera.makePreviewLayer()
        )
    }

    func updateNSView(
        _ nsView: CameraPreviewNSView,
        context: Context
    ) {
        nsView.updateHandFrame(handFrame)
    }
}

final class CameraPreviewNSView: NSView {
    private let previewLayer: AVCaptureVideoPreviewLayer
    private let jointsLayer = CAShapeLayer()

    private var handFrame: HandFrame?

    override var isFlipped: Bool {
        true
    }

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer

        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(previewLayer)

        jointsLayer.fillColor = NSColor.systemGreen.cgColor
        previewLayer.addSublayer(jointsLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("This view is created in code.")
    }

    func updateHandFrame(_ frame: HandFrame?) {
        handFrame = frame
        redrawJoints()
    }

    override func layout() {
        super.layout()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        previewLayer.frame = bounds
        jointsLayer.frame = previewLayer.bounds

        CATransaction.commit()

        redrawJoints()
    }

    private func redrawJoints() {
        let path = CGMutablePath()

        if let handFrame {
            for joint in HandJoint.allCases {
                guard let landmark =
                    handFrame.reliableLandmark(joint) else {
                    continue
                }

                // Vision uses a bottom-left origin.
                // Capture-device coordinates use a top-left origin.
                let capturePoint = CGPoint(
                    x: CGFloat(landmark.x),
                    y: CGFloat(1 - landmark.y)
                )

                let displayPoint = previewLayer.layerPointConverted(
                    fromCaptureDevicePoint: capturePoint
                )

                let radius: CGFloat = 4

                path.addEllipse(
                    in: CGRect(
                        x: displayPoint.x - radius,
                        y: displayPoint.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
            }
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        jointsLayer.path = path
        CATransaction.commit()
    }
}