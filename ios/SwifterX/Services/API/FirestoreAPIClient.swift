import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - FirestoreAPIClient
// Production implementation of APIClient backed by Cloud Firestore.
//
// Firestore collections:
//   /categories/{id}                     — service categories
//   /providers/{id}                      — service providers
//   /providers/{id}/services/{id}        — services offered by a provider
//   /providers/{id}/reviews/{id}         — customer reviews
//   /providers/{id}/availability/{date}  — available time slots per date (YYYY-MM-DD)
//   /orders/{id}                         — customer orders

final class FirestoreAPIClient: APIClient {
    static let shared = FirestoreAPIClient()
    private let db = Firestore.firestore()

    private let defaultTimeSlots = [
        "9:00 AM", "10:00 AM", "11:00 AM",
        "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"
    ]

    private init() {}

    // MARK: - Providers

    func fetchProviders() async throws -> [ServiceProvider] {
        let snapshot = try await db.collection("providers").getDocuments()
        let providers: [ServiceProvider] = snapshot.documents.compactMap { doc in
            // Prefer the `id` field stored in the document; fall back to the document ID so
            // providers whose Cloud Function hasn't synced yet are still decoded correctly.
            if var provider = try? doc.data(as: ServiceProvider.self) {
                if provider.id.isEmpty { provider.id = doc.documentID }
                return provider
            }
            // Manual fallback: decode required fields tolerantly so a single bad doc
            // doesn't silently drop the whole provider from the customer browse list.
            let data = doc.data()
            guard let name = data["name"] as? String, !name.isEmpty else { return nil }
            let category = data["category"] as? String ?? "Services"
            let description = data["description"] as? String ?? ""
            let rating = (data["rating"] as? Double) ?? (data["rating"] as? NSNumber).map(\.doubleValue) ?? 0
            let distanceMi = (data["distanceMi"] as? Double) ?? (data["distanceMi"] as? NSNumber).map(\.doubleValue) ?? 0
            return ServiceProvider(
                id: (data["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? doc.documentID,
                name: name,
                category: category,
                description: description,
                rating: rating,
                distanceMi: distanceMi,
                imageName: data["imageName"] as? String ?? "",
                imageURL: data["imageURL"] as? String ?? "",
                reviewCount: (data["reviewCount"] as? Int) ?? (data["reviewCount"] as? NSNumber).map(\.intValue) ?? 0,
                providerLat: (data["providerLat"] as? Double) ?? (data["providerLat"] as? NSNumber).map(\.doubleValue) ?? 0,
                providerLng: (data["providerLng"] as? Double) ?? (data["providerLng"] as? NSNumber).map(\.doubleValue) ?? 0,
                listingApproved: data["listingApproved"] as? Bool
            )
        }
        return providers.filter(\.isVisibleToCustomers)
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [(name: String, icon: String)] {
        let snapshot = try await db.collection("categories")
            .order(by: "order")
            .getDocuments()
        let categories = snapshot.documents.compactMap { doc -> (name: String, icon: String)? in
            let data = doc.data()
            guard let name = data["title"] as? String,
                  let icon = data["icon"] as? String else { return nil }
            return (name: name, icon: icon)
        }
        return categories
    }

    // MARK: - Provider services (customer browse + provider CRUD)

    func fetchServices(for providerID: String) async throws -> [ServiceItem] {
        let snapshot = try await db.collection("providers").document(providerID)
            .collection("services").getDocuments()
        return ServiceItemFirestore.sortedItems(from: snapshot.documents)
    }

    func saveProviderService(providerID: String, item: ServiceItem) async throws {
        // Rules: `providers/{providerID}` must match signed-in uid; payload must be exactly id, name, price.
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.permissionDenied.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Sign in to save services."])
        }
        guard user.uid == providerID else {
            throw NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.permissionDenied.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Account mismatch — sign out and back in, then try again."])
        }
        // Avoid forcing refresh on every save — it often fails offline and surfaces as a non-Firestore NSError.
        _ = try await user.getIDToken()
        let ref = db.collection("providers").document(providerID).collection("services").document(item.id)
        let payload: [String: Any] = [
            "id": item.id,
            "name": item.name,
            "price": NSNumber(value: item.price)
        ]
        try await ref.setData(payload, merge: false)
    }

    func deleteProviderService(providerID: String, serviceId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.permissionDenied.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Sign in to delete services."])
        }
        guard user.uid == providerID else {
            throw NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.permissionDenied.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Account mismatch — sign out and back in."])
        }
        _ = try await user.getIDToken()
        try await db.collection("providers").document(providerID)
            .collection("services").document(serviceId).delete()
    }

    // MARK: - Orders

    func fetchOrders(for uid: String) async throws -> [ServiceOrder] {
        let snapshot = try await db.collection("orders")
            .whereField("customerUID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ServiceOrder.self)
        }
    }

    func placeOrder(_ order: ServiceOrder, uid: String) async throws {
        try await db.collection("orders").document(order.id).setData(from: order)
    }

    func cancelOrder(id: String, uid: String) async throws {
        try await db.collection("orders").document(id).updateData([
            "status": ServiceOrder.OrderStatus.cancelled.rawValue
        ])
    }

    // MARK: - Reviews

    func fetchReviews(for providerID: String) async throws -> [Review] {
        let snapshot = try await db.collection("providers").document(providerID)
            .collection("reviews")
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Review.self)
        }
    }

    /// Returns true if the customer already submitted a review for this specific order.
    func hasReview(orderID: String, providerID: String, uid: String) async throws -> Bool {
        let snapshot = try await db.collection("providers").document(providerID)
            .collection("reviews")
            .whereField("customerUID", isEqualTo: uid)
            .whereField("orderID", isEqualTo: orderID)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    func submitReview(_ review: Review, uid: String) async throws {
        try await db.collection("providers").document(review.providerID)
            .collection("reviews").document(review.id).setData(from: review)

        // Update the provider's aggregate rating and reviewCount
        let providerRef = db.collection("providers").document(review.providerID)
        try await db.runTransaction { transaction, errorPointer in
            let providerDoc: DocumentSnapshot
            do {
                providerDoc = try transaction.getDocument(providerRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            let currentCount = providerDoc.data()?["reviewCount"] as? Int ?? 0
            let currentRating = providerDoc.data()?["rating"] as? Double ?? 0.0
            let newCount = currentCount + 1
            let newRating = ((currentRating * Double(currentCount)) + Double(review.rating)) / Double(newCount)
            transaction.updateData([
                "reviewCount": newCount,
                "rating": (newRating * 10).rounded() / 10
            ], forDocument: providerRef)
            return nil
        }
    }

    // MARK: - Availability

    func fetchAvailability(for providerID: String, on date: Date) async throws -> [String] {
        let dateStr = datePath(date)
        let doc = try await db.collection("providers").document(providerID)
            .collection("availability").document(dateStr).getDocument()
        if let slots = doc.data()?["slots"] as? [String], !slots.isEmpty {
            return slots
        }
        return defaultTimeSlots
    }

    // MARK: - Helpers

    private func datePath(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }
}
