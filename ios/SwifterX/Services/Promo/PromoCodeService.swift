import Foundation
import FirebaseFirestore

// MARK: - PromoCodeService

@MainActor
final class PromoCodeService: ObservableObject {
    static let shared = PromoCodeService()

    @Published var validatedPromo: PromoCode?
    @Published var promoState: PromoState = .idle

    private let db = Firestore.firestore()
    private init() {}

    enum PromoState: Equatable {
        case idle
        case loading
        case valid(discount: Double, description: String)
        case invalid(String)
    }

    // MARK: - Validate

    func validate(code: String, subtotal: Double) async {
        let key = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !key.isEmpty else { promoState = .idle; validatedPromo = nil; return }
        promoState = .loading

        do {
            let snap = try await db.collection("promoCodes").document(key).getDocument()
            guard snap.exists, let promo = try? snap.data(as: PromoCode.self) else {
                promoState = .invalid("Code \(key) not found.")
                validatedPromo = nil
                return
            }
            if let discount = promo.discount(for: subtotal) {
                validatedPromo = promo
                let label = promo.discountType == .percent
                    ? "\(Int(promo.discountValue))% off"
                    : "$\(String(format: "%.2f", promo.discountValue)) off"
                promoState = .valid(discount: discount, description: label)
            } else {
                validatedPromo = nil
                if !promo.isActive {
                    promoState = .invalid("This code is no longer active.")
                } else if let exp = promo.expiresAt, exp < Date() {
                    promoState = .invalid("This code has expired.")
                } else if promo.maxUses > 0, promo.usedCount >= promo.maxUses {
                    promoState = .invalid("This code has reached its usage limit.")
                } else {
                    promoState = .invalid("Minimum order of $\(Int(promo.minOrderValue)) required.")
                }
            }
        } catch {
            promoState = .invalid("Could not validate code. Check your connection.")
            validatedPromo = nil
        }
    }

    // MARK: - Redeem (called after order placed)

    func redeem(code: String) {
        let key = code.uppercased()
        db.collection("promoCodes").document(key).updateData([
            "usedCount": FieldValue.increment(Int64(1))
        ])
    }

    func reset() {
        validatedPromo = nil
        promoState = .idle
    }
}
