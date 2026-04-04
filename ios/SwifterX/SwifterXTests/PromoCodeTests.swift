import XCTest
@testable import SwifterX

final class PromoCodeTests: XCTestCase {

    // MARK: - Helpers

    private func makePromo(type: PromoCode.DiscountType, value: Double,
                           minOrder: Double = 0, maxUses: Int = 0,
                           usedCount: Int = 0, isActive: Bool = true,
                           expiresAt: Date? = nil) -> PromoCode {
        PromoCode(code: "TEST",
                  discountType: type,
                  discountValue: value,
                  minOrderValue: minOrder,
                  maxUses: maxUses,
                  usedCount: usedCount,
                  isActive: isActive,
                  expiresAt: expiresAt)
    }

    // MARK: - Percent discount

    func testPercentDiscountCalculation() {
        let promo = makePromo(type: .percent, value: 20)       // 20% off
        let discount = promo.discount(for: 100.0)
        XCTAssertEqual(discount, 20.0, accuracy: 0.001)
    }

    func testPercentDiscountOnFractionalSubtotal() {
        let promo = makePromo(type: .percent, value: 10)       // 10% off
        let discount = promo.discount(for: 49.99)
        XCTAssertEqual(discount!, 4.999, accuracy: 0.001)
    }

    // MARK: - Fixed discount

    func testFixedDiscountReturnsExactValue() {
        let promo = makePromo(type: .fixed, value: 15)         // $15 off
        XCTAssertEqual(promo.discount(for: 100.0), 15.0)
    }

    func testFixedDiscountCappedAtSubtotal() {
        let promo = makePromo(type: .fixed, value: 200)        // $200 off $50 order
        let discount = promo.discount(for: 50.0)
        // Discount cannot exceed subtotal
        XCTAssertLessThanOrEqual(discount ?? 0, 50.0)
    }

    // MARK: - Minimum order requirement

    func testPromoReturnsNilWhenBelowMinOrder() {
        let promo = makePromo(type: .percent, value: 15, minOrder: 50)
        XCTAssertNil(promo.discount(for: 30.0))
    }

    func testPromoAppliesWhenExactlyAtMinOrder() {
        let promo = makePromo(type: .percent, value: 10, minOrder: 50)
        XCTAssertNotNil(promo.discount(for: 50.0))
    }

    // MARK: - Inactive promo

    func testInactivePromoReturnsNil() {
        let promo = makePromo(type: .percent, value: 10, isActive: false)
        XCTAssertNil(promo.discount(for: 100.0))
    }

    // MARK: - Usage limit

    func testUnlimitedUsageAllowed() {
        let promo = makePromo(type: .fixed, value: 5, maxUses: 0, usedCount: 9999)
        XCTAssertNotNil(promo.discount(for: 100.0))
    }

    func testMaxUsesReachedReturnsNil() {
        let promo = makePromo(type: .fixed, value: 5, maxUses: 10, usedCount: 10)
        XCTAssertNil(promo.discount(for: 100.0))
    }

    func testUsedCountBelowMaxIsAllowed() {
        let promo = makePromo(type: .fixed, value: 5, maxUses: 10, usedCount: 9)
        XCTAssertNotNil(promo.discount(for: 100.0))
    }

    // MARK: - Expiry

    func testExpiredPromoReturnsNil() {
        let past = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let promo = makePromo(type: .percent, value: 10, expiresAt: past)
        XCTAssertNil(promo.discount(for: 100.0))
    }

    func testFutureExpiryAllowed() {
        let future = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let promo = makePromo(type: .percent, value: 10, expiresAt: future)
        XCTAssertNotNil(promo.discount(for: 100.0))
    }

    func testNilExpiryNeverExpires() {
        let promo = makePromo(type: .percent, value: 10, expiresAt: nil)
        XCTAssertNotNil(promo.discount(for: 100.0))
    }
}
