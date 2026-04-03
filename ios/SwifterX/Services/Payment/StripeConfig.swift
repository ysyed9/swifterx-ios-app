import Foundation

/// Reads Stripe publishable key from Info.plist. When missing or placeholder, checkout skips live Stripe and confirms orders locally (development only).
enum StripeConfig {
    static var publishableKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String
        guard let key, !key.isEmpty, !key.contains("REPLACE_ME") else { return nil }
        return key
    }

    /// `true` when a real publishable key is set **and** you deploy the Cloud Functions in `firebase/functions`.
    static var isLivePaymentsEnabled: Bool {
        publishableKey != nil
    }
}
