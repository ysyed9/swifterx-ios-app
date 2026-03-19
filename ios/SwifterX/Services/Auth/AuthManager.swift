import SwiftUI
import FirebaseAuth
import GoogleSignIn

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case googleSignInFailed
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
        } catch {
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
        } catch {
            throw AuthError.from(error)
        }
    }

    // MARK: - Create Account

    func createAccount(email: String, password: String, name: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
        } catch {
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
        } catch {
            throw AuthError.from(error)
        }
    }
}
