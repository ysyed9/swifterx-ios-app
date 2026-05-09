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
    /// Alias used by deep link router and OrderDetailView
    var customerOrders: [ServiceOrder] { orders }
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
    private let functions = AppFunctions.instance

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
                    if let error {
                        #if DEBUG
                        self.errorMessage = error.localizedDescription
                        #else
                        self.errorMessage = "Couldn’t load orders. Pull to refresh or try again."
                        #endif
                        return
                    }
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

        // Inbox: confirmed + paid orders for this specific provider that haven't been claimed yet.
        // Filter by providerID so only the booked provider sees their pending requests.
        inboxListener = db.collection("orders")
            .whereField("providerUID", isEqualTo: "")
            .whereField("providerID", isEqualTo: uid)
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
        guard let cartProvider = cart.provider else {
            throw OrderError.missingProviderInfo
        }
        guard !cartProvider.id.isEmpty, !cartProvider.name.isEmpty else {
            throw OrderError.missingProviderInfo
        }
        guard cartProvider.isVisibleToCustomers else {
            throw OrderError.providerNotBookable
        }
        guard cart.total > 0, cart.total < 100_000 else {
            throw OrderError.invalidOrderTotal
        }

        let order = ServiceOrder(
            id: UUID().uuidString,
            customerUID: uid,
            providerID: cartProvider.id,
            providerName: cartProvider.name,
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
        do {
            try await db.collection("orders").document(order.id).setData(from: order)
            RetryQueue.shared.remove(key: "place_order_\(order.id)")
        } catch {
            let ns = error as NSError
            let permissionDenied = (ns.domain == FirestoreErrorDomain
                && ns.code == FirestoreErrorCode.permissionDenied.rawValue)
                || ((ns.userInfo[NSUnderlyingErrorKey] as? NSError).map {
                    $0.domain == FirestoreErrorDomain
                        && $0.code == FirestoreErrorCode.permissionDenied.rawValue
                } ?? false)
            if permissionDenied {
                throw OrderError.placementNotAllowed
            }
            // If offline, queue for retry when connectivity returns
            RetryQueue.shared.enqueue(key: "place_order_\(order.id)") { [weak self] in
                try? await self?.db.collection("orders").document(order.id).setData(from: order)
            }
            throw error
        }
        AnalyticsManager.shared.logOrderPlaced(
            orderID:      order.id,
            providerName: order.providerName,
            amount:       order.price
        )
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
        AnalyticsManager.shared.logOrderCancelled(orderID: order.id)
    }
}

// MARK: - OrderError

enum OrderError: LocalizedError {
    case unauthorized
    case notFound
    case alreadyClaimed
    /// Cart has no provider or provider id/name is empty (Firestore rules reject the write).
    case missingProviderInfo
    /// Provider doc has `listingApproved == false` (stale cart, deep link, or admin change).
    case providerNotBookable
    /// Rules require `price > 0` and a sane cap; cart total was out of range.
    case invalidOrderTotal
    /// Firestore returned permission denied (e.g. rules mismatch); retry would not help.
    case placementNotAllowed

    var errorDescription: String? {
        switch self {
        case .unauthorized:   return "You don't have permission to modify this order."
        case .notFound:       return "Order not found."
        case .alreadyClaimed: return "This job was already claimed by another provider."
        case .missingProviderInfo:
            return "Choose a provider and at least one service before placing your order."
        case .providerNotBookable:
            return "This provider isn’t accepting bookings right now. Try another provider or check back later."
        case .invalidOrderTotal:
            return "Your order total must be greater than zero. Add a service or refresh your cart."
        case .placementNotAllowed:
            return "We couldn’t place this order. Sign in again, or pick another provider if the problem continues."
        }
    }
}
