import Foundation

struct Review: Identifiable, Codable {
    var id: String
    var providerID: String
    var customerUID: String
    var customerName: String
    var rating: Int
    var comment: String
    var createdAt: Date
    /// Links the review to a specific order so we can prevent duplicate reviews.
    var orderID: String

    init(id: String = UUID().uuidString, providerID: String, customerUID: String,
         customerName: String, rating: Int, comment: String,
         createdAt: Date = Date(), orderID: String = "") {
        self.id = id
        self.providerID = providerID
        self.customerUID = customerUID
        self.customerName = customerName
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
        self.orderID = orderID
    }

    // Formatted date for display
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        let days = Int(interval / 86400)
        if days == 0 { return "Today" }
        if days < 7  { return "\(days) day\(days == 1 ? "" : "s") ago" }
        let weeks = days / 7
        if weeks < 5 { return "\(weeks) week\(weeks == 1 ? "" : "s") ago" }
        let months = days / 30
        return "\(months) month\(months == 1 ? "" : "s") ago"
    }
}
