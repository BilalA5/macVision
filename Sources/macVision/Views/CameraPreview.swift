import SwiftUI
import AppKit
import AVFoundation
import QuartzCore

struct CameraPreview : NSViewRepresentable {
    let camera : CameraManager

    func makeNSView(context : Context) -> CameraPreviewNSView {
        CameraPreviewNSView(previewLayer : camera.makePreviewLayer())
    }

    func updatedNSView(_ nsView : CameraPreviewNSView, context : Context) {
        //pass
    }
}

final class CameraPreviewNSView : NSView {
    private let previewLayer : AVCaptureVideoPreviewLayer

    init(previewLayer : AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer

        super.init(frame : .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("This view is created in code.")
    }

    override func layout() {
        super.layout()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.comit()
    }
}