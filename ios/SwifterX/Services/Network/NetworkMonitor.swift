import Network
import Combine
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isExpensive: Bool = false   // cellular / hotspot

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.swifterx.network", qos: .background)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = self.isConnected
                self.isConnected  = path.status == .satisfied
                self.isExpensive  = path.isExpensive

                if wasConnected && !self.isConnected {
                    AnalyticsManager.shared.log("Network: went offline")
                } else if !wasConnected && self.isConnected {
                    AnalyticsManager.shared.log("Network: restored")
                    RetryQueue.shared.flush()
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - Offline banner

struct OfflineBanner: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var visible = false

    var body: some View {
        VStack(spacing: 0) {
            if visible {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 13, weight: .semibold))
                    Text("You're offline — showing cached data")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: visible)
        .onChange(of: networkMonitor.isConnected) { connected in
            if !connected {
                visible = true
            } else {
                // Show "back online" briefly then hide
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { visible = false }
            }
        }
    }
}

// MARK: - ViewModifier helper

extension View {
    func offlineBanner() -> some View {
        VStack(spacing: 0) {
            OfflineBanner()
            self
        }
    }
}
