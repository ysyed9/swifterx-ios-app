import Foundation

// MARK: - Dispute
// Stored in Firestore at disputes/{disputeID}
// Created by the customer; updated only by Cloud Functions / Admin SDK.

struct Dispute: Identifiable, Codable {
    var id: String
    var orderID: String
    var customerUID: String
    var providerID: String
    var providerName: String
    var orderAmount: Double
    var reason: DisputeReason
    var description: String
    var refundRequested: Bool
    var status: DisputeStatus
    var resolution: String?          // Admin note or auto-decision message
    var createdAt: Date
    var resolvedAt: Date?

    // MARK: Reason

    enum DisputeReason: String, Codable, CaseIterable, Identifiable {
        case noShow       = "no_show"
        case poorQuality  = "poor_quality"
        case wrongService = "wrong_service"
        case overcharged  = "overcharged"
        case safetyIssue  = "safety_issue"
        case other        = "other"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .noShow:       return "Provider no-show"
            case .poorQuality:  return "Poor quality of work"
            case .wrongService: return "Wrong service performed"
            case .overcharged:  return "Overcharged / price mismatch"
            case .safetyIssue:  return "Safety concern"
            case .other:        return "Other issue"
            }
        }

        var icon: String {
            switch self {
            case .noShow:       return "person.fill.xmark"
            case .poorQuality:  return "hand.thumbsdown"
            case .wrongService: return "exclamationmark.triangle"
            case .overcharged:  return "dollarsign.circle"
            case .safetyIssue:  return "shield.slash"
            case .other:        return "questionmark.circle"
            }
        }

        /// Hint text shown below the description field.
        var descriptionHint: String {
            switch self {
            case .noShow:
                return "Describe when you were home and how you tried to contact the provider."
            case .poorQuality:
                return "Describe what was done incorrectly or left unfinished."
            case .wrongService:
                return "Describe what service was actually performed vs. what was booked."
            case .overcharged:
                return "Describe the price discrepancy you experienced."
            case .safetyIssue:
                return "Describe the safety concern as clearly as possible."
            case .other:
                return "Tell us what happened so we can investigate."
            }
        }
    }

    // MARK: Status

    enum DisputeStatus: String, Codable {
        case submitted  = "submitted"    // Just filed, awaiting triage
        case reviewing  = "reviewing"    // Admin / automated review in progress
        case resolved   = "resolved"     // Settled (no refund)
        case refunded   = "refunded"     // Settled with refund
        case rejected   = "rejected"     // Dispute not upheld

        var label: String {
            switch self {
            case .submitted:  return "Submitted"
            case .reviewing:  return "Under Review"
            case .resolved:   return "Resolved"
            case .refunded:   return "Refunded"
            case .rejected:   return "Closed"
            }
        }

        var isOpen: Bool { self == .submitted || self == .reviewing }
        var isClosed: Bool { !isOpen }
    }

    // MARK: Init

    init(id: String = UUID().uuidString,
         orderID: String,
         customerUID: String,
         providerID: String,
         providerName: String,
         orderAmount: Double,
         reason: DisputeReason,
         description: String,
         refundRequested: Bool,
         status: DisputeStatus = .submitted,
         resolution: String? = nil,
         createdAt: Date = Date(),
         resolvedAt: Date? = nil) {
        self.id = id
        self.orderID = orderID
        self.customerUID = customerUID
        self.providerID = providerID
        self.providerName = providerName
        self.orderAmount = orderAmount
        self.reason = reason
        self.description = description
        self.refundRequested = refundRequested
        self.status = status
        self.resolution = resolution
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
    }
}
