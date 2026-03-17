import Foundation

struct ServiceCategory: Identifiable, Hashable {
    let id: UUID
    let title: String
    let icon: String

    init(id: UUID = UUID(), title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}
