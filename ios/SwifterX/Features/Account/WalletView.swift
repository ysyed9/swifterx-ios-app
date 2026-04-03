import SwiftUI

struct WalletView: View {
    @State private var showAddCard = false
    @State private var savedCards: [SavedCard] = SavedCard.load()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Banner
                    HStack(spacing: 14) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Payments")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Cards are processed securely via Stripe.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.black)
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                    // Apple Pay notice
                    HStack(spacing: 12) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 22))
                            .foregroundStyle(.black)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Pay")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                            Text("Available at checkout automatically")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#828282"))
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .padding(16)
                    .background(Color(hex: "#f6f6f6"))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                    // Saved cards
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Saved Cards")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)

                        if savedCards.isEmpty {
                            Text("No cards saved yet. Cards added during checkout appear here.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#828282"))
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(savedCards) { card in
                                CardRow(card: card) {
                                    withAnimation {
                                        savedCards.removeAll { $0.id == card.id }
                                        SavedCard.save(savedCards)
                                    }
                                }
                            }
                        }
                    }

                    // Add card button
                    Button { showAddCard = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Card")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.top, 16)
            }
            .background(Color.white)
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddCard) {
                AddCardSheet { nickname, last4, brand in
                    let card = SavedCard(nickname: nickname, last4: last4, brand: brand)
                    savedCards.append(card)
                    SavedCard.save(savedCards)
                }
            }
        }
    }
}

// MARK: - Supporting types

struct SavedCard: Identifiable, Codable {
    let id: String
    let nickname: String
    let last4: String
    let brand: String

    init(nickname: String, last4: String, brand: String) {
        self.id = UUID().uuidString
        self.nickname = nickname
        self.last4 = last4
        self.brand = brand
    }

    var brandIcon: String {
        switch brand.lowercased() {
        case "visa":       return "creditcard"
        case "mastercard": return "creditcard"
        case "amex":       return "creditcard"
        default:           return "creditcard"
        }
    }

    static func load() -> [SavedCard] {
        guard let data = UserDefaults.standard.data(forKey: "swifterx_saved_cards"),
              let cards = try? JSONDecoder().decode([SavedCard].self, from: data) else { return [] }
        return cards
    }

    static func save(_ cards: [SavedCard]) {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: "swifterx_saved_cards")
        }
    }
}

private struct CardRow: View {
    let card: SavedCard
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: card.brandIcon)
                .font(.system(size: 22))
                .foregroundStyle(.black)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.nickname.isEmpty ? card.brand : card.nickname)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                Text("•••• \(card.last4)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#828282"))
            }

            Spacer()

            Button(role: .destructive) { onRemove() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#f6f6f6"))
        .cornerRadius(10)
        .padding(.horizontal, 20)
    }
}

private struct AddCardSheet: View {
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var last4 = ""
    @State private var brand = "Visa"

    private let brands = ["Visa", "Mastercard", "Amex", "Discover", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Card details") {
                    TextField("Nickname (e.g. My Visa)", text: $nickname)
                    TextField("Last 4 digits", text: $last4)
                        .keyboardType(.numberPad)
                        .onChange(of: last4) { v in last4 = String(v.filter(\.isNumber).prefix(4)) }
                    Picker("Card brand", selection: $brand) {
                        ForEach(brands, id: \.self) { Text($0) }
                    }
                }
                Section {
                    Text("Actual card numbers are handled by Stripe and are never stored by SwifterX.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard last4.count == 4 else { return }
                        onSave(nickname, last4, brand)
                        dismiss()
                    }
                    .disabled(last4.count != 4)
                    .bold()
                }
            }
        }
    }
}

#Preview {
    WalletView()
}
