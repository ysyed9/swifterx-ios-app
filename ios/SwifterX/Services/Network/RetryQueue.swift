import Foundation

// Lightweight async work item that can be enqueued and replayed.
typealias RetryWork = () async -> Void

/// Stores failed async operations (e.g. order placement) and retries them
/// automatically once network connectivity is restored.
@MainActor
final class RetryQueue {
    static let shared = RetryQueue()
    private var queue: [String: RetryWork] = [:]   // key = unique label

    private init() {}

    /// Add or replace a pending retry work item.
    func enqueue(key: String, work: @escaping RetryWork) {
        queue[key] = work
    }

    func remove(key: String) { queue.removeValue(forKey: key) }

    /// Called by NetworkMonitor when connection is restored.
    func flush() {
        guard !queue.isEmpty else { return }
        let pending = queue
        queue.removeAll()
        for (key, work) in pending {
            Task {
                await work()
            }
        }
    }
}
