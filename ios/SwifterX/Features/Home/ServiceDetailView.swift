import SwiftUI

struct ServiceDetailView: View {
    let provider: ServiceProvider
    @State private var quantity = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SxSpacing.lg) {
                RoundedRectangle(cornerRadius: SxRadius.lg, style: .continuous)
                    .fill(Color.sxBorder)
                    .frame(height: 220)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 34))
                            .foregroundStyle(.sxSecondaryText)
                    )

                VStack(alignment: .leading, spacing: SxSpacing.xs) {
                    Text(provider.name)
                        .font(SxTypography.sectionTitle)
                    Text(provider.description)
                        .font(SxTypography.body)
                        .foregroundStyle(.sxSecondaryText)
                    Label(String(format: "%.1f rating  •  %.1fmi", provider.rating, provider.distanceMi),
                          systemImage: "star.fill")
                        .font(SxTypography.body)
                        .foregroundStyle(.sxAccent)
                }

                HStack {
                    Text("Quantity")
                        .font(SxTypography.body.weight(.semibold))
                    Spacer()
                    Stepper(value: $quantity, in: 1...6) {
                        Text("\(quantity)")
                            .frame(minWidth: 18)
                    }
                }
                .padding()
                .background(Color.sxSurface)
                .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))

                HStack {
                    SecondaryButton(title: "Save for later") {}
                    PrimaryButton(title: "Book Now") {}
                }
            }
            .padding(SxSpacing.md)
        }
        .background(Color.sxBackground)
        .navigationTitle("Service details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ServiceDetailView(provider: MockData.providers[0])
    }
}
