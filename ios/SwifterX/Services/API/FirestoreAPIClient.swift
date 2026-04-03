import Foundation
import FirebaseFirestore

// MARK: - FirestoreAPIClient
// Production implementation of APIClient backed by Cloud Firestore.
// Falls back to MockData for providers/categories if Firestore collections are empty
// (useful during development before the database is seeded).
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
            try? doc.data(as: ServiceProvider.self)
        }
        return providers.isEmpty ? MockData.providers : providers
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
        return categories.isEmpty ? MockData.categories : categories
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
