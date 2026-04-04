import SwiftUI

// MARK: - EmptyStateView
// Reusable illustrated empty state with icon, title, subtitle, and optional CTA button.

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    // Visual accent colour for the icon circle
    var accentColor: Color = Color(hex: "#111111")

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Icon circle with subtle gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.08), accentColor.opacity(0.02)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(accentColor.opacity(0.55))
            }

            Spacer().frame(height: 24)

            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#888888"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let title = actionTitle, let action {
                Spacer().frame(height: 28)
                Button(action: action) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 13)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
