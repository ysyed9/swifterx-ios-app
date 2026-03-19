import SwiftUI

struct OrdersView: View {
    let orders = MockData.orders

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
                        Circle()
                            .fill(.black)
                            .frame(width: 13, height: 13)
                            .overlay(
                                Text("3")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 6, y: -4)
                    }
                    .padding(.trailing, 12)

                    Image(systemName: "cart")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Orders list
                VStack(spacing: 0) {
                    ForEach(orders) { order in
                        NavigationLink(destination: OrderDetailView(order: order)) {
                            OrderCardView(order: order)
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)

                Spacer().frame(height: 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

private struct OrderCardView: View {
    let order: ServiceOrder
    @State private var bookAgainProvider: ServiceProvider? = nil

    private var matchedProvider: ServiceProvider? {
        MockData.providers.first { $0.name == order.providerName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Provider info row
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "#dbdbdb"))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "#999999"))
                    )

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
                            .foregroundStyle(order.status == .reserved ? Color(hex: "#20a655") : Color(hex: "#828282"))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black)
            }

            // Services chips — "+" books that service again
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
}
