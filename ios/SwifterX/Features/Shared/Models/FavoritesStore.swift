import Foundation
import Combine

/// Persists the user's favourite provider IDs to UserDefaults.
/// Inject as @EnvironmentObject from SwifterXApp.
@MainActor
final class FavoritesStore: ObservableObject {

    static let shared = FavoritesStore()

    @Published private(set) var favoriteIDs: Set<String> = []

    private let key = "swifterx_favorite_provider_ids"

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        favoriteIDs = Set(saved)
    }

    func isFavorite(_ providerID: String) -> Bool {
        favoriteIDs.contains(providerID)
    }

    func toggle(_ provider: ServiceProvider) {
        if favoriteIDs.contains(provider.id) {
            favoriteIDs.remove(provider.id)
        } else {
            favoriteIDs.insert(provider.id)
        }
        persist()
    }

    func add(_ provider: ServiceProvider) {
        favoriteIDs.insert(provider.id)
        persist()
    }

    func remove(_ provider: ServiceProvider) {
        favoriteIDs.remove(provider.id)
        persist()
    }

    /// Returns all favorited providers from a given list (the full provider catalogue).
    func favorites(from providers: [ServiceProvider]) -> [ServiceProvider] {
        providers.filter { favoriteIDs.contains($0.id) }
    }

    private func persist() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: key)
    }
}
