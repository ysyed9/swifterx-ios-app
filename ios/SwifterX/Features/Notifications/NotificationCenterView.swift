import SwiftUI

// MARK: - NotificationCenterView
// Lists persisted alerts from users/{uid}/notifications (order, chat, promo, dispute).

struct NotificationCenterView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var orderManager: OrderManager
    @EnvironmentObject private var notificationFeed: NotificationFeedStore
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var profileManager: UserProfileManager

    @State private var selectedOrder: ServiceOrder? = nil

    var body: some View {
        Group {
            if notificationFeed.items.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .background(Color(hex: "#f7f7f7"))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if notificationFeed.unreadCount > 0 {
                    Button("Mark all read") {
                        Task { await notificationFeed.markAllRead() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                }
            }
        }
        .sheet(item: $selectedOrder) { order in
            NavigationStack {
                OrderDetailView(order: order)
            }
            .environmentObject(orderManager)
            .environmentObject(authManager)
            .environmentObject(dataService)
            .environmentObject(profileManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#cccccc"))
            Text("No notifications yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)
            Text("Order updates, chat messages, and promos will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#888888"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(notificationFeed.items) { item in
                    notificationRow(item)
                    Divider().padding(.leading, 58)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func notificationRow(_ item: InAppNotificationItem) -> some View {
        Button {
            handleTap(item)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconBackground(for: item))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15, weight: item.read ? .medium : .bold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        if !item.read {
                            Circle()
                                .fill(Color(hex: "#2563eb"))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(item.body)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#666666"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)

                    HStack(spacing: 6) {
                        Text(item.category.label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "#999999"))
                        if let t = item.createdAt {
                            Text("·")
                                .foregroundStyle(Color(hex: "#cccccc"))
                            Text(Self.timeFormatter.string(from: t))
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#999999"))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task { await notificationFeed.delete(id: item.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if !item.read {
                Button {
                    Task { await notificationFeed.markRead(id: item.id) }
                } label: {
                    Label("Mark as read", systemImage: "checkmark.circle")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.body)")
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func iconBackground(for item: InAppNotificationItem) -> Color {
        switch item.category {
        case .order:   return Color(hex: "#e8f4ff")
        case .chat:    return Color(hex: "#f0fdf4")
        case .promo:   return Color(hex: "#fffbeb")
        case .dispute: return Color(hex: "#fef2f2")
        case .system:  return Color(hex: "#f3f4f6")
        }
    }

    private func orderForItem(_ item: InAppNotificationItem) -> ServiceOrder? {
        guard let oid = item.orderId else { return nil }
        if appState.userRole == .customer {
            return orderManager.customerOrders.first { $0.id == oid }
        }
        return orderManager.inboxOrders.first { $0.id == oid }
            ?? orderManager.myJobs.first { $0.id == oid }
    }

    private func handleTap(_ item: InAppNotificationItem) {
        Task { await notificationFeed.markRead(id: item.id) }

        guard item.orderId != nil else { return }

        if let order = orderForItem(item) {
            selectedOrder = order
            return
        }

        if appState.userRole == .customer {
            appState.activeTab = .orders
        } else {
            appState.providerActiveTab = .home
        }
    }
}
