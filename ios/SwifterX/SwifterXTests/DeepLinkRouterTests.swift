import XCTest
@testable import SwifterX

final class DeepLinkRouterTests: XCTestCase {

    private let router = DeepLinkRouter.shared

    // MARK: - URL generation helpers

    func testOrderURLFormat() {
        let url = DeepLinkRouter.orderURL(id: "abc123")
        XCTAssertEqual(url.absoluteString, "https://swifterx.app/order/abc123")
    }

    func testReferralURLFormat() {
        let url = DeepLinkRouter.referralURL(code: "REF42")
        XCTAssertEqual(url.absoluteString, "https://swifterx.app/refer/REF42")
    }

    func testProviderURLFormat() {
        let url = DeepLinkRouter.providerURL(id: "provider-007")
        XCTAssertEqual(url.absoluteString, "https://swifterx.app/provider/provider-007")
    }

    // MARK: - URL parsing via handle(url:)

    @MainActor func testHandleOrderURL() {
        let url = DeepLinkRouter.orderURL(id: "order-XYZ")
        router.handle(url: url)
        if case .order(let id) = router.pendingLink {
            XCTAssertEqual(id, "order-XYZ")
        } else {
            XCTFail("Expected .order deep link, got \(String(describing: router.pendingLink))")
        }
        router.clear()
    }

    @MainActor func testHandleReferralURL() {
        let url = DeepLinkRouter.referralURL(code: "INVITE50")
        router.handle(url: url)
        if case .referral(let code) = router.pendingLink {
            XCTAssertEqual(code, "INVITE50")
        } else {
            XCTFail("Expected .referral deep link")
        }
        // Referral also sets pendingReferralCode
        XCTAssertEqual(router.pendingReferralCode, "INVITE50")
        router.clear()
    }

    @MainActor func testHandleProviderURL() {
        let url = DeepLinkRouter.providerURL(id: "prov-007")
        router.handle(url: url)
        if case .provider(let id) = router.pendingLink {
            XCTAssertEqual(id, "prov-007")
        } else {
            XCTFail("Expected .provider deep link")
        }
        router.clear()
    }

    @MainActor func testHandleUnknownPathDoesNotSetLink() {
        let url = URL(string: "https://swifterx.app/unknown/path")!
        router.clear()
        router.handle(url: url)
        XCTAssertNil(router.pendingLink)
    }

    @MainActor func testHandleURLMissingSegmentDoesNotSetLink() {
        let url = URL(string: "https://swifterx.app/order")!
        router.clear()
        router.handle(url: url)
        XCTAssertNil(router.pendingLink)
    }

    @MainActor func testClearRemovesPendingLink() {
        let url = DeepLinkRouter.orderURL(id: "x")
        router.handle(url: url)
        router.clear()
        XCTAssertNil(router.pendingLink)
    }

    // MARK: - Referral code uppercased on parse

    @MainActor func testReferralCodeUppercased() {
        let url = URL(string: "https://swifterx.app/refer/lowercase")!
        router.handle(url: url)
        if case .referral(let code) = router.pendingLink {
            XCTAssertEqual(code, "LOWERCASE")
        }
        router.clear()
    }
}
