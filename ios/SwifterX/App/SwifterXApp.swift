import SwiftUI
import FirebaseAnalytics
import FirebaseAppCheck
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications

#if !DEBUG
/// Production App Check: DeviceCheck attestation (enable enforcement in Firebase Console when ready).
private final class SwifterXDeviceCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        DeviceCheckProvider(app: app)
    }
}
#endif

enum AppCheckBootstrap {
    /// Must run before `FirebaseApp.configure()` so Firestore / Functions attach tokens.
    static func install() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(SwifterXDeviceCheckProviderFactory())
        #endif
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppCheckBootstrap.install()
        FirebaseApp.configure()

        // Hold Analytics until ATT completes on first launch (see TrackingTransparencyCoordinator).
        Analytics.setAnalyticsCollectionEnabled(false)

        // Disable In-App Messaging auto-init (not used in this app)
        FirebaseApp.app()?.isDataCollectionDefaultEnabled = true

        // Firestore offline persistence — providers + past orders load from disk instantly
        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings

        // Push notifications — delegate only here; permission is requested **after** ATT
        // (see `TrackingTransparencyCoordinator`) so the tracking dialog is not masked at launch.
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { await TrackingTransparencyCoordinator.runLaunchFlowIfNeeded() }
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
    @StateObject private var authManager             = AuthManager()
    @StateObject private var profileManager          = UserProfileManager()
    @StateObject private var providerProfileManager  = ProviderProfileManager.shared
    @StateObject private var locationManager         = LocationManager.shared
    @StateObject private var dataService             = DataService()
    @StateObject private var orderManager            = OrderManager()
    @StateObject private var checkoutPayment         = CheckoutPaymentCoordinator()
    @StateObject private var favoritesStore          = FavoritesStore()
    @StateObject private var networkMonitor          = NetworkMonitor.shared
    @StateObject private var deepLinkRouter          = DeepLinkRouter.shared
    @StateObject private var notificationFeed      = NotificationFeedStore.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authManager)
                .environmentObject(profileManager)
                .environmentObject(providerProfileManager)
                .environmentObject(locationManager)
                .environmentObject(dataService)
                .environmentObject(orderManager)
                .environmentObject(checkoutPayment)
                .environmentObject(favoritesStore)
                .environmentObject(networkMonitor)
                .environmentObject(deepLinkRouter)
                .environmentObject(notificationFeed)
                .environmentObject(GeoSortService.shared)
                .preferredColorScheme(.light)
                // Universal links
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
                // Feed device location into geo sorter
                .onReceive(locationManager.$location) { loc in
                    GeoSortService.shared.update(coordinate: loc?.coordinate)
                }
        }
    }
}
