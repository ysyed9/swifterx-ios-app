import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class ProviderProfileManager: ObservableObject {
    static let shared = ProviderProfileManager()

    @Published var profile: ProviderProfile?
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Listen

    func startListening(uid: String) {
        listener?.remove()
        isLoading = true
        listener = db.collection("providerProfiles").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.isLoading = false
                self.profile = try? snap?.data(as: ProviderProfile.self)
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        profile = nil
    }

    // MARK: - Save (full profile)

    func save(_ profile: ProviderProfile) async throws {
        try db.collection("providerProfiles")
            .document(profile.id)
            .setData(from: profile, merge: true)
        self.profile = profile
    }

    // MARK: - Mark onboarding complete

    func completeOnboarding(uid: String) async throws {
        try await db.collection("providerProfiles").document(uid)
            .updateData(["isOnboarded": true])
        profile?.isOnboarded = true
    }

    // MARK: - Fetch once (for reads without listener)

    func fetch(uid: String) async throws -> ProviderProfile? {
        let snap = try await db.collection("providerProfiles").document(uid).getDocument()
        return try? snap.data(as: ProviderProfile.self)
    }

    // MARK: - Check onboarded status

    func isOnboarded(uid: String) async -> Bool {
        guard let p = try? await fetch(uid: uid) else { return false }
        return p.isOnboarded
    }
}
