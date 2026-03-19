import Foundation

// MARK: - APIClient Protocol
// Swap MockAPIClient for FirestoreAPIClient (or a REST client) when the backend is ready.

protocol APIClient {
    func fetchProviders() async throws -> [ServiceProvider]
    func fetchCategories() async throws -> [(name: String, icon: String)]
    func fetchOrders(for uid: String) async throws -> [ServiceOrder]
    func placeOrder(_ order: ServiceOrder, uid: String) async throws
    func cancelOrder(id: String, uid: String) async throws
}
