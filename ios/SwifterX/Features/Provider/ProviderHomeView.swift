import SwiftUI
import MapKit

struct ProviderHomeView: View {
    @EnvironmentObject private var orderManager:   OrderManager
    @EnvironmentObject private var authManager:    AuthManager
    @EnvironmentObject private var providerProfileManager: ProviderProfileManager
    @EnvironmentObject private var locationManager: LocationManager
    @State private var showInbox = false
    @State private var selectedInboxJob: ServiceOrder? = nil
    @State private var actionError: String? = nil
    @State private var isActioning = false
    @State private var showChat = false
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    private var activeJob: ServiceOrder? {
        orderManager.myJobs.first { $0.status == .inProgress }
    }
    private var nextConfirmedJob: ServiceOrder? {
        orderManager.myJobs.first { $0.status == .confirmed }
    }
    private var currentJob: ServiceOrder? { activeJob ?? nextConfirmedJob }
    private var uid: String { authManager.userUID ?? "" }

    /// Onboarded but operator has not set `approved` yet — cannot claim jobs (enforced in rules).
    private var pendingApproval: Bool {
        guard let p = providerProfileManager.profile else { return false }
        return p.isOnboarded && !p.isApprovedForJobs
    }

    private var rejectionReasonText: String? {
        guard pendingApproval else { return nil }
        return providerProfileManager.profile?.trimmedRejectionReason
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInbox) {
            InboxSheet(onAccept: { job in
                Task { await acceptJob(job) }
            })
            .environmentObject(orderManager)
        }
        .sheet(item: $selectedInboxJob) { job in
            JobDetailSheet(job: job, uid: uid, onAccept: {
                Task { await acceptJob(job) }
            })
        }
        .alert("Error", isPresented: .constant(actionError != nil)) {
            Button("OK") { actionError = nil }
        } message: { Text(actionError ?? "") }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            // Real device location
            if let loc = locationManager.location {
                Annotation("You", coordinate: loc.coordinate) {
                    Circle()
                        .fill(Color.blue.opacity(0.25))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().fill(.blue).frame(width: 11, height: 11))
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .onChange(of: locationManager.location) { loc in
            if let loc {
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            if !orderManager.inboxOrders.isEmpty && !pendingApproval {
                Button { showInbox = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(orderManager.inboxOrders.count) Available Job\(orderManager.inboxOrders.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.black)
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.top, 56)
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Card

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let job = currentJob {
                activeJobCard(job)
            } else if pendingApproval {
                if let reason = rejectionReasonText {
                    rejectionCard(reason: reason)
                } else {
                    underReviewCard
                }
            } else if orderManager.isLoadingProviderJobs {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, 40)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 14, y: -4)
    }

    // MARK: - Active Job Card

    private func activeJobCard(_ job: ServiceOrder) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#d0d0d0"))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(job.providerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                    Text(job.services.map(\.name).joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#828282"))
                        .lineLimit(1)
                }
                Spacer()
                // Chat with customer
                Button { showChat = true } label: {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Chat with customer")
                .padding(.trailing, 10)
                statusPill(job.status)
            }
            .padding(.horizontal, 20)
            .sheet(isPresented: $showChat) {
                if let job = currentJob {
                    NavigationStack {
                        ChatView(
                            orderID:     job.id,
                            orderTitle:  "Order #\(job.id.prefix(6).uppercased())",
                            currentUID:  uid,
                            currentName: "Provider",
                            isProvider:  true
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#828282"))
                Text(job.date + (job.scheduledTime.isEmpty ? "" : " • \(job.scheduledTime)"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#828282"))
                Spacer()
                Text("$\(Int(job.price))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            if !job.specialInstructions.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#828282"))
                    Text(job.specialInstructions)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#828282"))
                        .lineLimit(2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }

            // Services list
            VStack(spacing: 0) {
                Divider().padding(.horizontal, 20).padding(.top, 14)
                ForEach(job.services) { svc in
                    HStack {
                        Text(svc.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                        Spacer()
                        Text("$\(Int(svc.price))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    Divider().padding(.horizontal, 20)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if job.status == .confirmed {
                    Button {
                        Task { await releaseJob(job) }
                    } label: {
                        Text("Release")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#cc3333"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "#fff0f0"))
                            .cornerRadius(10)
                    }

                    Button {
                        Task { await startJob(job) }
                    } label: {
                        if isActioning {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Text("Start Job")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 13)
                    .background(Color.black)
                    .cornerRadius(10)
                    .disabled(isActioning)
                } else {
                    Button {
                        Task { await completeJob(job) }
                    } label: {
                        if isActioning {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Label("Mark Complete", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 14)
                    .background(Color(hex: "#20a655"))
                    .cornerRadius(10)
                    .disabled(isActioning)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Under review / rejection (approval gate)

    private func rejectionCard(reason: String) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#d0d0d0"))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "#ca8a04"))
            Text("Profile not approved")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black)
            Text(reason)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#444444"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Text("Update your profile if needed, or contact support if you have questions.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#828282"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
    }

    private var underReviewCard: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#d0d0d0"))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Image(systemName: "hourglass")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "#888888"))
            Text("Under review")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black)
            Text("Your profile is being verified. You will be able to accept paid jobs once SwifterX approves your account.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#828282"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 34))
                .foregroundStyle(Color(hex: "#bbbbbb"))
            Text("No active jobs")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
            Text(orderManager.inboxOrders.isEmpty
                 ? "You're all caught up. New jobs will appear here."
                 : "Tap 'Available Jobs' above to claim a job.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#828282"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
    }

    // MARK: - Status Pill

    private func statusPill(_ status: ServiceOrder.OrderStatus) -> some View {
        Text(status.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.12))
            .cornerRadius(6)
    }

    private func statusColor(_ status: ServiceOrder.OrderStatus) -> Color {
        switch status {
        case .pending:    return Color(hex: "#f59e0b")
        case .confirmed:  return Color(hex: "#3b82f6")
        case .inProgress: return Color(hex: "#20a655")
        case .completed:  return Color(hex: "#828282")
        case .cancelled:  return Color(hex: "#cc3333")
        }
    }

    // MARK: - Actions

    private func acceptJob(_ job: ServiceOrder) async {
        isActioning = true
        do {
            try await orderManager.acceptOrder(job, providerUID: uid)
            showInbox = false
            selectedInboxJob = nil
        } catch {
            actionError = error.localizedDescription
        }
        isActioning = false
    }

    private func releaseJob(_ job: ServiceOrder) async {
        isActioning = true
        do { try await orderManager.releaseOrder(job, providerUID: uid) }
        catch { actionError = error.localizedDescription }
        isActioning = false
    }

    private func startJob(_ job: ServiceOrder) async {
        isActioning = true
        do {
            try await orderManager.startJob(job, providerUID: uid)
            // Begin streaming live location to this order's document
            locationManager.startSharing(orderID: job.id)
        } catch { actionError = error.localizedDescription }
        isActioning = false
    }

    private func completeJob(_ job: ServiceOrder) async {
        isActioning = true
        do {
            try await orderManager.completeJob(job, providerUID: uid)
            locationManager.stopSharing()
        } catch { actionError = error.localizedDescription }
        isActioning = false
    }
}

// MARK: - Inbox Sheet

private struct InboxSheet: View {
    @EnvironmentObject private var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    let onAccept: (ServiceOrder) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if orderManager.inboxOrders.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "#cccccc"))
                        Text("Inbox is empty")
                            .font(.system(size: 16, weight: .semibold))
                        Text("No new jobs available right now.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#828282"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(orderManager.inboxOrders) { job in
                                InboxJobRow(job: job, onAccept: { onAccept(job) })
                                Divider().padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .background(Color.white)
            .navigationTitle("Available Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(.black)
                }
            }
        }
    }
}

private struct InboxJobRow: View {
    let job: ServiceOrder
    let onAccept: () -> Void
    @State private var isAccepting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.providerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                    Text(job.services.map(\.name).joined(separator: " • "))
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#828282"))
                        .lineLimit(1)
                }
                Spacer()
                Text("$\(Int(job.price))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
            }

            HStack(spacing: 16) {
                Label(job.date + (job.scheduledTime.isEmpty ? "" : " • \(job.scheduledTime)"),
                      systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#828282"))
                Spacer()
            }

            Button {
                isAccepting = true
                onAccept()
            } label: {
                Group {
                    if isAccepting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Accept Job")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.black)
                .cornerRadius(8)
            }
            .disabled(isAccepting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct JobDetailSheet: View {
    let job: ServiceOrder
    let uid: String
    let onAccept: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(job.providerName)
                            .font(.system(size: 20, weight: .bold))
                        Text(job.date + (job.scheduledTime.isEmpty ? "" : " at \(job.scheduledTime)"))
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#828282"))
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Services")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal, 20)
                        ForEach(job.services) { svc in
                            HStack {
                                Text(svc.name)
                                    .font(.system(size: 15))
                                Spacer()
                                Text("$\(Int(svc.price))")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Total Payout")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text("$\(Int(job.price))")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding(.horizontal, 20)

                    if !job.specialInstructions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Customer Note")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#828282"))
                            Text(job.specialInstructions)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 20)
                    }

                    Button {
                        onAccept()
                        dismiss()
                    } label: {
                        Text("Accept Job")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .background(Color.white)
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(.black)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ProviderHomeView() }
        .environmentObject(OrderManager())
        .environmentObject(AuthManager())
        .environmentObject(ProviderProfileManager.shared)
        .environmentObject(LocationManager.shared)
}
