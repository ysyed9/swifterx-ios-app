import SwiftUI

struct ServiceCategoryCardView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: SxSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.sxAccent)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.sxAccent : Color.sxAccent.opacity(0.15))
                    )

                Text(title)
                    .font(SxTypography.caption)
                    .foregroundStyle(.sxPrimaryText)
                    .lineLimit(1)
            }
            .frame(width: 68)
            .padding(.vertical, SxSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        ServiceCategoryCardView(icon: "scissors", title: "Salon", isSelected: true, onTap: {})
        ServiceCategoryCardView(icon: "wrench.adjustable", title: "Repair", isSelected: false, onTap: {})
    }
    .padding()
    .background(Color.sxBackground)
}
