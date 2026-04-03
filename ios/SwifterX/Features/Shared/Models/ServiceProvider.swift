import Foundation

struct ServiceProvider: Identifiable, Codable {
    var id: String
    var name: String
    var category: String
    var description: String
    var rating: Double
    var distanceMi: Double
    var imageName: String
    var imageURL: String
    var reviewCount: Int

    init(id: String = UUID().uuidString, name: String, category: String,
         description: String, rating: Double, distanceMi: Double,
         imageName: String = "", imageURL: String = "", reviewCount: Int = 156) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.rating = rating
        self.distanceMi = distanceMi
        self.imageName = imageName
        self.imageURL = imageURL
        self.reviewCount = reviewCount
    }
}

enum OrderPaymentStatus: String, Codable, CaseIterable {
    case unpaid     = "unpaid"
    case processing = "processing"
    case paid       = "paid"
    case failed     = "failed"
    case refunded   = "refunded"
}

struct ServiceOrder: Identifiable, Codable {
    var id: String
    var customerUID: String
    var providerID: String
    var providerName: String
    var price: Double
    var scheduledDate: Date
    var scheduledTime: String
    var status: OrderStatus
    var services: [OrderLineItem]
    var specialInstructions: String
    var createdAt: Date
    /// Set by Cloud Function after Stripe PaymentIntent is created; do not trust client-only updates for `paid`.
    var paymentStatus: OrderPaymentStatus
    var stripePaymentIntentId: String?
    /// Firebase Auth UID of the provider who accepted this job. Empty until a provider claims it.
    var providerUID: String

    // Computed for display — not stored in Firestore
    var date: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: scheduledDate)
    }

    // Excludes computed 'date' from Codable
    enum CodingKeys: String, CodingKey {
        case id, customerUID, providerID, providerName, price
        case scheduledDate, scheduledTime, status, services
        case specialInstructions, createdAt
        case paymentStatus, stripePaymentIntentId, providerUID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        customerUID = try c.decode(String.self, forKey: .customerUID)
        providerID = try c.decode(String.self, forKey: .providerID)
        providerName = try c.decode(String.self, forKey: .providerName)
        price = try c.decode(Double.self, forKey: .price)
        scheduledDate = try c.decode(Date.self, forKey: .scheduledDate)
        scheduledTime = try c.decode(String.self, forKey: .scheduledTime)
        status = try c.decode(OrderStatus.self, forKey: .status)
        services = try c.decode([OrderLineItem].self, forKey: .services)
        specialInstructions = try c.decode(String.self, forKey: .specialInstructions)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        paymentStatus = try c.decodeIfPresent(OrderPaymentStatus.self, forKey: .paymentStatus) ?? .paid
        stripePaymentIntentId = try c.decodeIfPresent(String.self, forKey: .stripePaymentIntentId)
        providerUID = try c.decodeIfPresent(String.self, forKey: .providerUID) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(customerUID, forKey: .customerUID)
        try c.encode(providerID, forKey: .providerID)
        try c.encode(providerName, forKey: .providerName)
        try c.encode(price, forKey: .price)
        try c.encode(scheduledDate, forKey: .scheduledDate)
        try c.encode(scheduledTime, forKey: .scheduledTime)
        try c.encode(status, forKey: .status)
        try c.encode(services, forKey: .services)
        try c.encode(specialInstructions, forKey: .specialInstructions)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(paymentStatus, forKey: .paymentStatus)
        try c.encodeIfPresent(stripePaymentIntentId, forKey: .stripePaymentIntentId)
        try c.encode(providerUID, forKey: .providerUID)
    }

    enum OrderStatus: String, Codable, CaseIterable {
        case pending    = "pending"
        case confirmed  = "confirmed"
        case inProgress = "inProgress"
        case completed  = "completed"
        case cancelled  = "cancelled"

        var label: String {
            switch self {
            case .pending:    return "Pending"
            case .confirmed:  return "Confirmed"
            case .inProgress: return "In Progress"
            case .completed:  return "Completed"
            case .cancelled:  return "Cancelled"
            }
        }

        var color: String {
            switch self {
            case .pending:    return "orange"
            case .confirmed:  return "green"
            case .inProgress: return "blue"
            case .completed:  return "gray"
            case .cancelled:  return "red"
            }
        }
    }

    init(id: String = UUID().uuidString, customerUID: String = "",
         providerID: String = "", providerName: String, price: Double,
         scheduledDate: Date = Date(), scheduledTime: String = "",
         status: OrderStatus, services: [OrderLineItem],
         specialInstructions: String = "", createdAt: Date = Date(),
         paymentStatus: OrderPaymentStatus = .unpaid,
         stripePaymentIntentId: String? = nil,
         providerUID: String = "") {
        self.id = id
        self.customerUID = customerUID
        self.providerID = providerID
        self.providerName = providerName
        self.price = price
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.status = status
        self.services = services
        self.specialInstructions = specialInstructions
        self.createdAt = createdAt
        self.paymentStatus = paymentStatus
        self.stripePaymentIntentId = stripePaymentIntentId
        self.providerUID = providerUID
    }
}

struct OrderLineItem: Identifiable, Codable {
    var id: String
    var name: String
    var price: Double

    init(id: String = UUID().uuidString, name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
}
