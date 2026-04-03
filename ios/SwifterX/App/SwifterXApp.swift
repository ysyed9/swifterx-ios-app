import SwiftUI
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // Disable In-App Messaging auto-init (not used in this app)
        FirebaseApp.app()?.isDataCollectionDefaultEnabled = true

        // Push notifications
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared
        NotificationManager.shared.requestPermission()

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}

@main
struct SwifterXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager      = AuthManager()
    @StateObject private var profileManager   = UserProfileManager()
    @StateObject private var dataService      = DataService()
    @StateObject private var orderManager     = OrderManager()
    @StateObject private var checkoutPayment  = CheckoutPaymentCoordinator()
    @StateObject private var favoritesStore   = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authManager)
                .environmentObject(profileManager)
                .environmentObject(dataService)
                .environmentObject(orderManager)
                .environmentObject(checkoutPayment)
                .environmentObject(favoritesStore)
                .preferredColorScheme(.light)
        }
    }
}
