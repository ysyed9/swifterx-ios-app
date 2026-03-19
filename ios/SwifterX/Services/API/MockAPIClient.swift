import Foundation

// MARK: - MockAPIClient
// Serves hardcoded data from MockData so the app works while the real backend is built.
// Replace with FirestoreAPIClient once Firebase is connected.

final class MockAPIClient: APIClient {
    static let shared = MockAPIClient()
    private init() {}

    func fetchProviders() async throws -> [ServiceProvider] {
        try await Task.sleep(nanoseconds: 300_000_000) // simulate 0.3s latency
        return MockData.providers
    }

    func fetchCategories() async throws -> [(name: String, icon: String)] {
        return MockData.categories
    }

    func fetchOrders(for uid: String) async throws -> [ServiceOrder] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.orders
    }

    func placeOrder(_ order: ServiceOrder, uid: String) async throws {
        // No-op in mock — in production this writes to Firestore
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func cancelOrder(id: String, uid: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
