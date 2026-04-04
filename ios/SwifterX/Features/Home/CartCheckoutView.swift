import SwiftUI

struct CartCheckoutView: View {
    @StateObject private var cart        = CartStore.shared
    @StateObject private var promoService = PromoCodeService.shared
    @EnvironmentObject private var dataService:  DataService
    @EnvironmentObject private var orderManager: OrderManager
    @EnvironmentObject private var authManager:  AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager
    @EnvironmentObject private var checkoutPayment: CheckoutPaymentCoordinator
    @EnvironmentObject private var notificationFeed: NotificationFeedStore
    @Environment(\.dismiss) private var dismiss

    @State private var loggedPromoCodeForFeed: String? = nil
    @State private var selectedDate:         Date   = Date()
    @State private var selectedTime:         String = ""
    @State private var specialInstructions:  String = ""
    @State private var availableSlots:       [String] = []
    @State private var isLoadingSlots        = false
    @State private var isPlacingOrder        = false
    @State private var showConfirmation      = false
    @State private var orderError:           String? = nil
    @State private var promoInput:           String = ""

    private var discountAmount: Double {
        if case .valid(let d, _) = promoService.promoState { return d }
        return 0
    }
    private var finalTotal: Double { max(0, cart.total - discountAmount) }

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
                    promoSection
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
                Text("Your booking has been confirmed with \(cart.provider?.name ?? "the provider"). You'll receive an update shortly.")
            }
            .alert("Order Failed", isPresented: .constant(orderError != nil)) {
                Button("OK") { orderError = nil }
            } message: {
                Text(orderError ?? "")
            }
        }
        .task(id: selectedDate) {
            await loadSlots()
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

            DatePicker("", selection: $selectedDate,
                       in: Date()...,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.black)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .onChange(of: selectedDate) { _ in selectedTime = "" }
        }
    }

    // MARK: - Time Slots

    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                if isLoadingSlots {
                    ProgressView().scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableSlots, id: \.self) { slot in
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
        NavigationLink { PersonalInfoView() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal information")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    if let profile = profileManager.profile, !profile.fullAddress.isEmpty {
                        Text(profile.fullAddress)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "828282"))
                    } else {
                        Text("Add your address")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "cc3333"))
                    }
                    if let phone = profileManager.profile?.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "828282"))
                    }
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
                .sanitized($specialInstructions, using: InputSanitizer.specialInstructions)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Payment

    private var paymentSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment method")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                if StripeConfig.isLivePaymentsEnabled {
                    Text("Card / Apple Pay via Stripe")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "828282"))
                } else {
                    Text(StripeConfig.canSimulatePaidCheckoutWithoutStripe
                         ? "Dev mode — no charge (add StripePublishableKey + Cloud Functions for live pay)"
                         : "Payments are not configured for this build.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "828282"))
                }
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "828282"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Promo Code

    private var promoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Promo code")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)

            HStack(spacing: 10) {
                TextField("Enter code", text: $promoInput)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color(hex: "f6f6f6"))
                    .cornerRadius(8)
                    .sanitized($promoInput, using: InputSanitizer.promoCode)

                Button {
                    let cleanCode = InputSanitizer.promoCode(promoInput)
                    Task { await promoService.validate(code: cleanCode, subtotal: cart.subtotal) }
                } label: {
                    Group {
                        if case .loading = promoService.promoState {
                            ProgressView().tint(.white)
                        } else {
                            Text("Apply")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 72, height: 42)
                    .background(Color.black)
                    .cornerRadius(8)
                }
                .disabled(promoInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // State feedback
            switch promoService.promoState {
            case .valid(_, let desc):
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("\(desc) applied!").foregroundColor(.green)
                }
                .font(.system(size: 13))
            case .invalid(let msg):
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text(msg).foregroundColor(.red)
                }
                .font(.system(size: 13))
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .onChange(of: promoService.promoState) { _, newState in
            if case .valid(_, let desc) = newState,
               let code = promoService.validatedPromo?.code,
               loggedPromoCodeForFeed != code {
                loggedPromoCodeForFeed = code
                Task { await notificationFeed.logPromoApplied(code: code, savingsDescription: desc) }
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Summary")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            SummaryRow(label: "subtotal",            amount: cart.subtotal)
            SummaryRow(label: "fee & estimated tax", amount: cart.fee)
            if discountAmount > 0 {
                SummaryRow(label: "promo discount", amount: -discountAmount)
            }
            Divider().padding(.vertical, 8)
            HStack {
                Text("total")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text("$\(String(format: "%.2f", finalTotal))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Place Order

    private var checkoutPaymentsConfigured: Bool {
        StripeConfig.isLivePaymentsEnabled || StripeConfig.canSimulatePaidCheckoutWithoutStripe
    }

    private var placeOrderButton: some View {
        Button {
            guard !selectedTime.isEmpty else { return }
            Task { await submitOrder() }
        } label: {
            HStack {
                Spacer()
                if isPlacingOrder {
                    ProgressView().tint(.white)
                } else {
                    Text(placeOrderButtonTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(placeOrderButtonBackground)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .disabled(selectedTime.isEmpty || isPlacingOrder || !checkoutPaymentsConfigured)
    }

    private var placeOrderButtonTitle: String {
        if !checkoutPaymentsConfigured {
            return "Payments unavailable — update the app"
        }
        if selectedTime.isEmpty {
            return "Select a time to continue"
        }
        return "Place Order  •  $\(String(format: "%.2f", finalTotal))"
    }

    private var placeOrderButtonBackground: Color {
        if selectedTime.isEmpty || !checkoutPaymentsConfigured { return Color.gray }
        return Color.black
    }

    // MARK: - Helpers

    private func loadSlots() async {
        guard let provider = cart.provider else { return }
        isLoadingSlots = true
        availableSlots = await dataService.fetchAvailability(for: provider.id, on: selectedDate)
        isLoadingSlots = false
    }

    private func submitOrder() async {
        guard let uid = authManager.userUID else { return }
        isPlacingOrder = true
        cart.selectedDate         = selectedDate
        cart.selectedTime         = selectedTime
        cart.specialInstructions  = specialInstructions
        let useStripe = StripeConfig.isLivePaymentsEnabled
        if !useStripe && !StripeConfig.canSimulatePaidCheckoutWithoutStripe {
            orderError = StripeConfig.checkoutBlockedMessage
            isPlacingOrder = false
            return
        }
        let checkoutTrace = PerformanceTracer(name: "checkout_flow")
        do {
            let order = try await orderManager.placeOrder(from: cart, uid: uid, useLiveStripe: useStripe)
            if useStripe, let pk = StripeConfig.publishableKey {
                let clientSecret = try await checkoutPayment.fetchPaymentIntentClientSecret(orderId: order.id)
                let completed = try await checkoutPayment.presentPaymentSheet(
                    clientSecret: clientSecret,
                    publishableKey: pk
                )
                guard completed else {
                    orderError = "Payment was canceled. Your order is still pending—you can pay again from Orders when supported."
                    isPlacingOrder = false
                    return
                }
                try await checkoutPayment.confirmOrderPayment(orderId: order.id)
            }
            // Redeem promo if applied
        if let promo = promoService.validatedPromo {
            AnalyticsManager.shared.logPromoApplied(code: promo.code, discountAmount: discountAmount)
            promoService.redeem(code: promo.code)
            promoService.reset()
        }
        checkoutTrace?.stop()
        showConfirmation = true
        } catch {
            checkoutTrace?.stop()
            AnalyticsManager.shared.recordError(error, context: "submitOrder")
            orderError = error.localizedDescription
        }
        isPlacingOrder = false
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
                .foregroundColor(amount < 0 ? Color.green : Color(hex: "828282"))
            Spacer()
            Text(amount < 0
                 ? "-$\(String(format: "%.2f", abs(amount)))"
                 : "$\(String(format: "%.2f", amount))")
                .font(.system(size: 14))
                .foregroundColor(amount < 0 ? .green : .black)
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
        .environmentObject(DataService(client: MockAPIClient.shared))
        .environmentObject(OrderManager())
        .environmentObject(AuthManager())
        .environmentObject(UserProfileManager())
        .environmentObject(CheckoutPaymentCoordinator())
        .environmentObject(NotificationFeedStore.shared)
}
