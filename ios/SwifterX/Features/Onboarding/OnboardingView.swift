import SwiftUI

// MARK: - OnboardingView
// A 3-slide full-screen walkthrough shown exactly once after a new account is created.
// Gated by UserDefaults key "swifterx_onboarding_done".

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var currentPage = 0
    private let pages: [OnboardingPage] = OnboardingPage.all

    var body: some View {
        ZStack {
            // Full-screen background — slides between page accent colours
            pages[currentPage].background
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: currentPage)

            VStack(spacing: 0) {

                // Skip
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .accessibilityLabel("Skip onboarding")
                    } else {
                        Color.clear.frame(width: 60, height: 44)
                    }
                }

                Spacer()

                // Illustration
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 220, height: 220)
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.bottom, 44)
                .transition(.scale.combined(with: .opacity))
                .id(currentPage) // forces re-render with transition on page change
                .animation(.spring(response: 0.5, dampingFraction: 0.72), value: currentPage)

                // Text
                VStack(spacing: 12) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id("title_\(currentPage)")
                        .animation(.easeInOut(duration: 0.35), value: currentPage)

                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id("sub_\(currentPage)")
                        .animation(.easeInOut(duration: 0.35).delay(0.05), value: currentPage)
                }

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i == currentPage ? 1 : 0.35))
                            .frame(width: i == currentPage ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(pages[currentPage].background.opacity(1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityLabel(currentPage < pages.count - 1 ? "Next slide" : "Get started")
            }
        }
        // Swipe gesture for natural feel
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40, currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else if value.translation.width > 40, currentPage > 0 {
                        withAnimation { currentPage -= 1 }
                    }
                }
        )
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: OnboardingView.doneKey)
        onFinished()
    }

    static let doneKey = "swifterx_onboarding_done"

    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: doneKey)
    }
}

// MARK: - Page model

private struct OnboardingPage {
    let icon:     String
    let title:    String
    let subtitle: String
    let background: Color

    static let all: [OnboardingPage] = [
        OnboardingPage(
            icon:     "house.and.flag.fill",
            title:    "Home services,\non demand",
            subtitle: "Book trusted professionals for plumbing, cleaning, electrical work, and more — in minutes.",
            background: Color(hex: "#111111")
        ),
        OnboardingPage(
            icon:     "bolt.shield.fill",
            title:    "Vetted &\ntransparent",
            subtitle: "Every provider is background-checked. See real reviews, ratings, and upfront pricing before you book.",
            background: Color(hex: "#1a1a2e")
        ),
        OnboardingPage(
            icon:     "mappin.and.ellipse",
            title:    "Track in\nreal time",
            subtitle: "Know exactly when your provider is on the way. Chat, track, and pay — all in one place.",
            background: Color(hex: "#0f3460")
        )
    ]
}

#Preview {
    OnboardingView(onFinished: {})
}
