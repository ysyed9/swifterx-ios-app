import SwiftUI

struct ChatView: View {
    let orderID: String
    let orderTitle: String      // e.g. "Piper's Plumbing"
    let currentUID: String
    let currentName: String
    let isProvider: Bool

    @StateObject private var chatManager = ChatManager()
    @State private var inputText = ""
    @State private var isSending = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.black)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(orderTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Order chat")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#888888"))
                }
                Spacer()
                // balance spacer
                Color.clear.frame(width: 24)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if chatManager.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if chatManager.messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(chatManager.messages) { msg in
                                MessageBubble(msg: msg, isMine: msg.senderUID == currentUID)
                                    .id(msg.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: chatManager.messages.count) { _ in
                    if let last = chatManager.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Input bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Message…", text: $inputText, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#f2f2f2"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .sanitized($inputText, using: InputSanitizer.chatMessage)

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: isSending ? "ellipsis" : "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? Color(hex: "#cccccc") : Color.black)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
        .background(Color(hex: "#fafafa"))
        .navigationBarHidden(true)
        .onAppear {
            chatManager.startListening(orderID: orderID)
            AnalyticsManager.shared.logChatOpened(orderID: orderID)
            AnalyticsManager.shared.logScreen("ChatView")
        }
        .onDisappear { chatManager.stopListening() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "No messages yet",
            subtitle: "Send a message to coordinate\nyour service appointment."
        )
    }

    // MARK: - Send

    private func sendMessage() async {
        let text = InputSanitizer.chatMessage(inputText)
        guard !text.isEmpty else { return }
        isSending = true
        try? await chatManager.send(
            text: text,
            senderUID: currentUID,
            senderName: InputSanitizer.name(currentName),
            isProvider: isProvider
        )
        inputText = ""
        isSending = false
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let msg: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 60) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                if !isMine {
                    Text(msg.senderName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#888888"))
                        .padding(.leading, 4)
                }
                Text(msg.text)
                    .font(.system(size: 15))
                    .foregroundStyle(isMine ? .white : .black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? Color.black : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                Text(timeLabel(msg.sentAt))
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#bbbbbb"))
                    .padding(.horizontal, 4)
            }
            if !isMine { Spacer(minLength: 60) }
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
