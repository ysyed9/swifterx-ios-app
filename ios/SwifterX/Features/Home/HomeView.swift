import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedCategoryID: ServiceCategory.ID?

    private let categories = MockData.categories
    private let recommendations = MockData.recommendations

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SxSpacing.lg) {
                StatusHeaderView(title: "Welcome back", subtitle: "Find trusted services nearby")

                SearchFieldView(text: $searchText)

                VStack(alignment: .leading, spacing: SxSpacing.sm) {
                    Text("Select Service")
                        .font(SxTypography.sectionTitle)
                        .foregroundStyle(.sxPrimaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: SxSpacing.sm) {
                            ForEach(categories) { category in
                                ServiceCategoryCardView(
                                    icon: category.icon,
                                    title: category.title,
                                    isSelected: selectedCategoryID == category.id,
                                    onTap: { selectedCategoryID = category.id }
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: SxSpacing.sm) {
                    Text("Recommended")
                        .font(SxTypography.sectionTitle)
                        .foregroundStyle(.sxPrimaryText)

                    ForEach(recommendations) { service in
                        NavigationLink(value: service) {
                            RecommendationCardView(
                                title: service.title,
                                subtitle: service.subtitle,
                                rating: service.rating,
                                priceText: "$\(service.price)",
                                onTap: {}
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, SxSpacing.md)
            .padding(.top, SxSpacing.md)
            .padding(.bottom, SxSpacing.xl)
        }
        .background(Color.sxBackground)
        .navigationDestination(for: Recommendation.self) { service in
            ServiceDetailView(service: service)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
