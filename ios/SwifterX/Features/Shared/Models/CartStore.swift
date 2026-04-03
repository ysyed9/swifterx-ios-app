import SwiftUI
import Combine

struct ServiceItem: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var price: Double

    init(id: String = UUID().uuidString, name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
}

struct CartItem: Identifiable {
    var id: String
    let service: ServiceItem

    init(id: String = UUID().uuidString, service: ServiceItem) {
        self.id = id
        self.service = service
    }
}

class CartStore: ObservableObject {
    static let shared = CartStore()

    @Published var items: [CartItem] = []
    @Published var provider: ServiceProvider?
    @Published var selectedDate: Date = Date()
    @Published var selectedTime: String = ""
    @Published var specialInstructions: String = ""

    var subtotal: Double { items.reduce(0) { $0 + $1.service.price } }
    var fee: Double     { subtotal * 0.01 }
    var total: Double   { subtotal + fee }

    func add(_ service: ServiceItem, from provider: ServiceProvider) {
        if self.provider?.id != provider.id { items = [] }
        self.provider = provider
        if !items.contains(where: { $0.service.id == service.id }) {
            items.append(CartItem(service: service))
        }
    }

    func remove(_ service: ServiceItem) {
        items.removeAll { $0.service.id == service.id }
    }

    func contains(_ service: ServiceItem) -> Bool {
        items.contains { $0.service.id == service.id }
    }

    func clear() {
        items = []
        provider = nil
        selectedTime = ""
        specialInstructions = ""
    }
}
