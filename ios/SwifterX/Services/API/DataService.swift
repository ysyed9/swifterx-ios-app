import Foundation

// MARK: - DataService
// Observable wrapper around APIClient. Injected as @EnvironmentObject so views
// can load providers, categories, reviews, and availability without importing
// Firestore directly. Swap the underlying client via the constructor for testing.

@MainActor
final class DataService: ObservableObject {

    private let client: any APIClient

    @Published private(set) var providers: [ServiceProvider] = []
    @Published private(set) var categories: [(name: String, icon: String)] = []
    @Published private(set) var isLoadingProviders = false
    /// Shown on Home when a network/Firestore refresh fails (tap banner to dismiss).
    @Published private(set) var lastFetchError: String?

    init(client: any APIClient = FirestoreAPIClient.shared) {
        self.client = client
    }

    func clearLastFetchError() {
        lastFetchError = nil
    }

    // MARK: - Providers & Categories

    func loadProviders() async {
        isLoadingProviders = true
        let trace = PerformanceTracer(name: "load_providers")
        defer {
            trace?.stop()
            isLoadingProviders = false
        }
        do {
            providers = try await client.fetchProviders()
        } catch {
            lastFetchError = "Couldn’t refresh providers. Check your connection and try again."
        }
    }

    func loadCategories() async {
        let trace = PerformanceTracer(name: "load_categories")
        defer { trace?.stop() }
        do {
            categories = try await client.fetchCategories()
        } catch {
            lastFetchError = "Couldn’t refresh categories. Check your connection and try again."
        }
    }

    // MARK: - Provider services

    func fetchServices(for providerID: String) async throws -> [ServiceItem] {
        try await client.fetchServices(for: providerID)
    }

    func saveProviderService(providerID: String, item: ServiceItem) async throws {
        try await client.saveProviderService(providerID: providerID, item: item)
    }

    func deleteProviderService(providerID: String, serviceId: String) async throws {
        try await client.deleteProviderService(providerID: providerID, serviceId: serviceId)
    }

    func filteredProviders(category: String?, search: String) -> [ServiceProvider] {
        var base = providers
        if let cat = category, !cat.isEmpty {
            base = base.filter { $0.category == cat }
        }
        if !search.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                $0.category.localizedCaseInsensitiveContains(search) ||
                $0.description.localizedCaseInsensitiveContains(search)
            }
        }
        return base
    }

    // MARK: - Reviews

    func fetchReviews(for providerID: String) async -> [Review] {
        let trace = PerformanceTracer(name: "fetch_reviews")
        trace?.setAttribute("provider_id", value: providerID)
        let result = (try? await client.fetchReviews(for: providerID)) ?? []
        trace?.stop()
        return result
    }

    func submitReview(_ review: Review, uid: String) async throws {
        try await client.submitReview(review, uid: uid)
    }

    func hasReview(orderID: String, providerID: String, uid: String) async -> Bool {
        return (try? await client.hasReview(orderID: orderID, providerID: providerID, uid: uid)) ?? false
    }

    // MARK: - Availability

    func fetchAvailability(for providerID: String, on date: Date) async -> [String] {
        return (try? await client.fetchAvailability(for: providerID, on: date)) ?? defaultSlots
    }

    private let defaultSlots = [
        "9:00 AM", "10:00 AM", "11:00 AM",
        "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"
    ]
}
