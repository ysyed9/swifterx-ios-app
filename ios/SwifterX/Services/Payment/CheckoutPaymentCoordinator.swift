import Foundation
import UIKit
import FirebaseAuth
import FirebaseFunctions
import StripeCore
import StripePaymentSheet

enum CheckoutPaymentError: LocalizedError {
    case notSignedIn
    case invalidResponse
    case noPresenter
    case paymentFailed(String)
    case confirmationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "You must be signed in to pay."
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

    private let functions: Functions = {
        if let region = Bundle.main.object(forInfoDictionaryKey: "FirebaseFunctionsRegion") as? String,
           !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Functions.functions(region: region)
        }
        return Functions.functions()
    }()

    /// Server reads `order.price` from Firestore and creates the PaymentIntent (never trust client totals).
    func fetchPaymentIntentClientSecret(orderId: String) async throws -> String {
        guard Auth.auth().currentUser != nil else { throw CheckoutPaymentError.notSignedIn }
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
        // Apple Pay
        configuration.applePay = .init(
            merchantId: "merchant.com.swifterx.app",
            merchantCountryCode: "US"
        )
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
                case .failed(let error):
                    continuation.resume(throwing: CheckoutPaymentError.paymentFailed(error.localizedDescription))
                }
            }
        }
    }

    private func hostViewController() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
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
        #if DEBUG
        guard let fnError = error as NSError? else {
            return .paymentFailed(error.localizedDescription)
        }
        let message = fnError.userInfo[NSLocalizedDescriptionKey] as? String ?? fnError.localizedDescription
        let details = fnError.userInfo[FunctionsErrorDetailsKey]
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
