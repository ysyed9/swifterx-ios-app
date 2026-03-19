import Foundation

struct ServiceProvider: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let description: String
    let rating: Double
    let distanceMi: Double
    let imageName: String
    let reviewCount: Int

    init(id: UUID = UUID(), name: String, category: String, description: String,
         rating: Double, distanceMi: Double, imageName: String = "", reviewCount: Int = 156) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.rating = rating
        self.distanceMi = distanceMi
        self.imageName = imageName
        self.reviewCount = reviewCount
    }
}

struct ServiceOrder: Identifiable {
    let id: UUID
    let providerName: String
    let price: Double
    let date: String
    let status: OrderStatus
    let services: [OrderLineItem]

    enum OrderStatus {
        case reserved, canceled, completed
        var label: String {
            switch self { case .reserved: return "Reserved"; case .canceled: return "Canceled"; case .completed: return "Completed" }
        }
        var color: String {
            switch self { case .reserved: return "green"; case .canceled: return "gray"; case .completed: return "gray" }
        }
    }

    init(id: UUID = UUID(), providerName: String, price: Double, date: String,
         status: OrderStatus, services: [OrderLineItem]) {
        self.id = id
        self.providerName = providerName
        self.price = price
        self.date = date
        self.status = status
        self.services = services
    }
}

struct OrderLineItem: Identifiable {
    let id: UUID
    let name: String
    let price: Double

    init(id: UUID = UUID(), name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
}
