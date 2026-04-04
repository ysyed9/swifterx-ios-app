import SwiftUI
import MapKit
import CoreLocation

// MARK: - ProviderTrackingCard
// Shown in OrderDetailView when the order is inProgress.
// Reads live lat/lng from the order document (Firestore listener updates automatically).

struct ProviderTrackingCard: View {
    let order: ServiceOrder   // the *live* order from orderManager.customerOrders

    @State private var mapPosition: MapCameraPosition = .automatic

    private var providerCoord: CLLocationCoordinate2D? {
        guard let lat = order.providerLat, let lng = order.providerLng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private var etaText: String {
        guard let coord = providerCoord else { return "Locating provider…" }
        // Haversine from provider to approximate Austin city center as placeholder.
        // In production this would use the customer's stored address coordinates.
        let customerLat = 30.2672, customerLng = -97.7431
        let distanceM = haversineMeters(
            lat1: coord.latitude, lng1: coord.longitude,
            lat2: customerLat,   lng2: customerLng
        )
        // Assume 25 mph (≈11.2 m/s) average urban speed
        let minutes = Int(distanceM / 11.2 / 60)
        if minutes < 1 { return "Arriving now" }
        if minutes == 1 { return "~1 min away" }
        return "~\(minutes) min away"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Provider en route")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                }
                Spacer()
                Text(etaText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1e7a34"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#e6f4ea"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Map
            Group {
                if let coord = providerCoord {
                    Map(position: $mapPosition) {
                        // Provider's live location
                        Annotation("", coordinate: coord) {
                            ProviderDot()
                        }
                    }
                    .mapStyle(.standard(elevation: .flat))
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .onChange(of: coord.latitude) { _ in centerMap(on: coord) }
                    .onChange(of: coord.longitude) { _ in centerMap(on: coord) }
                    .onAppear { centerMap(on: coord) }
                } else {
                    // Waiting for first location ping
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "#f5f5f5"))
                            .frame(height: 180)
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Waiting for provider location…")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#888888"))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#e8f5e9"), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private func centerMap(on coord: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.6)) {
            mapPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    // MARK: - Haversine

    private func haversineMeters(lat1: Double, lng1: Double,
                                  lat2: Double, lng2: Double) -> Double {
        let R = 6_371_000.0
        let φ1 = lat1 * .pi / 180,  φ2 = lat2 * .pi / 180
        let Δφ = (lat2 - lat1) * .pi / 180
        let Δλ = (lng2 - lng1) * .pi / 180
        let a  = sin(Δφ/2)*sin(Δφ/2) + cos(φ1)*cos(φ2)*sin(Δλ/2)*sin(Δλ/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

// MARK: - Animated provider dot

private struct ProviderDot: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: pulse ? 36 : 24, height: pulse ? 36 : 24)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                           value: pulse)
            Circle()
                .fill(Color.blue)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
        .onAppear { pulse = true }
    }
}
