import Foundation
import FirebaseFirestore

/// Decodes `providers/{pid}/services` docs for display. Firestore may store `price` as Int or Double;
/// `doc.data(as: ServiceItem.self)` often fails on Int → services “disappear” from lists.
enum ServiceItemFirestore {

    static func item(from doc: DocumentSnapshot) -> ServiceItem? {
        guard let data = doc.data() else { return nil }
        let docId = doc.documentID
        let rawName = data["name"] as? String ?? ""
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let bounded = String(name.prefix(120))
        let id: String
        if let s = data["id"] as? String, !s.isEmpty { id = s }
        else { id = docId }
        guard let price = normalizedPrice(data["price"]), price > 0, price < 100_000 else { return nil }
        return ServiceItem(id: id, name: bounded, price: price)
    }

    static func sortedItems(from documents: [QueryDocumentSnapshot]) -> [ServiceItem] {
        documents.compactMap { item(from: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func normalizedPrice(_ value: Any?) -> Double? {
        switch value {
        case let d as Double: return d
        case let f as Float: return Double(f)
        case let i as Int: return Double(i)
        case let i as Int32: return Double(i)
        case let i as Int64: return Double(i)
        case let n as NSNumber: return n.doubleValue
        case let s as String:
            return Double(s.replacingOccurrences(of: ",", with: "."))
        default:
            return nil
        }
    }
}
