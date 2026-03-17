import SwiftUI

struct BottomTabItemView: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(SxTypography.caption)
        }
        .foregroundStyle(isSelected ? Color.sxAccent : Color.sxSecondaryText)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {
        BottomTabItemView(title: "Home", systemImage: "house.fill", isSelected: true)
        BottomTabItemView(title: "Cart", systemImage: "cart", isSelected: false)
        BottomTabItemView(title: "Profile", systemImage: "person", isSelected: false)
    }
    .padding()
    .background(Color.sxSurface)
}
