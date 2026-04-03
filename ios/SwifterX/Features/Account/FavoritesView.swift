import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var dataService: DataService

    private var favorites: [ServiceProvider] {
        favoritesStore.favorites(from: dataService.providers)
    }

    var body: some View {
        Group {
            if favorites.isEmpty {
                emptyState
            } else {
                providerList
            }
        }
        .navigationTitle("Favourite Services")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#cccccc"))
            Text("No favourites yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)
            Text("Tap the heart on any provider to save them here.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#828282"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - List

    private var providerList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(favorites) { provider in
                    NavigationLink(destination: ProviderDetailView(provider: provider)) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(hex: "#dbdbdb"))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color(hex: "#999999"))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.black)
                                Text(provider.category)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#828282"))
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.black)
                                    Text("\(provider.rating, specifier: "%.1f")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.black)
                                }
                            }

                            Spacer()

                            Button {
                                withAnimation { favoritesStore.toggle(provider) }
                            } label: {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 20)
                }
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environmentObject(FavoritesStore())
    .environmentObject(DataService(client: MockAPIClient.shared))
}
