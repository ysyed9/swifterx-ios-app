import Foundation

struct Recommendation: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let rating: Double
    let price: Int

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        rating: Double,
        price: Int
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.rating = rating
        self.price = price
    }
}
