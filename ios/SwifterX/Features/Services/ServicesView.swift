import SwiftUI

struct ServicesView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var filteredProviders: [ServiceProvider] {
        let base = MockData.providers
        if let cat = selectedCategory {
            return base.filter { $0.category == cat }
        }
        return base
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                Text("Services")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#858585"))
                    TextField("Search services...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(Color(hex: "#f6f6f6"))
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Categories
                Text("Browse Categories")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MockData.categories, id: \.name) { cat in
                        ServiceCategoryTile(
                            name: cat.name,
                            icon: cat.icon,
                            isSelected: selectedCategory == cat.name
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = (selectedCategory == cat.name) ? nil : cat.name
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Providers
                HStack {
                    Text(selectedCategory ?? "All Providers")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                    Spacer()
                    if selectedCategory != nil {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            Text("Clear")
                                .font(.system(size: 13))
                                .foregroundStyle(.black)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 4)

                if filteredProviders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "#cccccc"))
                        Text("No providers in this category yet.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#828282"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(filteredProviders) { provider in
                            NavigationLink(destination: ProviderDetailView(provider: provider)) {
                                ProviderListRow(provider: provider)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer().frame(height: 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

// MARK: - Category Tile

private struct ServiceCategoryTile: View {
    let name: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(isSelected ? .white : .black)
                .frame(width: 44, height: 44)

            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(isSelected ? Color.black : Color(hex: "#f6f6f6"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Provider Row

private struct ProviderListRow: View {
    let provider: ServiceProvider

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "#dbdbdb"))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "#999999"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                Text(provider.category)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#828282"))
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.black)
                    Text("\(provider.rating, specifier: "%.1f")  •  \(provider.distanceMi, specifier: "%.1f")mi")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#828282"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#aaaaaa"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack { ServicesView() }
}
