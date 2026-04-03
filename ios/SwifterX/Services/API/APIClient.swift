import Foundation

// MARK: - APIClient Protocol
// Swap MockAPIClient for FirestoreAPIClient when the backend is ready.
// All methods are async/throws — callers handle errors and loading states.

protocol APIClient {
    func fetchProviders() async throws -> [ServiceProvider]
    func fetchCategories() async throws -> [(name: String, icon: String)]
    func fetchOrders(for uid: String) async throws -> [ServiceOrder]
    func placeOrder(_ order: ServiceOrder, uid: String) async throws
    func cancelOrder(id: String, uid: String) async throws

    // Reviews
    func fetchReviews(for providerID: String) async throws -> [Review]
    func submitReview(_ review: Review, uid: String) async throws
    func hasReview(orderID: String, providerID: String, uid: String) async throws -> Bool

    // Availability — returns time slot strings ("9:00 AM") for a given date
    func fetchAvailability(for providerID: String, on date: Date) async throws -> [String]
}
