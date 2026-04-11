import AppTrackingTransparency
import FirebaseAnalytics
import Foundation

/// App Tracking Transparency bootstrap.
/// Implements [`requestTrackingAuthorization(completionHandler:)`](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/requesttrackingauthorization(completionhandler:))
/// on the main actor after the first UI frame, then enables Firebase Analytics so no analytics run until the ATT flow has started or is skipped (already decided / unavailable).
@MainActor
enum TrackingTransparencyCoordinator {
    /// Prevents double-presenting the system sheet if `runLaunchFlowIfNeeded()` is called from both AppDelegate and SwiftUI.
    private static var hasStartedAuthorizationRequest = false
    /// Set when analytics may run (after ATT completion or when status was already resolved).
    private static var didFinishBootstrap = false

    /// Call from `applicationDidBecomeActive` and/or root UI `task` / `onAppear`. Safe to call multiple times.
    static func runLaunchFlowIfNeeded() async {
        guard !didFinishBootstrap else { return }
        // Let the first frame + splash paint before ATT (helps the system sheet appear above a ready window).
        await Task.yield()
        try? await Task.sleep(nanoseconds: 250_000_000)

        guard !didFinishBootstrap else { return }

        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined:
                guard !hasStartedAuthorizationRequest else { return }
                hasStartedAuthorizationRequest = true
                ATTrackingManager.requestTrackingAuthorization { _ in
                    Task { @MainActor in
                        enableAnalyticsAndMarkComplete()
                    }
                }
            default:
                enableAnalyticsAndMarkComplete()
            }
        } else {
            enableAnalyticsAndMarkComplete()
        }
    }

    private static func enableAnalyticsAndMarkComplete() {
        guard !didFinishBootstrap else { return }
        Analytics.setAnalyticsCollectionEnabled(true)
        didFinishBootstrap = true
        // Ask for push **after** ATT so two system prompts don’t compete; brief pause avoids stacked sheets.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            NotificationManager.shared.requestPermission()
        }
    }
}
