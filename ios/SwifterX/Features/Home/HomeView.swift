import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var geoSort: GeoSortService
    @EnvironmentObject private var locationManager: LocationManager

    private var topProviders: [ServiceProvider] {
        Array(geoSort.sorted(dataService.providers).prefix(3))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                HeroBanner { appState.activeTab = .services }

                // Top Services
                SectionHeader(title: "Top Services for you", action: "Show More") {
                    appState.activeTab = .services
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)

                if dataService.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<5, id: \.self) { _ in SkeletonCategoryPill() }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    .allowsHitTesting(false)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(dataService.categories.prefix(5)), id: \.name) { cat in
                                Button { appState.activeTab = .services } label: {
                                    CategoryPillView(name: cat.name, icon: cat.icon)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                }

                // Recommended
                SectionHeader(title: "Recommended", action: "Show More") {
                    appState.activeTab = .services
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                if dataService.isLoadingProviders {
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { i in
                            SkeletonProviderRow()
                            if i < 2 { Divider().padding(.leading, 20) }
                        }
                    }
                    .padding(.top, 12)
                    .allowsHitTesting(false)
                } else {
                    VStack(spacing: 0) {
                        ForEach(topProviders) { provider in
                            NavigationLink(destination: ProviderDetailView(provider: provider)) {
                                ProviderRowView(provider: provider)
                            }
                            .buttonStyle(.plain)
                            if provider.id != topProviders.last?.id {
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                    .padding(.top, 12)
                }

                // Featured Services
                SectionHeader(title: "Featured Services", action: "") { }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                if dataService.isLoadingProviders {
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in SkeletonFeaturedCard() }
                    }
                    .padding(.top, 12)
                    .allowsHitTesting(false)
                } else {
                    VStack(spacing: 12) {
                        ForEach(dataService.providers) { provider in
                            NavigationLink(destination: ProviderDetailView(provider: provider)) {
                                FeaturedCardView(provider: provider)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 24)
            }
            // This is the one place maxWidth is safe: the direct child of ScrollView.
            // It tells the VStack to fill the scroll view's width (= screen width).
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task {
            if dataService.providers.isEmpty {
                async let p: () = dataService.loadProviders()
                async let c: () = dataService.loadCategories()
                _ = await (p, c)
            }
        }
        .onAppear {
            locationManager.requestWhenInUseForCustomerIfNeeded()
        }
    }
}

// MARK: - Hero Banner

private struct HeroBanner: View {
    let onSearchTap: () -> Void

    var body: some View {
        // Content VStack owns the frame — background image stretches to match it.
        // This avoids ZStack sizing ambiguity (Color.infinity vs image size).
        VStack(spacing: 0) {

            // Bell — top right
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                    Circle()
                        .fill(Color(hex: "#f97316"))
                        .frame(width: 9, height: 9)
                        .offset(x: 3, y: -3)
                }
                .accessibilityLabel("Notifications")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer()

            // Centred branding
            VStack(spacing: 6) {
                Text("SwifterX")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    Text("Empowerment through opportunity")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.78))
                        .tracking(0.2)
            }

            Spacer()

            // Black pill — matches the tab bar below
            Button(action: onSearchTap) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#666666"))
                    Text("Search services, providers…")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: "#999999"))
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "#dddddd"))
                        .frame(width: 1, height: 16)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#666666"))
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search for services and providers")
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        // Image is a background: it fills exactly the content VStack's bounds.
        .background(
            Image("img_hero_banner")
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.42))
                .clipped()
        )
    }
}

// MARK: - Subviews

private struct SectionHeader: View {
    let title: String
    let action: String
    let onAction: () -> Void

    init(title: String, action: String, onAction: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
            Spacer(minLength: 8)
            if !action.isEmpty {
                Button(action: onAction) {
                    Text(action)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.black)
                        .underline()
                }
            }
        }
    }
}

private struct CategoryPillView: View {
    let name: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "#dbdbdb"))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color(hex: "#555555"))
                )
            Text(name)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.black)
        }
        .frame(width: 60)
    }
}

private struct ProviderRowView: View {
    let provider: ServiceProvider

    var body: some View {
        HStack(spacing: 12) {
            ProviderThumbView(provider: provider, cornerRadius: 8)
                .frame(width: 94, height: 84)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(provider.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                    if provider.showsVerifiedBadge {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "2563eb"))
                            .accessibilityLabel("Verified")
                    }
                }
                Text(provider.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.black)
                    Text("\(provider.rating, specifier: "%.1f")  \(provider.distanceMi, specifier: "%.1f")mi")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.black)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(hex: "#999999"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

private struct FeaturedCardView: View {
    let provider: ServiceProvider

    var body: some View {
        HStack(spacing: 12) {
            ProviderThumbView(provider: provider, cornerRadius: 8)
                .frame(width: 116, height: 102)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(provider.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1e1e1e"))
                    if provider.showsVerifiedBadge {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "2563eb"))
                            .accessibilityLabel("Verified")
                    }
                }
                Text(provider.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(4)
            }
            Spacer()
        }
    }
}

private struct ProviderThumbView: View {
    let provider: ServiceProvider
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(hex: "#dbdbdb"))
            .overlay { imageContent }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var imageContent: some View {
        if !provider.imageName.isEmpty {
            Image(provider.imageName)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: provider.imageURL), !provider.imageURL.isEmpty {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    placeholderIcon
                }
            }
        } else {
            placeholderIcon
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.system(size: 22))
            .foregroundStyle(Color(hex: "#999999"))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview {
    NavigationStack { HomeView() }
        .environmentObject(DataService(client: MockAPIClient.shared))
        .environmentObject(AppState())
        .environmentObject(GeoSortService.shared)
        .environmentObject(LocationManager.shared)
}
