import Foundation
import Combine

// MARK: - DeepLink

enum DeepLink: Equatable {
    case order(id: String)
    case referral(code: String)
    case provider(id: String)
}

// MARK: - DeepLinkRouter

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    /// Set by onOpenURL / userActivity handler. AppRootView observes and acts.
    @Published var pendingLink: DeepLink? = nil

    /// Pending referral code waiting for signup to complete.
    @Published var pendingReferralCode: String? = nil

    private init() {}

    // MARK: - Parse

    /// Returns a typed DeepLink from a universal link URL, or nil if unrecognised.
    func handle(url: URL) {
        guard let link = parse(url: url) else { return }
        if case .referral(let code) = link {
            // Store separately so LoginView can pick it up on the signup screen
            pendingReferralCode = code
        }
        pendingLink = link
        AnalyticsManager.shared.log("Deep link received: \(url.absoluteString)")
    }

    func clear() { pendingLink = nil }

    // MARK: - URL parsing

    private func parse(url: URL) -> DeepLink? {
        // Support both https://swifterx.app/order/abc and swifterx://order/abc
        let path = url.pathComponents.filter { $0 != "/" }
        guard path.count >= 2 else { return nil }
        switch path[0] {
        case "order":    return .order(id: path[1])
        case "refer":    return .referral(code: path[1].uppercased())
        case "provider": return .provider(id: path[1])
        default:         return nil
        }
    }

    // MARK: - Link generation

    static func orderURL(id: String) -> URL {
        URL(string: "https://swifterx.app/order/\(id)")!
    }

    static func referralURL(code: String) -> URL {
        URL(string: "https://swifterx.app/refer/\(code)")!
    }

    static func providerURL(id: String) -> URL {
        URL(string: "https://swifterx.app/provider/\(id)")!
    }
}
