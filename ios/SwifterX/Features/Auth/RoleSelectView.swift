import SwiftUI

struct RoleSelectView: View {
    var onCustomer: () -> Void
    var onProvider: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 142)

                Text("Select")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.black)

                Spacer().frame(height: 16)

                Text("Lorem ipsum dolor sit amet consectetur. Faucibus sit non nibh orci scelerisque gravida.")
                    .font(.system(size: 13))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 301)

                Spacer().frame(height: 30)

                HStack(spacing: 15) {
                    Button(action: onCustomer) {
                        RoleCard(
                            icon: "person.3.fill",
                            label: "Customer",
                            isEnabled: true
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onProvider) {
                        RoleCard(
                            icon: "gearshape.2",
                            label: "Provider",
                            isEnabled: true
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}

// MARK: - Role Card

private struct RoleCard: View {
    let icon: String
    let label: String
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(isEnabled ? .black : Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(width: 60, height: 60)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isEnabled ? .black : Color(red: 0.6, green: 0.6, blue: 0.6))
                .textCase(.lowercase)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 155)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isEnabled ? Color.black : Color(red: 0.6, green: 0.6, blue: 0.6), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    RoleSelectView(onCustomer: {}, onProvider: {})
}
