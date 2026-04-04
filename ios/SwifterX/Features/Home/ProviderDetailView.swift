import SwiftUI

struct ProviderDetailView: View {
    let provider: ServiceProvider
    @StateObject private var cart = CartStore.shared
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @State private var showCart        = false
    @State private var showAllReviews  = false
    @State private var reviews:    [Review] = []
    @State private var services:   [ServiceItem] = []
    @State private var isLoading   = true

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)

            if !cart.items.isEmpty && cart.provider?.id == provider.id {
                viewCartButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCart) {
            CartCheckoutView()
        }
        .sheet(isPresented: $showAllReviews) {
            AllReviewsSheet(provider: provider, reviews: reviews)
        }
        .task {
            async let r = dataService.fetchReviews(for: provider.id)
            let fetchedReviews = await r
            reviews  = fetchedReviews.isEmpty ? MockData.mockReviews.filter { $0.providerID == provider.id } : fetchedReviews
            services = MockData.serviceItems(for: provider.category)
            isLoading = false
        }
    }

    private func shareProvider() {
        let url = DeepLinkRouter.providerURL(id: provider.id)
        let text = "Check out \(provider.name) on SwifterX — \(provider.category) services, rated \(String(format: "%.1f", provider.rating))★"
        let items: [Any] = [text, url]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(av, animated: true)
        AnalyticsManager.shared.log("Provider shared: \(provider.id)")
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .top) {
            providerHeroImage
                .frame(height: 210)

            HStack {
                Button { dismiss() } label: {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            favoritesStore.toggle(provider)
                        }
                    } label: {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: favoritesStore.isFavorite(provider.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(favoritesStore.isFavorite(provider.id) ? .red : .white)
                            )
                    }
                    Button {
                        shareProvider()
                    } label: {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundColor(.white))
                    }
                    .accessibilityLabel("Share provider")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }

    private var providerHeroImage: some View {
        Color(red: 0.85, green: 0.85, blue: 0.87)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if !provider.imageName.isEmpty {
                    Image(provider.imageName)
                        .resizable()
                        .scaledToFill()
                } else if let url = URL(string: provider.imageURL), !provider.imageURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        }
                    }
                }
            }
            .clipped()
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Provider header
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(provider.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    if provider.showsVerifiedBadge {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "2563eb"))
                            .accessibilityLabel("Verified provider")
                    }
                }

                HStack(spacing: 4) {
                    Text("\(provider.rating, specifier: "%.1f")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "828282"))
                    Text("(\(reviews.isEmpty ? provider.reviewCount : reviews.count))")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "828282"))
                    Text(String(format: "%.1fmi", provider.distanceMi))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                }

                HStack(spacing: 8) {
                    TagChip("Best Overall")
                    TagChip("emergency services")
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                Divider()
                Text(provider.description)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(4)
                    .padding(.vertical, 15)

                Divider()

                // Hours row
                HStack(spacing: 20) {
                    Image(systemName: "clock").font(.system(size: 14)).foregroundColor(.black)
                    HStack(spacing: 4) {
                        Text("Open").font(.system(size: 14)).foregroundColor(Color(hex: "3ab130"))
                        Text("•").font(.system(size: 9)).foregroundColor(Color(hex: "383838"))
                        Text("Closes 6 PM").font(.system(size: 14)).foregroundColor(Color(hex: "383838"))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.gray)
                }
                .padding(.vertical, 15)

                Divider()

                HStack(spacing: 20) {
                    Image(systemName: "phone").font(.system(size: 14)).foregroundColor(.black)
                    Text("(555) 123-4567").font(.system(size: 14)).foregroundColor(Color(hex: "383838"))
                    Spacer()
                }
                .padding(.vertical, 15)

                Divider()
            }

            reviewsSection
            servicesSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reviews")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 4) {
                    Text("\(provider.rating, specifier: "%.1f")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "828282"))
                    Text("\(reviews.isEmpty ? provider.reviewCount : reviews.count) Ratings")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                    Spacer()
                    Button { showAllReviews = true } label: {
                        Text("view all")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .underline()
                    }
                }

                if reviews.isEmpty {
                    Text("No reviews yet.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "828282"))
                        .padding(.top, 4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(reviews) { review in
                                ReviewCard(review: review)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Services

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Our Services")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 4)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                ForEach(services) { service in
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(service.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                Text("$\(Int(service.price))")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "828282"))
                            }
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    if cart.contains(service) {
                                        cart.remove(service)
                                    } else {
                                        cart.add(service, from: provider)
                                    }
                                }
                            } label: {
                                Circle()
                                    .fill(cart.contains(service) ? Color.black : Color(hex: "f6f6f6"))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: cart.contains(service) ? "checkmark" : "plus")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(cart.contains(service) ? .white : .black)
                                    )
                            }
                        }
                        .padding(.vertical, 15)
                    }
                }
                Divider()
                Spacer().frame(height: 80)
            }
        }
    }

    // MARK: - View Cart Button

    private var viewCartButton: some View {
        Button { showCart = true } label: {
            HStack {
                Spacer()
                Text("View cart (\(cart.items.count))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.black)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Supporting Views

private struct TagChip: View {
    let label: String
    init(_ label: String) { self.label = label }
    var body: some View {
        Text(label)
            .font(.system(size: 12))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(hex: "f6f6f6"))
            .cornerRadius(8)
    }
}

private struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "f6f6f6"))
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray))
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.customerName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    HStack(spacing: 15) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= review.rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: "828282"))
                            }
                        }
                        Text(review.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "828282"))
                    }
                }
            }
            Text(review.comment)
                .font(.system(size: 12))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(width: 300)
        .background(Color(hex: "f6f6f6"))
        .cornerRadius(8)
    }
}

// MARK: - All Reviews Sheet

private struct AllReviewsSheet: View {
    let provider: ServiceProvider
    let reviews: [Review]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if reviews.isEmpty {
                        Text("No reviews yet.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "828282"))
                            .padding(.top, 40)
                    } else {
                        ForEach(reviews) { review in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: "f6f6f6"))
                                        .frame(width: 36, height: 36)
                                        .overlay(Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(review.customerName)
                                            .font(.system(size: 14, weight: .semibold))
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { i in
                                                Image(systemName: i <= review.rating ? "star.fill" : "star")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(Color(hex: "828282"))
                                            }
                                        }
                                    }
                                    Spacer()
                                    Text(review.timeAgo)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "828282"))
                                }
                                Text(review.comment)
                                    .font(.system(size: 13))
                                    .foregroundColor(.black)
                                    .lineSpacing(3)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationTitle("\(provider.name) — Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.black)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProviderDetailView(provider: MockData.providers[0])
    }
    .environmentObject(DataService(client: MockAPIClient.shared))
    .environmentObject(FavoritesStore())
}
