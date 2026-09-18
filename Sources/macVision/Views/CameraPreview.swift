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
    private let connectionsLayer = CAShapeLayer()
    private let fingertipsLayer = CAShapeLayer()
    private let fingers: [[HandJoint]] = [
        [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip],
        [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
        [.indexMCP, .middleMCP, .middlePIP, .middleDIP, .middleTip],
        [.middleMCP, .ringMCP, .ringPIP, .ringDIP, .ringTip],
        [.ringMCP, .littleMCP, .littlePIP, .littleDIP, .littleTip],
        [.wrist, .littleMCP]
    ]

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

        connectionsLayer.fillColor = nil
        connectionsLayer.strokeColor = NSColor.systemGreen.withAlphaComponent(0.7).cgColor
        connectionsLayer.lineWidth = 1.25
        connectionsLayer.lineCap = .round
        previewLayer.addSublayer(connectionsLayer)
        fingertipsLayer.fillColor = NSColor.white.cgColor
        fingertipsLayer.strokeColor = NSColor.systemGreen.cgColor
        fingertipsLayer.lineWidth = 1.5
        jointsLayer.fillColor = NSColor.systemGreen.cgColor
        previewLayer.addSublayer(jointsLayer)
        previewLayer.addSublayer(fingertipsLayer)
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
        connectionsLayer.frame = previewLayer.bounds
        fingertipsLayer.frame = previewLayer.bounds

        CATransaction.commit()

        redrawJoints()
    }

    private func redrawJoints() {
        let dots = CGMutablePath()
        let bones = CGMutablePath()
        let tips = CGMutablePath()
        var positions: [HandJoint: CGPoint] = [:]
        if let handFrame {
            for joint in HandJoint.allCases {
                guard let landmark = handFrame.reliableLandmark(joint) else { continue }
                let capturePoint = CGPoint(x: CGFloat(landmark.x), y: CGFloat(1 - landmark.y))
                let point = previewLayer.layerPointConverted(fromCaptureDevicePoint: capturePoint)
                positions[joint] = point
                let isTip = joint == .thumbTip || joint == .indexTip
                let radius: CGFloat = isTip ? 3.5 : 2.5
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                if isTip { tips.addEllipse(in: rect) } else { dots.addEllipse(in: rect) }
            }
            for finger in fingers {
                for (first, second) in zip(finger, finger.dropFirst()) {
                    guard let start = positions[first], let end = positions[second] else { continue }
                    bones.move(to: start)
                    bones.addLine(to: end)
                }
            }
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        jointsLayer.path = dots
        connectionsLayer.path = bones
        fingertipsLayer.path = tips
        CATransaction.commit()
    }
}
