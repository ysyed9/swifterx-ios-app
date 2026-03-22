import SwiftUI
import FirebaseCore
import GoogleSignIn

// Firebase recommends initializing via AppDelegate so it runs before any
// SwiftUI lifecycle code, ensuring Auth state listeners are set up first.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // Required for Google Sign-In to handle the OAuth redirect URL
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct SwifterXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var profileManager = UserProfileManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authManager)
                .environmentObject(profileManager)
                .preferredColorScheme(.light)
        }
    }
}
