import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var orderManager: OrderManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    Text("Past Orders")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.black)
                        if !orderManager.orders.isEmpty {
                            Circle()
                                .fill(.black)
                                .frame(width: 13, height: 13)
                                .overlay(
                                    Text("\(min(orderManager.orders.count, 9))")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 6, y: -4)
                        }
                    }
                    .padding(.trailing, 12)

                    Image(systemName: "cart")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if orderManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if orderManager.orders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "#cccccc"))
                        Text("No orders yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("Book a service to get started.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#828282"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(orderManager.orders) { order in
                            NavigationLink(destination: OrderDetailView(order: order)) {
                                OrderCardView(order: order)
                            }
                            .buttonStyle(.plain)
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                }

                Spacer().frame(height: 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

private struct OrderCardView: View {
    let order: ServiceOrder
    @EnvironmentObject private var dataService: DataService
    @State private var bookAgainProvider: ServiceProvider? = nil

    private var matchedProvider: ServiceProvider? {
        dataService.providers.first { $0.id == order.providerID }
            ?? dataService.providers.first { $0.name == order.providerName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "#dbdbdb"))
                    .overlay {
                        if let p = matchedProvider, !p.imageName.isEmpty {
                            Image(p.imageName).resizable().scaledToFill()
                        } else if let urlStr = matchedProvider?.imageURL, !urlStr.isEmpty,
                                  let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase { img.resizable().scaledToFill() }
                                else { Image(systemName: "person.fill").font(.system(size: 24)).foregroundStyle(Color(hex: "#999999")) }
                            }
                        } else {
                            Image(systemName: "person.fill").font(.system(size: 24)).foregroundStyle(Color(hex: "#999999"))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.providerName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("$\(Int(order.price))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: "#828282"))
                    HStack(spacing: 4) {
                        Text(order.date)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#828282"))
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#828282"))
                        Text(order.status.label)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(statusColor(order.status))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black)
            }

            let visible = order.services
            if !visible.isEmpty {
                let pairs = stride(from: 0, to: visible.count, by: 2).map {
                    Array(visible[$0..<min($0 + 2, visible.count)])
                }
                VStack(spacing: 8) {
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: 8) {
                            ForEach(pair) { item in
                                ServiceChipView(name: item.name, price: item.price) {
                                    bookAgainProvider = matchedProvider
                                }
                            }
                            if pair.count == 1 { Spacer() }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(item: $bookAgainProvider) { provider in
            NavigationStack { ProviderDetailView(provider: provider) }
        }
    }

    private func statusColor(_ status: ServiceOrder.OrderStatus) -> Color {
        switch status {
        case .pending:    return Color(hex: "#f59e0b")
        case .confirmed:  return Color(hex: "#20a655")
        case .inProgress: return Color(hex: "#3b82f6")
        case .completed:  return Color(hex: "#828282")
        case .cancelled:  return Color(hex: "#cc3333")
        }
    }
}

private struct ServiceChipView: View {
    let name: String
    let price: Double
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black)
                    .textCase(.none)
                Text("$\(Int(price))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "#828282"))
            }
            Spacer()
            Button(action: onAdd) {
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.black)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#f6f6f6"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack { OrdersView() }
        .environmentObject(OrderManager())
        .environmentObject(DataService(client: MockAPIClient.shared))
}
