import Foundation

/// Reads Stripe publishable key from the built Info.plist (`StripePublishableKey` ← `$(STRIPE_PUBLISHABLE_KEY)` from `Config/Shared.xcconfig` + optional `Secrets.xcconfig`).
/// Release builds **must** have a valid key to place orders (no “free” paid orders from misconfiguration).
enum StripeConfig {
    static var publishableKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String
        guard let key, !key.isEmpty, !key.contains("REPLACE_ME") else { return nil }
        return key
    }

    /// `true` when PaymentSheet + Cloud Functions payment flow should run.
    static var isLivePaymentsEnabled: Bool {
        publishableKey != nil
    }

    /// Only DEBUG may create `confirmed` / `paid` orders without Stripe (local dev).
    static var canSimulatePaidCheckoutWithoutStripe: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Shown when a Release build has no valid Stripe publishable key.
    static let checkoutBlockedMessage =
        "Payments are not available in this build. Please update the app from the App Store."
}
