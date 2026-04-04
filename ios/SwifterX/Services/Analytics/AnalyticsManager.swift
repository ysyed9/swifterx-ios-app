import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

// MARK: - AnalyticsManager
// Central hub for all Firebase Analytics events and Crashlytics breadcrumbs.
// Call from the main thread; all methods are synchronous wrappers.

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - User Identity

    /// Call after sign-in so all subsequent events are attributed to this user.
    func setUser(uid: String) {
        Analytics.setUserID(uid)
        Crashlytics.crashlytics().setUserID(uid)
    }

    /// Call on sign-out to disassociate the session from the user.
    func clearUser() {
        Analytics.setUserID(nil)
        Crashlytics.crashlytics().setUserID("")
    }

    // MARK: - Auth Events

    func logLogin(method: String = "email") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        Crashlytics.crashlytics().log("User logged in via \(method)")
    }

    func logSignUp(method: String = "email") {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
        Crashlytics.crashlytics().log("New account created via \(method)")
    }

    // MARK: - Booking Events

    /// Fired when the customer submits an order (before payment).
    func logOrderPlaced(orderID: String, providerName: String, amount: Double) {
        Analytics.logEvent("order_placed", parameters: [
            "order_id":      orderID,
            "provider_name": providerName,
            AnalyticsParameterValue:    amount,
            AnalyticsParameterCurrency: "USD"
        ])
        Crashlytics.crashlytics().log("Order placed: \(orderID) with \(providerName) for $\(amount)")
    }

    /// Fired after Stripe PaymentIntent is confirmed.
    func logPaymentCompleted(orderID: String, amount: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterTransactionID: orderID,
            AnalyticsParameterValue:         amount,
            AnalyticsParameterCurrency:      "USD"
        ])
        Crashlytics.crashlytics().log("Payment completed: \(orderID) $\(amount)")
    }

    /// Fired when a customer cancels an order.
    func logOrderCancelled(orderID: String) {
        Analytics.logEvent("order_cancelled", parameters: [
            "order_id": orderID
        ])
        Crashlytics.crashlytics().log("Order cancelled: \(orderID)")
    }

    // MARK: - Review Events

    func logReviewSubmitted(providerID: String, rating: Int) {
        Analytics.logEvent("review_submitted", parameters: [
            "provider_id": providerID,
            "rating":      rating
        ])
        Crashlytics.crashlytics().log("Review submitted for \(providerID): \(rating) stars")
    }

    // MARK: - Chat Events

    func logChatOpened(orderID: String) {
        Analytics.logEvent("chat_opened", parameters: [
            "order_id": orderID
        ])
    }

    // MARK: - Screen Tracking

    func logScreen(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name
        ])
    }

    // MARK: - Promo Events

    func logPromoApplied(code: String, discountAmount: Double) {
        Analytics.logEvent("promo_applied", parameters: [
            "promo_code":      code,
            "discount_amount": discountAmount
        ])
    }

    // MARK: - Crashlytics Breadcrumbs

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func recordError(_ error: Error, context: String) {
        Crashlytics.crashlytics().log("Error in \(context): \(error.localizedDescription)")
        Crashlytics.crashlytics().record(error: error)
    }
}

// MARK: - PerformanceTracer
// Thin wrapper around Firebase Performance traces so call sites don't import FirebasePerformance.

struct PerformanceTracer {
    private let trace: Trace?

    init?(name: String) {
        trace = Performance.startTrace(name: name)
    }

    func stop() {
        trace?.stop()
    }

    func increment(_ metric: String, by count: Int64 = 1) {
        trace?.incrementMetric(metric, by: count)
    }

    func setAttribute(_ key: String, value: String) {
        trace?.setValue(value, forAttribute: key)
    }
}
