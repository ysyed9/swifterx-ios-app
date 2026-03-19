import SwiftUI

struct CartCheckoutView: View {
    @StateObject private var cart = CartStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: String = ""
    @State private var specialInstructions: String = ""
    @State private var showConfirmation = false

    private let timeSlots = ["9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    providerHeader
                    Divider()
                    cartItemsSection
                    Divider()
                    datePickerSection
                    Divider()
                    timeSlotsSection
                    Divider()
                    personalInfoSection
                    Divider()
                    instructionsSection
                    Divider()
                    paymentSection
                    Divider()
                    summarySection
                    Divider()
                    placeOrderButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Checkout")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .alert("Order Placed!", isPresented: $showConfirmation) {
                Button("Done") {
                    cart.clear()
                    dismiss()
                }
            } message: {
                Text("Your booking has been confirmed. You'll receive a confirmation shortly.")
            }
        }
    }

    // MARK: - Provider Header

    private var providerHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "f6f6f6"))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(cart.provider?.name ?? "Provider")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                Text("\(cart.items.count) service\(cart.items.count == 1 ? "" : "s") • $\(Int(cart.subtotal))")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "828282"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Cart Items

    private var cartItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Cart summary")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            ForEach(cart.items) { item in
                VStack(spacing: 0) {
                    HStack {
                        Text(item.service.name)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        Spacer()
                        Text("$\(Int(item.service.price))")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    Divider().padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Date Picker

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Select date")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Text(formattedDate(selectedDate))
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "828282"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.black)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Time Slots

    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select time")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timeSlots, id: \.self) { slot in
                        TimeChip(time: slot, isSelected: selectedTime == slot) {
                            selectedTime = slot
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        NavigationLink {
            PersonalInfoView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal information")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Text("555 N St, apt 24 • Austin, TX 45667")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "828282"))
                    Text("(555) 123-4567")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "828282"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Special Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add special instructions (optional)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)

            TextField("Type here...", text: $specialInstructions, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .padding(12)
                .background(Color(hex: "f6f6f6"))
                .cornerRadius(8)
                .lineLimit(3...5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Payment

    private var paymentSection: some View {
        Button {} label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment method")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Text("Debit •••• 0000")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "828282"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Summary")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            SummaryRow(label: "subtotal", amount: cart.subtotal)
            SummaryRow(label: "fee & estimated tax", amount: cart.fee)
            Divider().padding(.vertical, 8)
            HStack {
                Text("total")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text("$\(String(format: "%.2f", cart.total))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Place Order

    private var placeOrderButton: some View {
        Button {
            guard !selectedTime.isEmpty else { return }
            showConfirmation = true
        } label: {
            HStack {
                Spacer()
                Text(selectedTime.isEmpty ? "Select a time to continue" : "Place Order  •  $\(String(format: "%.2f", cart.total))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(selectedTime.isEmpty ? Color.gray : Color.black)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .disabled(selectedTime.isEmpty)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Supporting Views

private struct TimeChip: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(hex: "f6f6f6"))
                .cornerRadius(20)
        }
    }
}

private struct SummaryRow: View {
    let label: String
    let amount: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "828282"))
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: 14))
                .foregroundColor(.black)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    let cart = CartStore.shared
    cart.provider = MockData.providers[0]
    let services = MockData.serviceItems(for: "Plumbing")
    cart.items = [CartItem(service: services[0]), CartItem(service: services[1])]
    return CartCheckoutView()
}
