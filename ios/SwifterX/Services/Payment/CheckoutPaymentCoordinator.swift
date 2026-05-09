import Foundation
import UIKit
import FirebaseAuth
import FirebaseFunctions
import StripeCore
import StripePaymentSheet

enum CheckoutPaymentError: LocalizedError {
    case notSignedIn
    /// Callable returned UNAUTHENTICATED — no valid Auth context reached Cloud Functions.
    case serverAuthMissing
    case invalidResponse
    case noPresenter
    case paymentFailed(String)
    case confirmationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "You must be signed in to pay."
        case .serverAuthMissing:
            return "Your session wasn’t accepted by the payment server. Sign out, sign in again, then try checkout once more."
        case .invalidResponse: return "Could not start payment. Deploy Cloud Functions and check logs."
        case .noPresenter: return "Could not show payment screen."
        case .paymentFailed(let m): return m
        case .confirmationFailed(let m): return m
        }
    }
}

/// Creates Stripe PaymentIntents via Firebase Callable Functions and presents **PaymentSheet**.
@MainActor
final class CheckoutPaymentCoordinator: ObservableObject {

    private let functions = AppFunctions.instance

    /// Ensures a fresh ID token is attached to the next Callable request (avoids `context.auth == null` → UNAUTHENTICATED).
    private func refreshAuthTokenForCallable() async throws {
        guard let user = Auth.auth().currentUser else {
            throw CheckoutPaymentError.notSignedIn
        }
        _ = try await user.getIDToken()
    }

    /// Server reads `order.price` from Firestore and creates the PaymentIntent (never trust client totals).
    func fetchPaymentIntentClientSecret(orderId: String) async throws -> String {
        try await refreshAuthTokenForCallable()
        let callable = functions.httpsCallable("createStripePaymentIntent")
        callable.timeoutInterval = 60
        let result: HTTPSCallableResult
        do {
            result = try await callable.call(["orderId": orderId])
        } catch {
            throw mappedError(error)
        }
        guard let dict = result.data as? [String: Any],
              let secret = dict["clientSecret"] as? String else {
            throw CheckoutPaymentError.invalidResponse
        }
        return secret
    }

    /// Verifies PaymentIntent status with Stripe and marks the order **paid** + **confirmed**.
    func confirmOrderPayment(orderId: String) async throws {
        try await refreshAuthTokenForCallable()
        let callable = functions.httpsCallable("confirmOrderPayment")
        callable.timeoutInterval = 60
        let result: HTTPSCallableResult
        do {
            result = try await callable.call(["orderId": orderId])
        } catch {
            AnalyticsManager.shared.recordError(error, context: "confirmOrderPayment:\(orderId)")
            throw mappedError(error)
        }
        if let dict = result.data as? [String: Any],
           let ok = dict["ok"] as? Bool, ok == false,
           let msg = dict["error"] as? String {
            throw CheckoutPaymentError.confirmationFailed(msg)
        }
        // Payment confirmed — log the purchase event.
        // We don't have the amount here easily; the cloud function owns authoritative amount.
        AnalyticsManager.shared.logPaymentCompleted(orderID: orderId, amount: 0)
        AnalyticsManager.shared.log("Payment confirmed for order \(orderId)")
    }

    /// Presents Stripe PaymentSheet. Returns `true` if the customer completed payment.
    func presentPaymentSheet(clientSecret: String, publishableKey: String) async throws -> Bool {
        StripeAPI.defaultPublishableKey = publishableKey
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "SwifterX"
        configuration.allowsDelayedPaymentMethods = true
        let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)

        guard let presenter = hostViewController() else {
            throw CheckoutPaymentError.noPresenter
        }

        return try await withCheckedThrowingContinuation { continuation in
            sheet.present(from: presenter) { result in
                switch result {
                case .completed:
                    continuation.resume(returning: true)
                case .canceled:
                    continuation.resume(returning: false)
                case .failed:
                    continuation.resume(throwing: CheckoutPaymentError.paymentFailed(
                        "Payment couldn’t be completed. Check your card or try another method."
                    ))
                }
            }
        }
    }

    private func hostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        let pool = active.isEmpty ? scenes : active
        let windows = pool.flatMap(\.windows)
        let key = windows.first(where: { $0.isKeyWindow })?.rootViewController
        let fallback = windows.reversed().first(where: { !$0.isHidden && $0.alpha > 0.01 })?.rootViewController
        guard let root = key ?? fallback else { return nil }
        return Self.topMost(from: root)
    }

    private static func topMost(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMost(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(from: selected)
        }
        return vc
    }

    private func mappedError(_ error: Error) -> CheckoutPaymentError {
        let ns = error as NSError
        if ns.domain == FunctionsErrorDomain,
           ns.code == FunctionsErrorCode.unauthenticated.rawValue {
            return .serverAuthMissing
        }
        #if DEBUG
        let message = ns.userInfo[NSLocalizedDescriptionKey] as? String ?? ns.localizedDescription
        let details = ns.userInfo[FunctionsErrorDetailsKey]
        if let detailsString = details as? String, !detailsString.isEmpty {
            return .paymentFailed("\(message) (\(detailsString))")
        }
        return .paymentFailed(message)
        #else
        AnalyticsManager.shared.recordError(error, context: "checkout_payment_callable")
        return .paymentFailed("Something went wrong. Please try again.")
        #endif
    }
}
