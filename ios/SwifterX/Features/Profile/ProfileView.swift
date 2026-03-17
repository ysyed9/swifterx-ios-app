import SwiftUI

struct ProfileView: View {
    @State private var notificationsEnabled = true
    @State private var darkMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SxSpacing.lg) {
                HStack(spacing: SxSpacing.md) {
                    Circle()
                        .fill(Color.sxAccent.opacity(0.25))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text("YS")
                                .font(SxTypography.cardTitle)
                                .foregroundStyle(.sxAccent)
                        )
                    VStack(alignment: .leading, spacing: SxSpacing.xxs) {
                        Text("Younus Syed")
                            .font(SxTypography.cardTitle)
                        Text("younus.syed@utdallas.edu")
                            .font(SxTypography.caption)
                            .foregroundStyle(.sxSecondaryText)
                    }
                }

                VStack(spacing: SxSpacing.sm) {
                    Toggle("Push notifications", isOn: $notificationsEnabled)
                    Toggle("Dark mode preview", isOn: $darkMode)
                }
                .padding()
                .background(Color.sxSurface)
                .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: SxSpacing.sm) {
                    Text("Saved addresses")
                        .font(SxTypography.body.weight(.semibold))
                    Text("2300 Northside Blvd, Richardson, TX")
                        .font(SxTypography.caption)
                        .foregroundStyle(.sxSecondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.sxSurface)
                .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))

                SecondaryButton(title: "Log out") {}
            }
            .padding(SxSpacing.md)
        }
        .background(darkMode ? Color.black.opacity(0.9) : Color.sxBackground)
        .tint(.sxAccent)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
