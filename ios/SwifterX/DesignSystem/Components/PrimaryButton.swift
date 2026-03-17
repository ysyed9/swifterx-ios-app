import SwiftUI

struct PrimaryButton: View {
    let title: String
    var fullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SxTypography.body.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.horizontal, SxSpacing.lg)
                .padding(.vertical, SxSpacing.sm)
                .background(Color.sxAccent)
                .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SxTypography.body.weight(.medium))
                .foregroundStyle(Color.sxPrimaryText)
                .padding(.horizontal, SxSpacing.lg)
                .padding(.vertical, SxSpacing.sm)
                .background(Color.sxSurface)
                .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous)
                        .stroke(Color.sxBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: SxSpacing.md) {
        PrimaryButton(title: "Continue", action: {})
        SecondaryButton(title: "Cancel", action: {})
    }
    .padding()
    .background(Color.sxBackground)
}
