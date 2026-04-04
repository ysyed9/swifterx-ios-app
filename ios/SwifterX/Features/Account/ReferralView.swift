import SwiftUI

struct ReferralView: View {
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var copied = false
    @State private var showShare = false

    private var referralCode: String {
        profileManager.profile?.referralCode ?? "–"
    }
    private var credits: Double {
        profileManager.profile?.referralCredits ?? 0
    }
    private var shareText: String {
        "Book home services with SwifterX — fast, trusted, on demand. Use my code \(referralCode) at checkout and we both get $10 credit! Download: https://swifterx.app"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // Hero
                ZStack {
                    Color.black
                    VStack(spacing: 10) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                        Text("Give $10, Get $10")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Share your code. When a friend places their first order, you both get $10 credit.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 44)
                }

                // Credit balance card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your referral credits")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#888888"))
                        Text("$\(String(format: "%.2f", credits))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "#f0c040"))
                }
                .padding(20)
                .background(Color(hex: "#fafafa"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#eeeeee"), lineWidth: 1))
                .padding(20)

                // Code card
                VStack(spacing: 14) {
                    Text("Your referral code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#888888"))

                    Text(referralCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .tracking(3)

                    HStack(spacing: 12) {
                        // Copy
                        Button {
                            UIPasteboard.general.string = referralCode
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label(copied ? "Copied!" : "Copy code",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(copied ? Color.green : Color.black)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: copied)

                        // Share
                        Button { showShare = true } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(hex: "#f2f2f2"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: "#eeeeee"), lineWidth: 1))
                .padding(.horizontal, 20)

                // How it works
                VStack(alignment: .leading, spacing: 16) {
                    Text("How it works")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)

                    step(num: "1", text: "Share your unique code with a friend")
                    step(num: "2", text: "They sign up and place their first order")
                    step(num: "3", text: "You both get $10 credit automatically")
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                Spacer().frame(height: 40)
            }
        }
        .background(Color.white)
        .navigationTitle("Refer a Friend")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
    }

    private func step(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color.black)
                .frame(width: 28, height: 28)
                .overlay(Text(num).font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#444444"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - System share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
