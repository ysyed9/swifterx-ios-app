import SwiftUI

struct RecommendationCardView: View {
    let title: String
    let subtitle: String
    let rating: Double
    let priceText: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: SxSpacing.md) {
            RoundedRectangle(cornerRadius: SxRadius.sm, style: .continuous)
                .fill(Color.sxBorder)
                .frame(width: 100, height: 84)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.sxSecondaryText)
                )

            VStack(alignment: .leading, spacing: SxSpacing.xs) {
                Text(title)
                    .font(SxTypography.cardTitle)
                    .foregroundStyle(.sxPrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(SxTypography.caption)
                    .foregroundStyle(.sxSecondaryText)
                    .lineLimit(2)

                HStack {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(SxTypography.caption)
                        .foregroundStyle(.sxAccent)
                    Spacer()
                    Text(priceText)
                        .font(SxTypography.body.weight(.semibold))
                        .foregroundStyle(.sxPrimaryText)
                }
            }
        }
        .padding(SxSpacing.sm)
        .background(Color.sxSurface)
        .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))
        .shadow(color: .sxCardShadow, radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

#Preview {
    RecommendationCardView(
        title: "Home Cleaning",
        subtitle: "Trained professional with all supplies",
        rating: 4.8,
        priceText: "$59",
        onTap: nil
    )
    .padding()
    .background(Color.sxBackground)
}
