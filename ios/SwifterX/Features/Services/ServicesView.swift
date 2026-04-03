import SwiftUI

struct ServicesView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredProviders: [ServiceProvider] {
        dataService.filteredProviders(category: selectedCategory, search: searchText)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

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

                if dataService.categories.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.bottom, 12)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(dataService.categories, id: \.name) { cat in
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
                }

                // Providers header
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

                if dataService.isLoadingProviders {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if filteredProviders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "#cccccc"))
                        Text("No providers found.")
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
        .task {
            if dataService.providers.isEmpty {
                async let p: () = dataService.loadProviders()
                async let c: () = dataService.loadCategories()
                _ = await (p, c)
            }
        }
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
            ProviderThumb(provider: provider)
                .frame(width: 64, height: 64)

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
                    Text("\(provider.rating, specifier: "%.1f")  •  \(provider.distanceMi, specifier: "%.1f")mi away")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#828282"))
                    Text("• \(provider.reviewCount) reviews")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#aaaaaa"))
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

// MARK: - Provider Thumbnail

private struct ProviderThumb: View {
    let provider: ServiceProvider

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(hex: "#dbdbdb"))
            .overlay { imageContent }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    fallbackIcon
                }
            }
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 24))
            .foregroundStyle(Color(hex: "#999999"))
    }
}

#Preview {
    NavigationStack { ServicesView() }
        .environmentObject(DataService(client: MockAPIClient.shared))
}
