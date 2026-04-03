import SwiftUI

/// Provider-side browse/search — not detailed in Figma; matches customer app theme (white, black text, grey search field).
struct ProviderServicesView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var searchText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Services")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#858585"))
                    TextField("Search services you offer...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(Color(hex: "#f6f6f6"))
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Text("Manage how customers find your offerings. Connect to your service catalog in a future update.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#828282"))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                if dataService.isLoadingProviders {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reference — nearby categories")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        ForEach(dataService.categories.filter {
                            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                        }, id: \.name) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.black)
                                    .frame(width: 40)
                                Text(cat.name)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#aaaaaa"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            Divider().padding(.leading, 60)
                        }
                    }
                }

                Spacer().frame(height: 32)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task {
            if dataService.categories.isEmpty {
                await dataService.loadCategories()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProviderServicesView()
    }
    .environmentObject(DataService(client: MockAPIClient.shared))
}
