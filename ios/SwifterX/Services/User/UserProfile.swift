import Foundation

struct UserProfile: Codable, Equatable {
    var uid: String
    var name: String
    var email: String
    var phone: String
    var addressLine: String
    var city: String
    var state: String
    var zip: String

    var fullAddress: String {
        guard !addressLine.isEmpty else { return "" }
        let cityState = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
        let cityStateZip = [cityState, zip].filter { !$0.isEmpty }.joined(separator: " ")
        return [addressLine, cityStateZip].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    static func empty(uid: String, email: String) -> UserProfile {
        UserProfile(uid: uid, name: "", email: email,
                    phone: "", addressLine: "", city: "", state: "", zip: "")
    }

    // Firestore dictionary
    var firestoreData: [String: Any] {
        ["uid": uid, "name": name, "email": email,
         "phone": phone, "addressLine": addressLine,
         "city": city, "state": state, "zip": zip]
    }

    init(uid: String, name: String, email: String, phone: String,
         addressLine: String, city: String, state: String, zip: String) {
        self.uid = uid; self.name = name; self.email = email
        self.phone = phone; self.addressLine = addressLine
        self.city = city; self.state = state; self.zip = zip
    }

    init?(from dict: [String: Any], uid: String) {
        self.uid        = uid
        self.name       = dict["name"]        as? String ?? ""
        self.email      = dict["email"]       as? String ?? ""
        self.phone      = dict["phone"]       as? String ?? ""
        self.addressLine = dict["addressLine"] as? String ?? ""
        self.city       = dict["city"]        as? String ?? ""
        self.state      = dict["state"]       as? String ?? ""
        self.zip        = dict["zip"]         as? String ?? ""
    }
}
