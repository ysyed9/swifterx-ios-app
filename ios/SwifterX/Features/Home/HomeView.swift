import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    let categories = MockData.categories
    let providers   = MockData.providers

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(hex: "#858585"))
                    Text("Search Swifter")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#858585"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(Color(hex: "#f6f6f6"))
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Top Services
                SectionHeader(title: "Top Services for you", action: "Show More")
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(categories.prefix(5)), id: \.name) { cat in
                            CategoryPillView(name: cat.name, icon: cat.icon)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)

                // Recommended
                SectionHeader(title: "Recommended", action: "Show More")
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                VStack(spacing: 0) {
                    ForEach(providers.prefix(3)) { provider in
                        NavigationLink(destination: ProviderDetailView(provider: provider)) {
                            ProviderRowView(provider: provider)
                        }
                        .buttonStyle(.plain)
                        if provider.id != providers.prefix(3).last?.id {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
                .padding(.top, 12)

                // Featured Services
                SectionHeader(title: "Featured Services", action: "")
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(providers) { provider in
                        NavigationLink(destination: ProviderDetailView(provider: provider)) {
                            FeaturedCardView(provider: provider)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer().frame(height: 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

private struct SectionHeader: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
            Spacer()
            if !action.isEmpty {
                Text(action)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black)
                    .underline()
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "#dbdbdb"))
                .frame(width: 94, height: 84)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: "#999999"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "#dbdbdb"))
                .frame(width: 116, height: 102)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "#999999"))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(provider.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1e1e1e"))
                Text(provider.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black)
                    .lineLimit(4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview {
    NavigationStack { HomeView() }
}
