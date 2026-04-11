import SwiftUI

// MARK: - DisputeView
// Bottom sheet shown from OrderDetailView.
// Allows the customer to pick a reason, describe the issue, and optionally
// request a refund. Submitted disputes land in Firestore → onDisputeCreated
// Cloud Function handles triage.

struct DisputeView: View {
    let order: ServiceOrder
    let customerUID: String
    let onSubmitted: (Dispute) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DisputeService.shared

    @State private var selectedReason: Dispute.DisputeReason = .noShow
    @State private var description: String = ""
    @State private var requestRefund: Bool = false
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showConfirmation = false

    private var canRequestRefund: Bool {
        order.paymentStatus == .paid || order.paymentStatus == .processing
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Order context card
                    orderCard
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Section: Reason
                    sectionHeader("What went wrong?")
                    reasonPicker
                        .padding(.horizontal, 20)

                    // Section: Description
                    sectionHeader("Describe the issue")
                    descriptionEditor
                        .padding(.horizontal, 20)

                    // Section: Refund toggle (only if order was paid)
                    if canRequestRefund {
                        sectionHeader("Resolution")
                        refundToggle
                            .padding(.horizontal, 20)
                    }

                    // Policy note
                    policyNote
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Submit button
                    submitButton
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(hex: "#f7f7f7"))
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.black)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
        .sheet(isPresented: $showConfirmation) {
            DisputeConfirmationView(
                reason: selectedReason,
                refundRequested: requestRefund && canRequestRefund
            )
        }
    }

    // MARK: - Order context card

    private var orderCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#e8e8e8"))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#666666"))
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(order.providerName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                Text(order.date + (order.scheduledTime.isEmpty ? "" : " · \(order.scheduledTime)"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#888888"))
            }
            Spacer()
            Text(String(format: "$%.2f", order.price))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .padding(.bottom, 8)
    }

    // MARK: - Reason picker

    private var reasonPicker: some View {
        VStack(spacing: 0) {
            ForEach(Dispute.DisputeReason.allCases) { reason in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedReason = reason }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(selectedReason == reason ? Color.black : Color(hex: "#efefef"))
                                .frame(width: 36, height: 36)
                            Image(systemName: reason.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(selectedReason == reason ? .white : Color(hex: "#666666"))
                        }
                        Text(reason.label)
                            .font(.system(size: 15, weight: selectedReason == reason ? .semibold : .regular))
                            .foregroundStyle(.black)
                        Spacer()
                        if selectedReason == reason {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if reason != Dispute.DisputeReason.allCases.last {
                    Divider().padding(.leading, 66)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Description editor

    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $description)
                .frame(minHeight: 110, maxHeight: 160)
                .font(.system(size: 15))
                .foregroundStyle(.black)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                .sanitized($description, using: InputSanitizer.reviewComment)
                .overlay(alignment: .topLeading) {
                    if description.isEmpty {
                        Text(selectedReason.descriptionHint)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Spacer()
                Text("\(description.count) / \(FieldLimit.reviewComment)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
            }
        }
    }

    // MARK: - Refund toggle

    private var refundToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Request a refund")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                Text("Ask SwifterX to refund \(String(format: "$%.2f", order.price)) to your original payment method.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#888888"))
                    .lineSpacing(2)
            }
            Spacer(minLength: 16)
            Toggle("", isOn: $requestRefund)
                .labelsHidden()
                .tint(.black)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Policy note

    private var policyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#888888"))
                .padding(.top, 1)
            Text("Disputes are reviewed within 1–3 business days. Refunds for eligible cases are processed within 5–10 business days to your original payment method. Submitting a false dispute may result in account suspension.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#888888"))
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color(hex: "#f0f0f0"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Submit button

    private var submitButton: some View {
        Button {
            Task { await submitDispute() }
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 15))
                    Text("Submit Dispute")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
                        ? Color.black : Color(hex: "#cccccc"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isSubmitting || description.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
        .accessibilityLabel("Submit dispute")
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(hex: "#888888"))
            .tracking(0.5)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    // MARK: - Action

    private func submitDispute() async {
        isSubmitting = true
        errorMessage = nil
        do {
            let dispute = try await service.submit(
                order: order,
                customerUID: customerUID,
                reason: selectedReason,
                description: description,
                refundRequested: requestRefund && canRequestRefund
            )
            isSubmitting = false
            showConfirmation = true
            onSubmitted(dispute)
        } catch DisputeService.DisputeError.alreadyFiled(let existing) {
            isSubmitting = false
            onSubmitted(existing)
            dismiss()
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - DisputeConfirmationView

struct DisputeConfirmationView: View {
    let reason: Dispute.DisputeReason
    let refundRequested: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#f0fdf4"))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "#22c55e"))
                }

                VStack(spacing: 10) {
                    Text("Dispute Submitted")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                    Text(refundRequested
                         ? "We've received your dispute and refund request. Our team will review it within 1–3 business days and notify you of the outcome."
                         : "We've received your dispute. Our team will review it within 1–3 business days and contact you with next steps.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#555555"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 8)

                // What happens next
                VStack(alignment: .leading, spacing: 14) {
                    nextStep(icon: "magnifyingglass", title: "Review", body: "Our team investigates the claim with the provider.")
                    nextStep(icon: "envelope", title: "Decision", body: "You'll receive an in-app notification with the outcome.")
                    if refundRequested {
                        nextStep(icon: "banknote", title: "Refund", body: "Approved refunds reach your account in 5–10 business days.")
                    }
                }
                .padding(18)
                .background(Color(hex: "#f7f7f7"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(28)
            Spacer()
        }
        .background(Color.white)
    }

    private func nextStep(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#e8e8e8"))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#666666"))
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - DisputeStatusBadge
// Reusable badge shown in OrderDetailView when a dispute exists.

struct DisputeStatusBadge: View {
    let dispute: Dispute

    private var color: Color {
        switch dispute.status {
        case .submitted, .reviewing: return Color(hex: "#f59e0b")
        case .resolved, .refunded:   return Color(hex: "#22c55e")
        case .rejected:              return Color(hex: "#888888")
        }
    }

    private var icon: String {
        switch dispute.status {
        case .submitted, .reviewing: return "clock.fill"
        case .resolved:              return "checkmark.circle.fill"
        case .refunded:              return "arrow.uturn.left.circle.fill"
        case .rejected:              return "xmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("Dispute \(dispute.status.label)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                if let resolution = dispute.resolution {
                    Text(resolution)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#666666"))
                } else {
                    Text("Reason: \(dispute.reason.label)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#888888"))
                }
            }
            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}
