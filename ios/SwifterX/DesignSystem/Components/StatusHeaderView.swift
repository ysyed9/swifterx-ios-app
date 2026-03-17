import SwiftUI

struct StatusHeaderView: View {
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: SxSpacing.sm) {
            VStack(alignment: .leading, spacing: SxSpacing.xxs) {
                Text(title)
                    .font(SxTypography.title)
                    .foregroundStyle(.sxPrimaryText)
                Text(subtitle)
                    .font(SxTypography.body)
                    .foregroundStyle(.sxSecondaryText)
            }
            Spacer()
            Circle()
                .fill(Color.sxAccent.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.sxAccent)
                )
        }
    }
}

#Preview {
    StatusHeaderView(title: "Hi Younus", subtitle: "Find your service today")
        .padding()
        .background(Color.sxBackground)
}
