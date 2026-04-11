import SwiftUI
import UIKit
import Security
import CryptoKit
import AuthenticationServices
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseAnalytics

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case googleSignInFailed
    case appleSignInFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:        return "Please enter a valid email address."
        case .wrongPassword:       return "Incorrect password. Please try again."
        case .userNotFound:        return "No account found with this email."
        case .emailAlreadyInUse:   return "An account with this email already exists."
        case .weakPassword:        return "Password must be at least 6 characters."
        case .networkError:        return "Network error. Please check your connection."
        case .googleSignInFailed:  return "Google sign-in failed. Please try again."
        case .appleSignInFailed:   return "Sign in with Apple failed. On a real device, enable Sign in with Apple for this app in Firebase and Apple Developer. If this persists, try again."
        case .unknown(let msg):    return msg
        }
    }

    static func from(_ error: Error) -> AuthError {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:        return .invalidEmail
        case .wrongPassword:       return .wrongPassword
        case .userNotFound:        return .userNotFound
        case .emailAlreadyInUse:   return .emailAlreadyInUse
        case .weakPassword:        return .weakPassword
        case .networkError:        return .networkError
        default:                   return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - AuthManager

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = true

    private var stateListener: AuthStateDidChangeListenerHandle?

    init() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.currentUser = user
                self?.isLoading = false
                if let uid = user?.uid {
                    AnalyticsManager.shared.setUser(uid: uid)
                }
            }
        }
    }

    deinit {
        if let handle = stateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool { currentUser != nil }
    var userUID: String? { currentUser?.uid }
    var userEmail: String? { currentUser?.email }
    var displayName: String? { currentUser?.displayName }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            AnalyticsManager.shared.logLogin(method: "email")
        } catch {
            AnalyticsManager.shared.recordError(error, context: "signIn")
            throw AuthError.from(error)
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        guard let rootVC = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            throw AuthError.googleSignInFailed
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.googleSignInFailed
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        do {
            try await Auth.auth().signIn(with: credential)
            AnalyticsManager.shared.logLogin(method: "google")
        } catch {
            AnalyticsManager.shared.recordError(error, context: "googleSignIn")
            throw AuthError.from(error)
        }
    }

    // MARK: - Sign in with Apple (Guideline 4.8 — equivalent option alongside Google)

    /// Random nonce for the Apple request; SHA256 hash is sent to Apple, raw value is passed to Firebase.
    nonisolated static func newAppleSignInRawNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: max(1, length))
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    nonisolated static func sha256HexForAppleNonce(_ raw: String) -> String {
        let data = Data(raw.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws {
        guard !idToken.isEmpty, !rawNonce.isEmpty else {
            throw AuthError.appleSignInFailed
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        do {
            try await Auth.auth().signIn(with: credential)
            AnalyticsManager.shared.logLogin(method: "apple")
        } catch {
            AnalyticsManager.shared.recordError(error, context: "appleSignIn")
            throw AuthError.from(error)
        }
    }

    /// Presents the system Sign in with Apple sheet (custom UI can call this like `signInWithGoogle()`).
    func signInWithAppleUsingSystemPrompt() async throws {
        let rawNonce = Self.newAppleSignInRawNonce()
        let result = try await AppleSignInPresentation.perform(rawNonce: rawNonce)
        try await signInWithApple(idToken: result.idToken, rawNonce: rawNonce, fullName: result.fullName)
    }

    // MARK: - Create Account

    func createAccount(email: String, password: String, name: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            AnalyticsManager.shared.logSignUp(method: "email")
        } catch {
            AnalyticsManager.shared.recordError(error, context: "createAccount")
            throw AuthError.from(error)
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            AnalyticsManager.shared.clearUser()
            AnalyticsManager.shared.log("User signed out")
        } catch {
            throw AuthError.from(error)
        }
    }
}

// MARK: - Sign in with Apple (ASAuthorizationController)

private enum AppleSignInPresentation {
    private static var retentionKey: UInt8 = 0

    struct AppleSignInResult {
        let idToken: String
        let fullName: PersonNameComponents?
    }

    /// `ASAuthorizationController` often returns **error 1000 (ASAuthorizationError.unknown)** if `performRequests()` runs off the main thread or there is no key window.
    @MainActor
    static func perform(rawNonce: String) async throws -> AppleSignInResult {
        guard signInAnchorWindow() != nil else {
            throw AuthError.appleSignInFailed
        }
        return try await withCheckedThrowingContinuation { continuation in
            let box = AppleSignInControllerBox(continuation: continuation)
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = AuthManager.sha256HexForAppleNonce(rawNonce)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = box
            controller.presentationContextProvider = box
            objc_setAssociatedObject(controller, &retentionKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            box.controller = controller
            controller.performRequests()
        }
    }

    /// Only use from the main thread (Sign in with Apple calls `presentationAnchor` on main).
    private static func signInAnchorWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let foreground = scenes.filter { $0.activationState == .foregroundActive }
        let pool = foreground.isEmpty ? scenes : foreground
        let windows = pool.flatMap(\.windows)
        return windows.first(where: { $0.isKeyWindow })
            ?? windows.first
            ?? scenes.flatMap(\.windows).first
    }

    private static func signInPresentationAnchor() -> ASPresentationAnchor {
        signInAnchorWindow() ?? UIWindow(frame: UIScreen.main.bounds)
    }

    private final class AppleSignInControllerBox: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        private let continuation: CheckedContinuation<AppleSignInResult, Error>
        weak var controller: ASAuthorizationController?

        init(continuation: CheckedContinuation<AppleSignInResult, Error>) {
            self.continuation = continuation
        }

        private func finishRetaining() {
            if let c = controller {
                objc_setAssociatedObject(c, &AppleSignInPresentation.retentionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            controller = nil
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            AppleSignInPresentation.signInPresentationAnchor()
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            finishRetaining()
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8), !idToken.isEmpty else {
                continuation.resume(throwing: AuthError.appleSignInFailed)
                return
            }
            continuation.resume(returning: AppleSignInResult(idToken: idToken, fullName: cred.fullName))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            finishRetaining()
            if let authErr = error as? ASAuthorizationError {
                if authErr.code == .canceled {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                // Code 1000 == .unknown — common when presentation is invalid or capability / Firebase Apple provider is misconfigured.
                if authErr.code == .unknown || authErr.code == .failed {
                    continuation.resume(throwing: AuthError.appleSignInFailed)
                    return
                }
            }
            continuation.resume(throwing: error)
        }
    }
}
