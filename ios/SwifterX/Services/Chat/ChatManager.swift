import Foundation
import FirebaseFirestore

@MainActor
final class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private(set) var orderID: String = ""

    // MARK: - Listen

    func startListening(orderID: String) {
        guard orderID != self.orderID || listener == nil else { return }
        self.orderID = orderID
        listener?.remove()
        isLoading = true

        listener = db.collection("orders").document(orderID)
            .collection("messages")
            .order(by: "sentAt")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                self.isLoading = false
                self.messages = snap?.documents.compactMap {
                    try? $0.data(as: ChatMessage.self)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        messages = []
        orderID  = ""
    }

    // MARK: - Send

    func send(text: String,
              senderUID: String,
              senderName: String,
              isProvider: Bool) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = InputSanitizer.chatMessage(trimmed)
        guard !body.isEmpty else { return }
        let safeName = InputSanitizer.name(senderName)
        let displayName = safeName.isEmpty ? (isProvider ? "Provider" : "Customer") : safeName
        let msg = ChatMessage(senderUID: senderUID,
                              senderName: displayName,
                              text: body,
                              isProvider: isProvider)
        try db.collection("orders").document(orderID)
            .collection("messages")
            .document(msg.id)
            .setData(from: msg)
    }
}
