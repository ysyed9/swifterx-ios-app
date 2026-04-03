import Foundation

struct ServiceCategory: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var icon: String

    init(id: String = UUID().uuidString, title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}
