import SwiftUI

// MARK: - Shimmer modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0),   location: 0.0),
                            .init(color: Color.white.opacity(0.55), location: 0.5),
                            .init(color: Color.white.opacity(0),   location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                    .blendMode(.screen)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Reusable skeleton blocks

/// Generic rounded rectangle placeholder — matches the shape of the real content.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(hex: "#e8e8e8"))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Skeleton Cards (match real cards visually)

/// Matches ProviderRowView layout (Home "Recommended" section)
struct SkeletonProviderRow: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonBlock(width: 68, height: 68, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 140, height: 14)
                SkeletonBlock(width: 90,  height: 11)
                SkeletonBlock(width: 60,  height: 11)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

/// Matches CategoryPillView layout (Home "Top Services" section)
struct SkeletonCategoryPill: View {
    var body: some View {
        VStack(spacing: 8) {
            SkeletonBlock(width: 48, height: 48, cornerRadius: 14)
            SkeletonBlock(width: 52, height: 10, cornerRadius: 5)
        }
        .padding(.horizontal, 8)
    }
}

/// Matches FeaturedCardView (Home "Featured" section)
struct SkeletonFeaturedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonBlock(height: 150, cornerRadius: 14)
            SkeletonBlock(width: 160, height: 14)
            SkeletonBlock(width: 90,  height: 11)
        }
        .padding(.horizontal, 20)
    }
}

/// Matches ProviderListRow (ServicesView provider list)
struct SkeletonProviderListRow: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonBlock(width: 60, height: 60, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 130, height: 14)
                SkeletonBlock(width: 80,  height: 11)
                SkeletonBlock(width: 55,  height: 10)
            }
            Spacer()
            SkeletonBlock(width: 50, height: 24, cornerRadius: 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

/// Matches OrderCardView (OrdersView)
struct SkeletonOrderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SkeletonBlock(width: 52, height: 52, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBlock(width: 140, height: 14)
                    SkeletonBlock(width: 90,  height: 11)
                }
                Spacer()
                SkeletonBlock(width: 60, height: 22, cornerRadius: 6)
            }
            SkeletonBlock(height: 1, cornerRadius: 0)
                .opacity(0.5)
            HStack {
                SkeletonBlock(width: 80, height: 11)
                Spacer()
                SkeletonBlock(width: 50, height: 11)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(hex: "#eeeeee"), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}
