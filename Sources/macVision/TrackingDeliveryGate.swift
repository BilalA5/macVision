import Foundation

/// Main-actor delivery must belong to this activation and arrive in order while fresh.
struct TrackingDeliveryGate {
    private var lastSequence: UInt64 = 0

    mutating func accept(sequence: UInt64, generation: UUID, expectedGeneration: UUID,
                         capturedAt: Double, now: Double) -> Bool {
        let age = now - capturedAt
        guard generation == expectedGeneration, sequence > lastSequence,
              age.isFinite, age >= 0, age < 0.25 else { return false }
        lastSequence = sequence
        return true
    }
}
