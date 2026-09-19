enum PinchFinger: String, Codable, CaseIterable, Sendable, Identifiable {
    case index, middle, ring, little
    var id: String { rawValue }
    var title: String { self == .little ? "Pinky" : rawValue.capitalized }
    var tip: HandJoint {
        switch self { case .index: .indexTip; case .middle: .middleTip; case .ring: .ringTip; case .little: .littleTip }
    }
}

enum HandJoint: String, CaseIterable, Sendable {
    case wrist

    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip

    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip

    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip

    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip

    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip
}

struct HandLandmark : Sendable {
    let x : Double
    let y : Double

    let confidence : Float
}

struct HandFrame : Sendable {
    let timeStamp : Double
    let imageWidth : Int
    let imageHeight : Int

    let landmarks : [HandJoint : HandLandmark]

    func reliableLandmark(
        _ joint : HandJoint,
        minimumConfidence : Float = 0.5
    ) -> HandLandmark? {
        guard let landmark = landmarks[joint], 
            landmark.confidence >= minimumConfidence else {
                return nil
            }
            return landmark
    }
}