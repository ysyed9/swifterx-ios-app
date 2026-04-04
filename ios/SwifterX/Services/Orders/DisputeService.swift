import Foundation
import FirebaseFirestore

// MARK: - DisputeService
// Handles Firestore reads and writes for the disputes collection.
// Only customers can create disputes; Cloud Functions / Admin SDK resolve them.

@MainActor
final class DisputeService: ObservableObject {
    static let shared = DisputeService()

    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Submit

    /// Creates a new dispute document in Firestore.
    /// Throws `DisputeError.alreadyFiled` if the customer already has a dispute for this order.
    func submit(
        order: ServiceOrder,
        customerUID: String,
        reason: Dispute.DisputeReason,
        description: String,
        refundRequested: Bool
    ) async throws -> Dispute {
        // Duplicate guard — one dispute per order per customer
        if let existing = try await fetchDispute(orderID: order.id, customerUID: customerUID) {
            throw DisputeError.alreadyFiled(existing)
        }

        let sanitizedDesc = InputSanitizer.clean(description, limit: FieldLimit.reviewComment)
        guard !sanitizedDesc.isEmpty else { throw DisputeError.emptyDescription }

        let dispute = Dispute(
            orderID:          order.id,
            customerUID:      customerUID,
            providerID:       order.providerID,
            providerName:     InputSanitizer.clean(order.providerName, limit: 120),
            orderAmount:      order.price,
            reason:           reason,
            description:      sanitizedDesc,
            refundRequested:  refundRequested
        )

        try await db.collection("disputes")
            .document(dispute.id)
            .setData(from: dispute)

        return dispute
    }

    // MARK: - Fetch

    /// Returns the customer's dispute for a specific order, or nil if none exists.
    func fetchDispute(orderID: String, customerUID: String) async throws -> Dispute? {
        let snap = try await db.collection("disputes")
            .whereField("orderID",     isEqualTo: orderID)
            .whereField("customerUID", isEqualTo: customerUID)
            .limit(to: 1)
            .getDocuments()

        return try snap.documents.first.map { try $0.data(as: Dispute.self) }
    }

    // MARK: - Error

    enum DisputeError: LocalizedError {
        case alreadyFiled(Dispute)
        case emptyDescription

        var errorDescription: String? {
            switch self {
            case .alreadyFiled:
                return "You already filed a dispute for this order. Please wait while we review it."
            case .emptyDescription:
                return "Please describe the issue before submitting."
            }
        }
    }
}
