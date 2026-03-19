import SwiftUI

struct ProviderDetailView: View {
    let provider: ServiceProvider
    @StateObject private var cart = CartStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCart = false

    private var services: [ServiceItem] {
        MockData.serviceItems(for: provider.category)
    }

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
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.85, green: 0.85, blue: 0.87))
                .frame(height: 210)

            HStack {
                Button { dismiss() } label: {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "xmark").font(.system(size: 14, weight: .semibold)).foregroundColor(.white))
                }
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "heart").font(.system(size: 14)).foregroundColor(.white))
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "ellipsis").font(.system(size: 14)).foregroundColor(.white))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Provider header
            VStack(spacing: 8) {
                Text(provider.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    Text("\(provider.rating, specifier: "%.1f")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "828282"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "828282"))
                    Text("(\(provider.reviewCount))")
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
                // About / description
                Divider().foregroundColor(Color(hex: "eeeeee"))
                Text(provider.description)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(4)
                    .padding(.vertical, 15)

                Divider().foregroundColor(Color(hex: "eeeeee"))

                // Hours row
                HStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    HStack(spacing: 4) {
                        Text("Open")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "3ab130"))
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "383838"))
                        Text("Closes 6 PM")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "383838"))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 15)

                Divider().foregroundColor(Color(hex: "eeeeee"))

                // Phone row
                HStack(spacing: 20) {
                    Image(systemName: "phone")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Text("(555) 123-4567")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "383838"))
                    Spacer()
                }
                .padding(.vertical, 15)

                Divider().foregroundColor(Color(hex: "eeeeee"))
            }

            // Reviews section
            reviewsSection

            // Our Services section
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

            HStack(spacing: 4) {
                Text("4.8")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "828282"))
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "828282"))
                Text("156 Ratings")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "828282"))
                Spacer()
                Text("view all")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .underline()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MockData.reviews, id: \.reviewer) { review in
                        ReviewCard(review: review)
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

            ForEach(services) { service in
                VStack(spacing: 0) {
                    Divider().foregroundColor(Color(hex: "eeeeee"))
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
            Divider().foregroundColor(Color(hex: "eeeeee"))

            Spacer().frame(height: 80)
        }
    }

    // MARK: - View Cart Button

    private var viewCartButton: some View {
        Button {
            showCart = true
        } label: {
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

// MARK: - Supporting views

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
    let review: (reviewer: String, rating: Int, date: String, text: String)
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "f6f6f6"))
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 14)).foregroundColor(.gray))
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.reviewer)
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
                        Text(review.date)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "828282"))
                    }
                }
            }
            Text(review.text)
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

#Preview {
    NavigationStack {
        ProviderDetailView(provider: MockData.providers[0])
    }
}
