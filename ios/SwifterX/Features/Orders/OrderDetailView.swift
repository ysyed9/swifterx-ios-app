import SwiftUI

struct OrderDetailView: View {
    let order: ServiceOrder
    @EnvironmentObject private var orderManager:   OrderManager
    @EnvironmentObject private var authManager:    AuthManager
    @EnvironmentObject private var dataService:    DataService
    @EnvironmentObject private var profileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelAlert  = false
    @State private var isCancelling     = false
    @State private var cancelError:     String? = nil
    @State private var showReviewSheet  = false
    @State private var hasReviewed      = false
    @State private var isCheckingReview = true

    private var matchedProvider: ServiceProvider? {
        dataService.providers.first { $0.id == order.providerID }
            ?? dataService.providers.first { $0.name == order.providerName }
    }

    var canCancel: Bool {
        order.status == .pending || order.status == .confirmed
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Provider card
                HStack(spacing: 14) {
                    providerThumb
                        .frame(width: 70, height: 70)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(order.providerName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                        HStack(spacing: 6) {
                            StatusBadge(status: order.status)
                            Text(order.date)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#828282"))
                            if !order.scheduledTime.isEmpty {
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#828282"))
                                Text(order.scheduledTime)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#828282"))
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                // Status timeline
                OrderStatusTimeline(status: order.status)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                Divider().padding(.horizontal, 20)

                // Services booked
                VStack(alignment: .leading, spacing: 8) {
                    Text("Services Booked")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.bottom, 4)

                    ForEach(order.services) { item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 15))
                                .foregroundStyle(.black)
                            Spacer()
                            Text("$\(Int(item.price))")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                        }
                        .padding(.vertical, 10)
                        Divider()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Summary
                VStack(alignment: .leading, spacing: 0) {
                    Text("Summary")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.bottom, 12)

                    SummaryLine(label: "subtotal",            amount: order.price)
                    SummaryLine(label: "fee & estimated tax", amount: order.price * 0.01)

                    Divider().padding(.vertical, 8)

                    HStack {
                        Text("total")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                        Text("$\(String(format: "%.2f", order.price * 1.01))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                Divider()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Review prompt (completed orders only)
                if order.status == .completed {
                    reviewPromptCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }

                // Actions
                VStack(spacing: 12) {
                    if canCancel {
                        Button {
                            showCancelAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                if isCancelling {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Cancel Order")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .cornerRadius(8)
                        }
                        .disabled(isCancelling)
                    }

                    Button { dismiss() } label: {
                        Text("Book Again")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#f6f6f6"))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard order.status == .completed,
                  let uid = authManager.userUID,
                  !order.providerID.isEmpty else {
                isCheckingReview = false
                return
            }
            hasReviewed = await dataService.hasReview(
                orderID: order.id, providerID: order.providerID, uid: uid)
            isCheckingReview = false
        }
        .sheet(isPresented: $showReviewSheet) {
            ReviewSheet(
                order: order,
                provider: matchedProvider,
                customerName: profileManager.profile?.name ?? "",
                onSubmitted: { hasReviewed = true }
            )
            .environmentObject(dataService)
            .environmentObject(authManager)
        }
        .alert("Cancel Order?", isPresented: $showCancelAlert) {
            Button("Keep Order", role: .cancel) {}
            Button("Cancel Order", role: .destructive) {
                Task { await cancelOrder() }
            }
        } message: {
            Text("Are you sure you want to cancel this order with \(order.providerName)?")
        }
        .alert("Error", isPresented: .constant(cancelError != nil)) {
            Button("OK") { cancelError = nil }
        } message: {
            Text(cancelError ?? "")
        }
    }

    // MARK: - Review Prompt Card

    @ViewBuilder
    private var reviewPromptCard: some View {
        if isCheckingReview {
            EmptyView()
        } else if hasReviewed {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color(hex: "#22c55e"))
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review submitted")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Thank you for your feedback!")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#828282"))
                }
                Spacer()
            }
            .padding(16)
            .background(Color(hex: "#f0fdf4"))
            .cornerRadius(12)
        } else {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(hex: "#f59e0b"))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("How was your experience?")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("Rate your visit with \(order.providerName)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#828282"))
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { _ in
                        Image(systemName: "star")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "#f59e0b"))
                    }
                    Spacer()
                    Button {
                        showReviewSheet = true
                    } label: {
                        Text("Leave a Review")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "#fffbeb"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#fde68a"), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var providerThumb: some View {
        let p = matchedProvider
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(hex: "#dbdbdb"))
            .overlay {
                if let name = p?.imageName, !name.isEmpty {
                    Image(name).resizable().scaledToFill()
                } else if let urlStr = p?.imageURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFill() }
                        else { Image(systemName: "person.fill").font(.system(size: 28)).foregroundStyle(Color(hex: "#999999")) }
                    }
                } else {
                    Image(systemName: "person.fill").font(.system(size: 28)).foregroundStyle(Color(hex: "#999999"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func cancelOrder() async {
        guard let uid = authManager.userUID else { return }
        isCancelling = true
        do {
            try await orderManager.cancelOrder(order, uid: uid)
            dismiss()
        } catch {
            cancelError = error.localizedDescription
        }
        isCancelling = false
    }
}

private struct StatusBadge: View {
    let status: ServiceOrder.OrderStatus

    var color: Color {
        switch status {
        case .pending:    return Color(hex: "#f59e0b")
        case .confirmed:  return Color(hex: "#20a655")
        case .inProgress: return Color(hex: "#3b82f6")
        case .completed:  return Color(hex: "#828282")
        case .cancelled:  return Color(hex: "#cc3333")
        }
    }

    var body: some View {
        Text(status.label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

private struct SummaryLine: View {
    let label: String
    let amount: Double
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#828282"))
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 14))
                .foregroundStyle(.black)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Status Timeline

struct OrderStatusTimeline: View {
    let status: ServiceOrder.OrderStatus

    private let steps: [(ServiceOrder.OrderStatus, String, String)] = [
        (.pending,    "clock",              "Pending"),
        (.confirmed,  "checkmark.circle",   "Confirmed"),
        (.inProgress, "wrench.and.screwdriver", "In Progress"),
        (.completed,  "checkmark.seal.fill","Completed")
    ]

    private func stepIndex(_ s: ServiceOrder.OrderStatus) -> Int {
        switch s {
        case .pending:    return 0
        case .confirmed:  return 1
        case .inProgress: return 2
        case .completed:  return 3
        case .cancelled:  return -1
        }
    }

    var body: some View {
        if status == .cancelled {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(hex: "#cc3333"))
                Text("Order Cancelled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#cc3333"))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(hex: "#fff0f0"))
            .cornerRadius(8)
        } else {
            let current = stepIndex(status)
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    let done = i <= current
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(done ? Color.black : Color(hex: "#e8e8e8"))
                                .frame(width: 28, height: 28)
                            Image(systemName: step.1)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(done ? .white : Color(hex: "#bbbbbb"))
                        }
                        Text(step.2)
                            .font(.system(size: 10, weight: done ? .semibold : .regular))
                            .foregroundStyle(done ? .black : Color(hex: "#bbbbbb"))
                            .multilineTextAlignment(.center)
                    }
                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(i < current ? Color.black : Color(hex: "#e8e8e8"))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .offset(y: -10)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: MockData.orders[0])
    }
    .environmentObject(OrderManager())
    .environmentObject(AuthManager())
    .environmentObject(DataService(client: MockAPIClient.shared))
    .environmentObject(UserProfileManager())
}
