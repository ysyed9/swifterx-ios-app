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

    init(client: any APIClient = FirestoreAPIClient.shared) {
        self.client = client
    }

    // MARK: - Providers & Categories

    func loadProviders() async {
        isLoadingProviders = true
        let trace = PerformanceTracer(name: "load_providers")
        providers = (try? await client.fetchProviders()) ?? MockData.providers
        trace?.stop()
        isLoadingProviders = false
    }

    func loadCategories() async {
        let trace = PerformanceTracer(name: "load_categories")
        categories = (try? await client.fetchCategories()) ?? MockData.categories
        trace?.stop()
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
