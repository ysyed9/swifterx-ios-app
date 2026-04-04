import Foundation
import FirebaseFirestore

// MARK: - InAppNotificationItem
// Mirrors documents in users/{uid}/notifications/{id}

struct InAppNotificationItem: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let category: Category
    let orderId: String?
    let promoCode: String?
    var read: Bool
    let createdAt: Date?

    enum Category: String, CaseIterable {
        case order
        case chat
        case promo
        case dispute
        case system

        var icon: String {
            switch self {
            case .order:   return "doc.text.fill"
            case .chat:    return "bubble.left.fill"
            case .promo:   return "tag.fill"
            case .dispute: return "exclamationmark.shield.fill"
            case .system:  return "bell.fill"
            }
        }

        var label: String {
            switch self {
            case .order:   return "Order"
            case .chat:    return "Chat"
            case .promo:   return "Promo"
            case .dispute: return "Dispute"
            case .system:  return "News"
            }
        }
    }

    init(id: String,
         title: String,
         body: String,
         category: Category,
         orderId: String? = nil,
         promoCode: String? = nil,
         read: Bool,
         createdAt: Date?) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.orderId = orderId
        self.promoCode = promoCode
        self.read = read
        self.createdAt = createdAt
    }

    init?(id: String, data: [String: Any]) {
        guard let title = data["title"] as? String,
              let body = data["body"] as? String,
              let raw = data["category"] as? String else { return nil }
        let cat = Category(rawValue: raw) ?? .system
        self.id = id
        self.title = title
        self.body = body
        self.category = cat
        self.orderId = data["orderId"] as? String
        self.promoCode = data["promoCode"] as? String
        self.read = (data["read"] as? Bool) ?? false
        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = nil
        }
    }
}
