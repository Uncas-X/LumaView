import Foundation

/// One consumer's request. Cancelling never affects another request for the
/// same URL, and a cancelled result cannot repopulate either thumbnail cache.
final class ThumbnailRequest: @unchecked Sendable {
    private enum State { case active, cancelled, completed }
    private let lock = NSRecursiveLock()
    private var state = State.active
    private var cancellationHandlers: [UUID: () -> Void] = [:]

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return state == .cancelled
    }

    func cancel() {
        lock.lock()
        guard state == .active else { lock.unlock(); return }
        state = .cancelled
        let handlers = Array(cancellationHandlers.values)
        cancellationHandlers.removeAll()
        lock.unlock()
        handlers.forEach { $0() }
    }

    @discardableResult
    func onCancel(_ handler: @escaping () -> Void) -> UUID {
        let identifier = UUID()
        lock.lock()
        let cancelled = state == .cancelled
        if state == .active { cancellationHandlers[identifier] = handler }
        lock.unlock()
        if cancelled { handler() }
        return identifier
    }

    func removeCancellationHandler(_ identifier: UUID) {
        lock.lock(); cancellationHandlers.removeValue(forKey: identifier); lock.unlock()
    }

    /// The cache write and delivery form one transaction with cancellation.
    /// A recursive lock permits a completion to cancel its own finished ticket.
    func finish(_ delivery: () -> Void) {
        lock.lock(); defer { lock.unlock() }
        guard state == .active else { return }
        state = .completed
        cancellationHandlers.removeAll()
        delivery()
    }
}
