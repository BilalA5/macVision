import Foundation

struct PinchMeasurement: Sendable {
    let ratio: Double

    init?(frame: HandFrame) {
        guard frame.imageWidth > 0,
              frame.imageHeight > 0,
              let thumb = frame.reliableLandmark(.thumbTip, minimumConfidence: 0.6),
              let index = frame.reliableLandmark(.indexTip, minimumConfidence: 0.6),
              let wrist = frame.reliableLandmark(.wrist, minimumConfidence: 0.6),
              let middleBase = frame.reliableLandmark(.middleMCP, minimumConfidence: 0.6) else {
            return nil
        }

        let width = Double(frame.imageWidth)
        let height = Double(frame.imageHeight)

        func distance(from first: HandLandmark, to second: HandLandmark) -> Double {
            let dx = (first.x - second.x) * width
            let dy = (first.y - second.y) * height
            return hypot(dx, dy)
        }

        let fingertipDistance = distance(from: thumb, to: index)
        let palmLength = distance(from: wrist, to: middleBase)

        guard fingertipDistance.isFinite,
              palmLength.isFinite,
              palmLength > 1 else {
            return nil
        }

        ratio = fingertipDistance / palmLength
    }
}
