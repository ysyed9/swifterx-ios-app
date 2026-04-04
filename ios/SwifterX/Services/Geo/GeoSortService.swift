import Foundation
import CoreLocation

// MARK: - GeoSortService

/// Sorts ServiceProviders by distance from a reference coordinate using the
/// Haversine formula.  Falls back to rating-sorted order when location is unavailable.
@MainActor
final class GeoSortService: ObservableObject {
    static let shared = GeoSortService()

    @Published private(set) var userCoordinate: CLLocationCoordinate2D? = nil

    private init() {}

    // MARK: - Update reference location

    /// Call this whenever LocationManager publishes a new coordinate.
    func update(coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
    }

    // MARK: - Sorting

    /// Returns providers sorted by distance (nearest first).
    /// If no user coordinate is available, falls back to descending rating order.
    func sorted(_ providers: [ServiceProvider]) -> [ServiceProvider] {
        guard let origin = userCoordinate else {
            return providers.sorted { $0.rating > $1.rating }
        }
        return providers.sorted {
            distance(from: origin, to: $0.coordinate) <
            distance(from: origin, to: $1.coordinate)
        }
    }

    /// Returns (providers, distances) pairs so views can show "X km away".
    func sortedWithDistances(_ providers: [ServiceProvider]) -> [(provider: ServiceProvider, km: Double?)] {
        guard let origin = userCoordinate else {
            return providers
                .sorted { $0.rating > $1.rating }
                .map { ($0, nil) }
        }
        return providers
            .map { ($0, distance(from: origin, to: $0.coordinate)) }
            .sorted { ($0.km ?? .infinity) < ($1.km ?? .infinity) }
    }

    // MARK: - Haversine

    private func distance(from a: CLLocationCoordinate2D,
                          to b: CLLocationCoordinate2D) -> Double {
        let R = 6371.0  // Earth radius km
        let lat1 = a.latitude  * .pi / 180
        let lat2 = b.latitude  * .pi / 180
        let dLat = (b.latitude  - a.latitude)  * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180

        let sinLat = sin(dLat / 2)
        let sinLon = sin(dLon / 2)
        let h = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon
        return 2 * R * asin(min(1, sqrt(h)))
    }
}

// MARK: - ServiceProvider coordinate helper

extension ServiceProvider {
    /// Convenience computed property — providers whose lat/lng are both 0 are
    /// treated as "no location available".
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: providerLat, longitude: providerLng)
    }

    var hasLocation: Bool { providerLat != 0 || providerLng != 0 }
}
