import SwiftUI

struct OrderDetailView: View {
    let order: ServiceOrder
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Provider card
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#dbdbdb"))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "#999999"))
                        )

                    VStack(alignment: .leading, spacing: 5) {
                        Text(order.providerName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                        HStack(spacing: 6) {
                            StatusBadge(status: order.status)
                            Text(order.date)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#828282"))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                Divider().padding(.horizontal, 20)

                // Services booked
                VStack(alignment: .leading, spacing: 8) {
                    Text("Services Booked")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.bottom, 4)

                    ForEach(order.services) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.black)
                            }
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

                // Actions
                VStack(spacing: 12) {
                    if order.status == .reserved {
                        Button {
                            showCancelAlert = true
                        } label: {
                            Text("Cancel Order")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    }

                    Button {
                        // Re-book (navigate back and open provider)
                        dismiss()
                    } label: {
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
        .alert("Cancel Order?", isPresented: $showCancelAlert) {
            Button("Keep Order", role: .cancel) {}
            Button("Cancel Order", role: .destructive) { dismiss() }
        } message: {
            Text("Are you sure you want to cancel this order with \(order.providerName)?")
        }
    }
}

private struct StatusBadge: View {
    let status: ServiceOrder.OrderStatus
    var color: Color {
        switch status {
        case .reserved:  return Color(hex: "#20a655")
        case .completed: return Color(hex: "#828282")
        case .canceled:  return Color(hex: "#cc3333")
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

#Preview {
    NavigationStack {
        OrderDetailView(order: MockData.orders[0])
    }
}
