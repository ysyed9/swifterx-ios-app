import Foundation
import CoreLocation
import FirebaseFirestore

// MARK: - LocationManager
// Wraps CLLocationManager. When a provider starts a job:
//   1. Requests WhenInUse permission (once)
//   2. Streams location updates to Firestore orders/{orderID}
//      with keys providerLat / providerLng
// The customer's existing Firestore listener picks up those changes automatically.

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let db      = Firestore.firestore()
    private(set) var sharingOrderID: String?

    private override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyBest
        manager.distanceFilter    = 15   // write to Firestore every ≥15m
        authorizationStatus       = manager.authorizationStatus
    }

    // MARK: - Public API

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
        manager.stopUpdatingLocation()
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
            if (manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways),
               self.sharingOrderID != nil {
                manager.startUpdatingLocation()
            }
        }
    }
}
