import SwiftUI
import MapKit

// MARK: - NearbyProvidersMapView
// Shows all providers as map pins. Tapping a pin opens ProviderDetailView.

struct NearbyProvidersMapView: View {
    @EnvironmentObject private var dataService:    DataService
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var geoSort:        GeoSortService

    @State private var selectedProvider: ServiceProvider? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var providersWithLocation: [ServiceProvider] {
        dataService.providers.filter { $0.hasLocation }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                // User location dot
                UserAnnotation()

                // Provider pins
                ForEach(providersWithLocation) { provider in
                    Annotation(provider.name, coordinate: provider.coordinate) {
                        ProviderMapPin(provider: provider, isSelected: selectedProvider?.id == provider.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedProvider = (selectedProvider?.id == provider.id) ? nil : provider
                                }
                            }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea(edges: .bottom)

            // Navigation bar overlay
            navBar
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedProvider) { provider in
            NavigationStack {
                ProviderDetailView(provider: provider)
            }
        }
        .onAppear {
            centerOnUser()
        }
        .onChange(of: locationManager.location) { _ in
            centerOnUser()
        }
    }

    // MARK: - Sub-views

    private var navBar: some View {
        HStack {
            Text("Nearby Providers")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Spacer()
            Text("\(providersWithLocation.count) nearby")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#858585"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private func centerOnUser() {
        if let coord = locationManager.location?.coordinate {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 8_000,
                    longitudinalMeters: 8_000
                ))
            }
        } else {
            // Default to Atlanta if no location
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 33.749, longitude: -84.388),
                latitudinalMeters: 12_000,
                longitudinalMeters: 12_000
            ))
        }
    }
}

// MARK: - Provider Map Pin

private struct ProviderMapPin: View {
    let provider: ServiceProvider
    let isSelected: Bool

    private var categoryIcon: String {
        switch provider.category {
        case "Plumbing":     return "drop.fill"
        case "Repairing":   return "wrench.and.screwdriver.fill"
        case "Gardening":   return "leaf.fill"
        case "Electrician": return "bolt.fill"
        case "Cleaning":    return "sparkles"
        case "Pest Control":return "shield.fill"
        case "Painting":    return "paintbrush.fill"
        case "Landscaping": return "tree.fill"
        default:            return "house.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.black : Color.white)
                    .frame(width: isSelected ? 48 : 36, height: isSelected ? 48 : 36)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Image(systemName: categoryIcon)
                    .font(.system(size: isSelected ? 18 : 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .black)
            }

            // Pointer triangle
            Triangle()
                .fill(isSelected ? Color.black : Color.white)
                .frame(width: 10, height: 6)
                .shadow(color: .black.opacity(0.1), radius: 1)

            if isSelected {
                Text(provider.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    .padding(.top, 4)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Triangle shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
