import SwiftUI

struct CartView: View {
    @State private var itemCount = 1
    private let item = MockData.recommendations[0]

    var body: some View {
        VStack(alignment: .leading, spacing: SxSpacing.lg) {
            Text("View carts")
                .font(SxTypography.sectionTitle)

            RecommendationCardView(
                title: item.title,
                subtitle: item.subtitle,
                rating: item.rating,
                priceText: "$\(item.price)",
                onTap: {}
            )

            HStack {
                Text("Quantity")
                    .font(SxTypography.body.weight(.semibold))
                Spacer()
                Stepper(value: $itemCount, in: 1...6) {
                    Text("\(itemCount)")
                        .font(SxTypography.body)
                }
            }
            .padding()
            .background(Color.sxSurface)
            .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: SxSpacing.xs) {
                Text("Total")
                    .font(SxTypography.caption)
                    .foregroundStyle(.sxSecondaryText)
                Text("$\(item.price * itemCount)")
                    .font(SxTypography.sectionTitle)
            }

            PrimaryButton(title: "Proceed to checkout") {}
            Spacer()
        }
        .padding(SxSpacing.md)
        .background(Color.sxBackground)
    }
}

#Preview {
    NavigationStack {
        CartView()
    }
}
