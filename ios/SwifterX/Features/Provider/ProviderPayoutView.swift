import SwiftUI
import SafariServices

// MARK: - ProviderPayoutView
// Shows earnings summary and Stripe Connect payout setup / dashboard.

struct ProviderPayoutView: View {
    @EnvironmentObject private var providerProfileManager: ProviderProfileManager
    @StateObject private var connectService = StripeConnectService.shared

    @State private var earnings: StripeConnectService.Earnings? = nil
    @State private var safariURL: URL? = nil
    @State private var showSafari = false
    @State private var errorMessage: String? = nil
    @State private var isActionLoading = false

    private var profile: ProviderProfile? { providerProfileManager.profile }
    private var payoutsEnabled: Bool { profile?.payoutsEnabled ?? false }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                earningsCard
                payoutSection
                Spacer().frame(height: 40)
            }
        }
        .background(Color(hex: "#f7f7f7"))
        .navigationBarHidden(true)
        .task { await loadEarnings() }
        .sheet(isPresented: $showSafari) {
            if let url = safariURL { SafariView(url: url) }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Payouts")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)
            Spacer()
            Image(systemName: "banknote")
                .font(.system(size: 20))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Earnings card

    private var earningsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Earnings Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
                if connectService.isLoading {
                    ProgressView().scaleEffect(0.8)
                }
            }

            if let e = earnings {
                VStack(spacing: 12) {
                    earningsRow(label: "Completed Jobs",  value: "\(e.completedJobs)")
                    Divider()
                    earningsRow(label: "Gross Earnings",  value: String(format: "$%.2f", e.grossEarnings))
                    earningsRow(label: "SwifterX fee (\(Int(e.feePercent))%)",
                                value: String(format: "-$%.2f", e.platformFee),
                                valueColor: Color(hex: "#e53e3e"))
                    Divider()
                    HStack {
                        Text("Your Earnings")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                        Text(String(format: "$%.2f", e.netEarnings))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 80)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, 22)
    }

    private func earningsRow(label: String, value: String, valueColor: Color = .black) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#666666"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Payout setup / dashboard

    private var payoutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payout Account")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)

            if payoutsEnabled {
                // Connected — show status + dashboard button
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("Connected to Stripe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#333333"))
                    Spacer()
                }

                Text("Funds are automatically transferred to your bank account after each completed job.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#888888"))

                actionButton(title: "View Payout Dashboard", icon: "arrow.up.right") {
                    await openDashboard()
                }
            } else if profile?.stripeConnectAccountId != nil {
                // Account exists but onboarding incomplete
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                    Text("Onboarding incomplete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#333333"))
                    Spacer()
                }
                Text("Complete the setup to start receiving payouts for your jobs.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#888888"))
                actionButton(title: "Complete Setup", icon: "arrow.up.right") {
                    await openOnboarding()
                }
            } else {
                // No account yet
                Text("Set up your bank account to receive payouts. SwifterX uses Stripe to securely process all transfers.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#888888"))
                    .lineSpacing(3)

                actionButton(title: "Set Up Payouts", icon: "creditcard") {
                    await setupAccount()
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, 22)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func actionButton(title: String, icon: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if isActionLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isActionLoading)
    }

    // MARK: - Actions

    private func loadEarnings() async {
        do { earnings = try await connectService.fetchEarnings() }
        catch { errorMessage = error.localizedDescription }
    }

    private func setupAccount() async {
        isActionLoading = true
        defer { isActionLoading = false }
        do {
            _ = try await connectService.createAccount()
            let url = try await connectService.onboardingURL()
            safariURL = url
            showSafari = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openOnboarding() async {
        isActionLoading = true
        defer { isActionLoading = false }
        do {
            let url = try await connectService.onboardingURL()
            safariURL = url
            showSafari = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openDashboard() async {
        isActionLoading = true
        defer { isActionLoading = false }
        do {
            let url = try await connectService.dashboardURL()
            safariURL = url
            showSafari = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - SafariView wrapper

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
