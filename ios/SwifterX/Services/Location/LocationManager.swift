import Foundation
import CoreLocation
import FirebaseFirestore

// MARK: - LocationManager
// Wraps CLLocationManager.
// - **Customer:** optional When In Use prompt on Home for nearby / map; light foreground updates when authorized.
// - **Provider:** When In Use + `startUpdatingLocation` while sharing live location on an active order.

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private static let customerAuthPromptedKey = "swifterx_customer_location_auth_prompted"

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let db      = Firestore.firestore()
    private(set) var sharingOrderID: String?
    /// Customer opted into location for discovery / map (does not write Firestore unless sharing).
    private var customerDiscoveryLocationEnabled = false

    private override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyBest
        manager.distanceFilter    = 15   // write to Firestore every ≥15m
        authorizationStatus       = manager.authorizationStatus
    }

    // MARK: - Public API

    /// One-time When In Use prompt for customers (e.g. first Home visit) so nearby / map can use the user dot.
    func requestWhenInUseForCustomerIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.customerAuthPromptedKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.customerAuthPromptedKey)
        customerDiscoveryLocationEnabled = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func startSharing(orderID: String) {
        sharingOrderID = orderID
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopSharing() {
        sharingOrderID = nil
        if !customerDiscoveryLocationEnabled {
            manager.stopUpdatingLocation()
        }
    }

    // MARK: - Internal write

    private func writeLocation(_ loc: CLLocation) {
        guard let orderID = sharingOrderID else { return }
        db.collection("orders").document(orderID).updateData([
            "providerLat": loc.coordinate.latitude,
            "providerLng": loc.coordinate.longitude
        ])
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.location = loc
            self?.writeLocation(loc)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            let authorized = manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways
            if authorized, self.sharingOrderID != nil || self.customerDiscoveryLocationEnabled {
                manager.startUpdatingLocation()
            } else if !authorized {
                manager.stopUpdatingLocation()
            }
        }
    }
}
