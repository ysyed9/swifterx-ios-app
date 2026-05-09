import Foundation

// MARK: - APIClient Protocol
// Default app build uses `FirestoreAPIClient`. `PreviewAPIClient` returns empty data for SwiftUI previews.
// All methods are async/throws — callers handle errors and loading states.

protocol APIClient {
    func fetchProviders() async throws -> [ServiceProvider]
    func fetchCategories() async throws -> [(name: String, icon: String)]
    /// `providers/{providerID}/services/*` — provider-owned catalog shown to customers.
    func fetchServices(for providerID: String) async throws -> [ServiceItem]
    func saveProviderService(providerID: String, item: ServiceItem) async throws
    func deleteProviderService(providerID: String, serviceId: String) async throws
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

// MARK: - PreviewAPIClient

/// No network: empty responses for SwiftUI previews (`#Preview`). Lives in this file so every target file sees the type.
final class PreviewAPIClient: APIClient {
    static let shared = PreviewAPIClient()
    private init() {}

    func fetchProviders() async throws -> [ServiceProvider] { [] }
    func fetchCategories() async throws -> [(name: String, icon: String)] { [] }
    func fetchServices(for providerID: String) async throws -> [ServiceItem] { _ = providerID; return [] }
    func saveProviderService(providerID: String, item: ServiceItem) async throws { _ = (providerID, item) }
    func deleteProviderService(providerID: String, serviceId: String) async throws { _ = (providerID, serviceId) }
    func fetchOrders(for uid: String) async throws -> [ServiceOrder] { _ = uid; return [] }
    func placeOrder(_ order: ServiceOrder, uid: String) async throws { _ = (order, uid) }
    func cancelOrder(id: String, uid: String) async throws { _ = (id, uid) }
    func fetchReviews(for providerID: String) async throws -> [Review] { _ = providerID; return [] }
    func submitReview(_ review: Review, uid: String) async throws { _ = (review, uid) }
    func hasReview(orderID: String, providerID: String, uid: String) async throws -> Bool {
        _ = (orderID, providerID, uid)
        return false
    }
    func fetchAvailability(for providerID: String, on date: Date) async throws -> [String] {
        _ = (providerID, date)
        return ["9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"]
    }
}
