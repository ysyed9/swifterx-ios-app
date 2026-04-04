import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - NotificationFeedStore
// Real-time listener on users/{uid}/notifications for the in-app Notification Center.

@MainActor
final class NotificationFeedStore: ObservableObject {
    static let shared = NotificationFeedStore()

    @Published private(set) var items: [InAppNotificationItem] = []
    @Published private(set) var unreadCount: Int = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var currentUID: String?

    private init() {}

    // MARK: - Listen

    func startListening(uid: String) {
        guard uid != currentUID || listener == nil else { return }
        stopListening()
        currentUID = uid

        listener = db.collection("users").document(uid)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        #if DEBUG
                        print("[NotificationFeed] \(error.localizedDescription)")
                        #endif
                        return
                    }
                    let docs = snapshot?.documents ?? []
                    self.items = docs.compactMap { doc in
                        InAppNotificationItem(id: doc.documentID, data: doc.data())
                    }
                    self.unreadCount = self.items.filter { !$0.read }.count
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        currentUID = nil
        items = []
        unreadCount = 0
    }

    // MARK: - Read state

    func markRead(id: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("notifications").document(id)
                .updateData(["read": true])
        } catch {
            #if DEBUG
            print("[NotificationFeed] markRead failed: \(error)")
            #endif
        }
    }

    func markAllRead() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let unread = items.filter { !$0.read }
        for item in unread {
            try? await db.collection("users").document(uid)
                .collection("notifications").document(item.id)
                .updateData(["read": true])
        }
    }

    // MARK: - Delete

    func delete(id: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("notifications").document(id)
                .delete()
        } catch {
            #if DEBUG
            print("[NotificationFeed] delete failed: \(error)")
            #endif
        }
    }

    // MARK: - Promo (client-authored feed entry)

    /// Called when the customer successfully applies a promo at checkout.
    func logPromoApplied(code: String, savingsDescription: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cleanCode = InputSanitizer.promoCode(code)
        guard cleanCode.count >= 2 else { return }

        let title = "Promo applied"
        let body = InputSanitizer.clean("\(cleanCode): \(savingsDescription)", limit: FieldLimit.reviewComment)

        do {
            try await db.collection("users").document(uid)
                .collection("notifications")
                .addDocument(data: [
                    "title": title,
                    "body": body,
                    "category": "promo",
                    "promoCode": cleanCode,
                    "read": false,
                    "createdAt": FieldValue.serverTimestamp(),
                ])
        } catch {
            #if DEBUG
            print("[NotificationFeed] logPromo failed: \(error)")
            #endif
        }
    }
}
