import Foundation

/// One pending delivery, with completed events taking precedence over preview updates.
/// The consumer still checks timestamps and session identity before acting.
final class LatestFrameMailbox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: (value: Value, isEvent: Bool)?
    private var scheduled = false

    /// Returns true only when the producer needs to schedule a consumer.
    func offer(_ value: Value, isEvent: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if pending == nil || isEvent || pending?.isEvent == false {
            pending = (value, isEvent)
        }
        guard !scheduled else { return false }
        scheduled = true
        return true
    }

    func take() -> Value? {
        lock.lock()
        defer { lock.unlock() }
        let value = pending?.value
        pending = nil
        scheduled = false
        return value
    }
}
