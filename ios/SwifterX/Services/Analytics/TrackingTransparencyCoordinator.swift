import AppTrackingTransparency
import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation
import UIKit

/// App Tracking Transparency bootstrap.
/// Implements [`requestTrackingAuthorization(completionHandler:)`](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/requesttrackingauthorization(completionhandler:))
/// after a foreground `UIWindowScene` is ready (important on iPad / multitasking), then enables Firebase Analytics.
@MainActor
enum TrackingTransparencyCoordinator {
    private static var hasStartedAuthorizationRequest = false
    private static var didFinishBootstrap = false
    /// One in-flight bootstrap so `applicationDidBecomeActive` and SwiftUI do not race or return early while ATT is still up.
    private static var bootstrapSerial: Task<Void, Never>?

    /// Call from `applicationDidBecomeActive` and/or root UI. Safe to call multiple times; concurrent callers await the same work.
    static func runLaunchFlowIfNeeded() async {
        if didFinishBootstrap { return }
        if let existing = bootstrapSerial {
            await existing.value
            return
        }
        let work = Task { await executeBootstrap() }
        bootstrapSerial = work
        await work.value
        bootstrapSerial = nil
    }

    private static func executeBootstrap() async {
        guard !didFinishBootstrap else { return }

        if ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT") {
            Analytics.setAnalyticsCollectionEnabled(true)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
            didFinishBootstrap = true
            hasStartedAuthorizationRequest = true
            return
        }

        await waitForForegroundPresentation()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 320_000_000)
        guard !didFinishBootstrap else { return }

        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined:
                guard !hasStartedAuthorizationRequest else { return }
                hasStartedAuthorizationRequest = true
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    ATTrackingManager.requestTrackingAuthorization { _ in
                        Task { @MainActor in
                            enableAnalyticsAndMarkComplete()
                            continuation.resume()
                        }
                    }
                }
            default:
                enableAnalyticsAndMarkComplete()
            }
        } else {
            enableAnalyticsAndMarkComplete()
        }
    }

    /// Wait until the app has an active scene and at least one visible window so the ATT alert can attach (App Review on iPad).
    private static func waitForForegroundPresentation() async {
        let step: UInt64 = 50_000_000
        for _ in 0..<90 {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let active = scenes.filter {
                $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
            }
            let windows = active.flatMap(\.windows)
            if windows.contains(where: { !$0.isHidden && $0.alpha > 0.01 && !$0.bounds.isEmpty }) {
                return
            }
            try? await Task.sleep(nanoseconds: step)
        }
    }

    private static func enableAnalyticsAndMarkComplete() {
        guard !didFinishBootstrap else { return }
        Analytics.setAnalyticsCollectionEnabled(true)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        didFinishBootstrap = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            NotificationManager.shared.requestPermission()
        }
    }
}
