import Foundation

// MARK: - MockAPIClient
// Serves hardcoded data from MockData. Used for development / testing.
// Switch to FirestoreAPIClient in SwifterXApp once the database is seeded.

final class MockAPIClient: APIClient {
    static let shared = MockAPIClient()
    private init() {}

    private let defaultSlots = ["9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM",
                                 "2:00 PM", "3:00 PM", "4:00 PM"]

    func fetchProviders() async throws -> [ServiceProvider] {
        try await Task.sleep(nanoseconds: 300_000_000)
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
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func cancelOrder(id: String, uid: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func fetchReviews(for providerID: String) async throws -> [Review] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return MockData.mockReviews.filter { $0.providerID == providerID }
    }

    func submitReview(_ review: Review, uid: String) async throws {
        try await Task.sleep(nanoseconds: 400_000_000)
    }

    func hasReview(orderID: String, providerID: String, uid: String) async throws -> Bool {
        return false
    }

    func fetchAvailability(for providerID: String, on date: Date) async throws -> [String] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return defaultSlots
    }
}
