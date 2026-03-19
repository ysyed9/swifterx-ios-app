import SwiftUI
import FirebaseFirestore

// MARK: - UserProfileManager

@MainActor
final class UserProfileManager: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    // Start listening for real-time profile updates for the given UID
    func startListening(uid: String) {
        stopListening()
        isLoading = true
        listenerRegistration = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    self?.isLoading = false
                    guard let data = snapshot?.data() else { return }
                    self?.profile = UserProfile(from: data, uid: uid)
                }
            }
    }

    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        profile = nil
    }

    // Create a new profile document (called after first sign-up)
    func createProfile(_ profile: UserProfile) async throws {
        try await db.collection("users").document(profile.uid)
            .setData(profile.firestoreData)
        self.profile = profile
    }

    // Update editable fields
    func updateProfile(uid: String,
                       name: String,
                       phone: String,
                       addressLine: String,
                       city: String,
                       state: String,
                       zip: String) async throws {
        let data: [String: Any] = [
            "name": name,
            "phone": phone,
            "addressLine": addressLine,
            "city": city,
            "state": state,
            "zip": zip
        ]
        try await db.collection("users").document(uid).updateData(data)
    }

    // Fetch once (used for quick reads, e.g. on app resume)
    func fetchProfile(uid: String) async throws -> UserProfile? {
        let snap = try await db.collection("users").document(uid).getDocument()
        guard let data = snap.data() else { return nil }
        return UserProfile(from: data, uid: uid)
    }

    // Delete the user's Firestore document (called on account deletion)
    func deleteProfile(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }
}
