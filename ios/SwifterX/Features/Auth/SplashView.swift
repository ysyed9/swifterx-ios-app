import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.92

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 160)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .task {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82, blendDuration: 0)) {
                opacity = 1
                scale = 1
            }
            try? await Task.sleep(nanoseconds: 1_450_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.32)) {
                    opacity = 0
                    scale = 1.04
                }
            }
            try? await Task.sleep(nanoseconds: 320_000_000)
            await MainActor.run {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
