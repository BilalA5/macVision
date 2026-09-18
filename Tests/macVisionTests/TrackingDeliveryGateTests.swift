import Foundation

func staleSessionAndOutOfOrderResultsAreRejected() {
    var gate = TrackingDeliveryGate()
    let current = UUID()
    let old = UUID()
    expect(!gate.accept(sequence: 99, generation: old, expectedGeneration: current, capturedAt: 1, now: 1.1))
    expect(gate.accept(sequence: 1, generation: current, expectedGeneration: current, capturedAt: 1, now: 1.1))
    expect(!gate.accept(sequence: 1, generation: current, expectedGeneration: current, capturedAt: 1, now: 1.1))
    expect(!gate.accept(sequence: 2, generation: current, expectedGeneration: current, capturedAt: 1, now: 2))
    expect(!gate.accept(sequence: 3, generation: current, expectedGeneration: current, capturedAt: 3, now: 2))
    expect(!gate.accept(sequence: 4, generation: current, expectedGeneration: current, capturedAt: .nan, now: 2))
    expect(gate.accept(sequence: 5, generation: current, expectedGeneration: current, capturedAt: 2, now: 2.1))
}
