import Foundation
import FirebaseFunctions

// MARK: - StripeConnectService
// Wraps the three Cloud Functions that manage provider Stripe Connect payouts.

@MainActor
final class StripeConnectService: ObservableObject {
    static let shared = StripeConnectService()

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil

    struct Earnings {
        let completedJobs: Int
        let grossEarnings: Double
        let platformFee:   Double
        let netEarnings:   Double
        let feePercent:    Double
    }

    private let functions = Functions.functions()
    private init() {}

    // MARK: - Create / retrieve Connect account

    /// Creates a Stripe Express account for the provider (idempotent — safe to call multiple times).
    /// Returns the Stripe account ID.
    func createAccount() async throws -> String {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let result = try await functions.httpsCallable("createConnectAccount").call()
        guard let data = result.data as? [String: Any],
              let accountId = data["accountId"] as? String else {
            throw ConnectError.unexpectedResponse
        }
        return accountId
    }

    // MARK: - Onboarding URL

    /// Returns a single-use Stripe-hosted onboarding URL.
    /// Open this in `ASWebAuthenticationSession` or `SFSafariViewController`.
    func onboardingURL() async throws -> URL {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let result = try await functions.httpsCallable("getConnectOnboardingUrl").call()
        guard let data = result.data as? [String: Any],
              let urlStr = data["url"] as? String,
              let url = URL(string: urlStr) else {
            throw ConnectError.unexpectedResponse
        }
        return url
    }

    // MARK: - Dashboard URL

    /// Returns a Stripe Express dashboard login link (valid for 5 minutes).
    func dashboardURL() async throws -> URL {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let result = try await functions.httpsCallable("getConnectDashboardUrl").call()
        guard let data = result.data as? [String: Any],
              let urlStr = data["url"] as? String,
              let url = URL(string: urlStr) else {
            throw ConnectError.unexpectedResponse
        }
        return url
    }

    // MARK: - Earnings summary

    func fetchEarnings() async throws -> Earnings {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let result = try await functions.httpsCallable("getProviderEarnings").call()
        guard let data = result.data as? [String: Any] else { throw ConnectError.unexpectedResponse }
        return Earnings(
            completedJobs: data["completedJobs"] as? Int    ?? 0,
            grossEarnings: data["grossEarnings"] as? Double ?? 0,
            platformFee:   data["platformFee"]   as? Double ?? 0,
            netEarnings:   data["netEarnings"]   as? Double ?? 0,
            feePercent:    data["feePercent"]     as? Double ?? 20
        )
    }

    // MARK: - Error

    enum ConnectError: LocalizedError {
        case unexpectedResponse
        var errorDescription: String? { "Unexpected response from server." }
    }
}
