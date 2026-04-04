import Foundation

// MARK: - PromoCode
// Stored in Firestore at promoCodes/{uppercased-code}

struct PromoCode: Codable {
    var code: String
    var discountType: DiscountType   // "percent" | "fixed"
    var discountValue: Double        // e.g. 15 = 15 % or $15
    var minOrderValue: Double        // minimum cart total to apply
    var maxUses: Int                 // 0 = unlimited
    var usedCount: Int
    var isActive: Bool
    var expiresAt: Date?

    enum DiscountType: String, Codable {
        case percent
        case fixed
    }

    /// Returns the dollar-amount discount for a given subtotal, or nil if invalid.
    func discount(for subtotal: Double) -> Double? {
        guard isActive, subtotal >= minOrderValue else { return nil }
        if let exp = expiresAt, exp < Date() { return nil }
        if maxUses > 0, usedCount >= maxUses  { return nil }
        switch discountType {
        case .percent: return min(subtotal, subtotal * discountValue / 100)
        case .fixed:   return min(subtotal, discountValue)
        }
    }
}
