import Foundation

// Stored at orders/{orderID}/messages/{messageID}
struct ChatMessage: Identifiable, Codable {
    var id: String
    var senderUID: String
    var senderName: String
    var text: String
    var sentAt: Date
    var isProvider: Bool

    init(id: String = UUID().uuidString,
         senderUID: String,
         senderName: String,
         text: String,
         sentAt: Date = Date(),
         isProvider: Bool) {
        self.id         = id
        self.senderUID  = senderUID
        self.senderName = senderName
        self.text       = text
        self.sentAt     = sentAt
        self.isProvider = isProvider
    }
}
