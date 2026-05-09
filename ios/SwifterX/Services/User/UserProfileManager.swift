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

    // Update editable fields (merge write: creates the doc if missing; rules require `photoURL` etc. on every write)
    func updateProfile(uid: String,
                       name: String,
                       phone: String,
                       addressLine: String,
                       city: String,
                       state: String,
                       zip: String) async throws {
        let existingPhoto = (profile?.uid == uid) ? (profile?.photoURL ?? "") : ""
        let data: [String: Any] = [
            "name": InputSanitizer.name(name),
            "phone": InputSanitizer.phone(phone),
            "addressLine": InputSanitizer.address(addressLine),
            "city": InputSanitizer.clean(city, limit: 60),
            "state": InputSanitizer.clean(state, limit: 30),
            "zip": InputSanitizer.clean(zip, limit: FieldLimit.zipCode),
            "photoURL": InputSanitizer.photoURL(existingPhoto)
        ]
        try await db.collection("users").document(uid).setData(data, merge: true)

        if var p = profile, p.uid == uid {
            p.name = data["name"] as? String ?? p.name
            p.phone = data["phone"] as? String ?? p.phone
            p.addressLine = data["addressLine"] as? String ?? p.addressLine
            p.city = data["city"] as? String ?? p.city
            p.state = data["state"] as? String ?? p.state
            p.zip = data["zip"] as? String ?? p.zip
            p.photoURL = data["photoURL"] as? String ?? p.photoURL
            profile = p
        }
    }

    func updatePhotoURL(uid: String, url: String) async throws {
        let cleaned = InputSanitizer.photoURL(url)
        try await db.collection("users").document(uid).updateData(["photoURL": cleaned])
        if var p = profile, p.uid == uid {
            p.photoURL = cleaned
            profile = p
        }
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
