import Foundation

/// A lightweight thread-safe boolean to bridge background camera
/// queues and the @MainActor without causing UI lag.
public final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool = false
    
    public init() {}

    public var value: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}
