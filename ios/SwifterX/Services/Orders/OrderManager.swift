import Foundation
import FirebaseFirestore
import FirebaseFunctions

// MARK: - OrderManager
// Manages orders for both customers (by customerUID) and providers (by providerUID).
// Inject as @EnvironmentObject; start the appropriate listener once the user signs in.

@MainActor
final class OrderManager: ObservableObject {

    // MARK: Customer
    @Published private(set) var orders: [ServiceOrder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil

    // MARK: Provider
    /// Available jobs in the inbox (confirmed + paid, not yet claimed by any provider).
    @Published private(set) var inboxOrders: [ServiceOrder] = []
    /// Jobs claimed by and assigned to the current provider.
    @Published private(set) var myJobs: [ServiceOrder] = []
    @Published private(set) var isLoadingProviderJobs = false

    private var customerListener: ListenerRegistration?
    private var inboxListener: ListenerRegistration?
    private var myJobsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let functions = Functions.functions()

    // MARK: - Customer Listener

    func startListening(uid: String) {
        customerListener?.remove()
        isLoading = true
        customerListener = db.collection("orders")
            .whereField("customerUID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if let error { self.errorMessage = error.localizedDescription; return }
                    self.orders = snapshot?.documents.compactMap { try? $0.data(as: ServiceOrder.self) } ?? []
                }
            }
    }

    func stopListening() {
        customerListener?.remove()
        customerListener = nil
        orders = []
        isLoading = false
    }

    // MARK: - Provider Listeners

    func startListeningAsProvider(uid: String) {
        stopListeningAsProvider()
        isLoadingProviderJobs = true

        // Inbox: confirmed + paid orders with no provider assigned yet
        inboxListener = db.collection("orders")
            .whereField("providerUID", isEqualTo: "")
            .whereField("status", isEqualTo: ServiceOrder.OrderStatus.confirmed.rawValue)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoadingProviderJobs = false
                    if error == nil {
                        self.inboxOrders = snapshot?.documents.compactMap { try? $0.data(as: ServiceOrder.self) } ?? []
                    }
                }
            }

        // My jobs: orders I've claimed (confirmed or in-progress)
        myJobsListener = db.collection("orders")
            .whereField("providerUID", isEqualTo: uid)
            .whereField("status", in: [
                ServiceOrder.OrderStatus.confirmed.rawValue,
                ServiceOrder.OrderStatus.inProgress.rawValue
            ])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if error == nil {
                        self.myJobs = snapshot?.documents.compactMap { try? $0.data(as: ServiceOrder.self) } ?? []
                    }
                }
            }
    }

    func stopListeningAsProvider() {
        inboxListener?.remove(); inboxListener = nil
        myJobsListener?.remove(); myJobsListener = nil
        inboxOrders = []
        myJobs = []
        isLoadingProviderJobs = false
    }

    // MARK: - Provider Actions

    /// Claim an inbox job — sets providerUID so no other provider can take it.
    func acceptOrder(_ order: ServiceOrder, providerUID: String) async throws {
        guard order.providerUID.isEmpty else { throw OrderError.alreadyClaimed }
        try await db.collection("orders").document(order.id).updateData([
            "providerUID": providerUID
        ])
    }

    /// Release a claimed job back to the inbox (before starting it).
    func releaseOrder(_ order: ServiceOrder, providerUID: String) async throws {
        guard order.providerUID == providerUID else { throw OrderError.unauthorized }
        try await db.collection("orders").document(order.id).updateData([
            "providerUID": ""
        ])
    }

    /// Mark the job as in-progress (provider is on-site / has started work).
    func startJob(_ order: ServiceOrder, providerUID: String) async throws {
        guard order.providerUID == providerUID else { throw OrderError.unauthorized }
        try await db.collection("orders").document(order.id).updateData([
            "status": ServiceOrder.OrderStatus.inProgress.rawValue
        ])
    }

    /// Mark the job as completed.
    func completeJob(_ order: ServiceOrder, providerUID: String) async throws {
        guard order.providerUID == providerUID else { throw OrderError.unauthorized }
        try await db.collection("orders").document(order.id).updateData([
            "status": ServiceOrder.OrderStatus.completed.rawValue
        ])
    }

    // MARK: - Place Order (Customer)

    @discardableResult
    func placeOrder(from cart: CartStore, uid: String, useLiveStripe: Bool) async throws -> ServiceOrder {
        let order = ServiceOrder(
            id: UUID().uuidString,
            customerUID: uid,
            providerID: cart.provider?.id ?? "",
            providerName: cart.provider?.name ?? "",
            price: cart.total,
            scheduledDate: cart.selectedDate,
            scheduledTime: cart.selectedTime,
            status: useLiveStripe ? .pending : .confirmed,
            services: cart.items.map { OrderLineItem(name: $0.service.name, price: $0.service.price) },
            specialInstructions: cart.specialInstructions,
            createdAt: Date(),
            paymentStatus: useLiveStripe ? .unpaid : .paid,
            stripePaymentIntentId: nil,
            providerUID: ""
        )
        try await db.collection("orders").document(order.id).setData(from: order)
        return order
    }

    // MARK: - Cancel Order (Customer)

    func cancelOrder(_ order: ServiceOrder, uid: String) async throws {
        guard order.customerUID == uid || order.customerUID.isEmpty else { throw OrderError.unauthorized }
        // If order was paid, trigger Stripe refund via Cloud Function
        if order.paymentStatus == .paid, order.stripePaymentIntentId != nil {
            let callable = functions.httpsCallable("refundOrder")
            _ = try? await callable.call(["orderId": order.id])
        } else {
            try await db.collection("orders").document(order.id).updateData([
                "status": ServiceOrder.OrderStatus.cancelled.rawValue
            ])
        }
    }
}

// MARK: - OrderError

enum OrderError: LocalizedError {
    case unauthorized
    case notFound
    case alreadyClaimed

    var errorDescription: String? {
        switch self {
        case .unauthorized:   return "You don't have permission to modify this order."
        case .notFound:       return "Order not found."
        case .alreadyClaimed: return "This job was already claimed by another provider."
        }
    }
}
