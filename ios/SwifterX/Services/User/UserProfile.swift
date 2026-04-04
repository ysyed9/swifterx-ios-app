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
    var referralCode: String       // unique code this user can share
    var referralCredits: Double    // accumulated $ credit from referrals
    /// Customer profile photo (Firebase Storage download URL).
    var photoURL: String

    var fullAddress: String {
        guard !addressLine.isEmpty else { return "" }
        let cityState = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
        let cityStateZip = [cityState, zip].filter { !$0.isEmpty }.joined(separator: " ")
        return [addressLine, cityStateZip].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    static func empty(uid: String, email: String) -> UserProfile {
        UserProfile(uid: uid, name: "", email: email,
                    phone: "", addressLine: "", city: "", state: "", zip: "",
                    referralCode: Self.generateCode(uid: uid), photoURL: "")
    }

    // MARK: - Referral code generation

    static func generateCode(uid: String) -> String {
        let base = uid.prefix(6).uppercased()
        let suffix = String(Int.random(in: 100...999))
        return "SX-\(base)\(suffix)"
    }

    // MARK: - Firestore dictionary

    /// Values aligned with Firestore rules field sizes; safe for `setData` / full document writes.
    var firestoreData: [String: Any] {
        [
            "uid": uid,
            "name": InputSanitizer.name(name),
            "email": InputSanitizer.email(email),
            "phone": InputSanitizer.phone(phone),
            "addressLine": InputSanitizer.address(addressLine),
            "city": InputSanitizer.clean(city, limit: 60),
            "state": InputSanitizer.clean(state, limit: 30),
            "zip": InputSanitizer.clean(zip, limit: FieldLimit.zipCode),
            "referralCode": InputSanitizer.clean(referralCode, limit: 40),
            "referralCredits": referralCredits,
            "photoURL": InputSanitizer.photoURL(photoURL)
        ]
    }

    init(uid: String, name: String, email: String, phone: String,
         addressLine: String, city: String, state: String, zip: String,
         referralCode: String = "", referralCredits: Double = 0, photoURL: String = "") {
        self.uid             = uid
        self.name            = name
        self.email           = email
        self.phone           = phone
        self.addressLine     = addressLine
        self.city            = city
        self.state           = state
        self.zip             = zip
        self.referralCode    = referralCode.isEmpty ? Self.generateCode(uid: uid) : referralCode
        self.referralCredits = referralCredits
        self.photoURL        = photoURL
    }

    init?(from dict: [String: Any], uid: String) {
        self.uid             = uid
        self.name            = dict["name"]            as? String ?? ""
        self.email           = dict["email"]           as? String ?? ""
        self.phone           = dict["phone"]           as? String ?? ""
        self.addressLine     = dict["addressLine"]     as? String ?? ""
        self.city            = dict["city"]            as? String ?? ""
        self.state           = dict["state"]           as? String ?? ""
        self.zip             = dict["zip"]             as? String ?? ""
        self.referralCode    = dict["referralCode"]    as? String ?? Self.generateCode(uid: uid)
        self.referralCredits = dict["referralCredits"] as? Double ?? 0
        self.photoURL        = dict["photoURL"]        as? String ?? ""
    }
}
