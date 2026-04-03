import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

/// Handles FCM push notification registration and token management.
/// Conform AppDelegate to UNUserNotificationCenterDelegate and MessagingDelegate,
/// then call NotificationManager.shared methods from there.
@MainActor
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published private(set) var fcmToken: String?

    private override init() { super.init() }

    // MARK: - Registration

    /// Request notification permission and register with APNs + FCM.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error { print("[Notifications] Permission error: \(error)") }
            guard granted else {
                print("[Notifications] Permission denied")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Called by AppDelegate after APNs returns a device token.
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Called by AppDelegate when APNs registration fails.
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("[Notifications] APNs registration failed: \(error.localizedDescription)")
    }

    /// Called by MessagingDelegate when FCM provides a new token.
    func didReceiveFCMToken(_ token: String) {
        fcmToken = token
        print("[Notifications] FCM token: \(token)")
        saveTokenToFirestore(token: token)
    }

    // MARK: - Firestore token storage

    private func saveTokenToFirestore(token: String) {
        guard let uid = FirebaseHelper.currentUID else { return }
        Task {
            do {
                let db = FirebaseHelper.firestore
                try await db.collection("users").document(uid).setData(
                    ["fcmToken": token, "fcmTokenUpdatedAt": Date()],
                    merge: true
                )
            } catch {
                print("[Notifications] Failed to save FCM token: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension NotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor in
            NotificationManager.shared.didReceiveFCMToken(token)
        }
    }
}

// MARK: - FirebaseHelper (private)

private enum FirebaseHelper {
    static var currentUID: String? {
        return _currentUID()
    }
    static var firestore: Firestore {
        return Firestore.firestore()
    }
}

// Lazy import to avoid circular deps
import FirebaseAuth
import FirebaseFirestore

private func _currentUID() -> String? {
    return Auth.auth().currentUser?.uid
}
