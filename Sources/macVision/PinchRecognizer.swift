struct PinchRecognizer : Sendable {
    enum State : String, Sendable {
        case waitingForRelease
        case ready
        case pinched
    }

    enum Event : Sendable {
        case began
        case ended
        case cancelled
    }

    private(set) var state : State = .waitingForRelease

    private let closeThreshold = 0.25
    private let openThreshold = 0.40
    private let confirmationSeconds = 0.05
    private let maximumFrameGap = 0.20

    private var candidateStartedAt: Double?
    private var previousTimestamp: Double?

    mutating func update(measurement : PinchMeasurement?, timestamp : Double) -> Event? {
        guard timestamp.isFinite, let measurement, measurement.ratio.isFinite else {
            return reset()
        }

        if let previousTimestamp {
            let gap = timestamp - previousTimestamp

            guard gap > 0, gap <= maximumFrameGap else {
                return reset()
            }
        }

        previousTimestamp = timestamp

        let conditionMet : Bool

        switch state {
            case .waitingForRelease, .pinched:
                conditionMet = measurement.ratio >= openThreshold
            case.ready:
                conditionMet = measurement.ratio <= closeThreshold
        }

        guard conditionMet else {
            candidateStartedAt = nil
            return nil
        }

        guard let startedAt = candidateStartedAt else {
            candidateStartedAt = timestamp
            return nil
        }

        guard timestamp - startedAt >= confirmationSeconds else {
            return nil
        }

        candidateStartedAt = nil

        switch state {
            case.waitingForRelease:
                state = .ready
                return nil
            case.ready:
                state = .pinched
                return .began
            case.pinched:
                state = .ready
                return .ended
        }
    }

    mutating func reset() -> Event? {
        let wasPinched = state == .pinched

        state = .waitingForRelease
        candidateStartedAt = nil
        previousTimestamp = nil

        return wasPinched ? .cancelled : nil
    }
}
