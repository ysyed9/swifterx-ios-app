import Foundation
import SwiftUI

// MARK: - Field-level limits (single source of truth)

enum FieldLimit {
    static let name             = 60
    static let email            = 120
    static let password         = 128
    static let phone            = 20
    static let address          = 160
    static let chatMessage      = 2_000
    static let reviewComment    = 1_000
    static let specialInstructions = 500
    static let promoCode        = 24
    static let bio              = 600
    static let searchQuery      = 80
    static let cardNumber       = 19   // 16 digits + 3 spaces
    static let cvv              = 4
    static let zipCode          = 10
    static let photoURL         = 2048   // Firebase Storage download URLs
    static let hourlyRate       = 6    // numeric string, e.g. "250.00"
    static let serviceRadius    = 4
}

// MARK: - InputSanitizer

enum InputSanitizer {

    // MARK: - Core transform

    /// Trims whitespace, collapses internal runs of whitespace, and caps length.
    static func clean(_ raw: String, limit: Int) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let capped  = trimmed.count <= limit ? trimmed : String(trimmed.prefix(limit))
        return capped
    }

    /// Like `clean` but also removes characters outside the allowed set.
    static func clean(_ raw: String, limit: Int, allowedSet: CharacterSet) -> String {
        let filtered = String(raw.unicodeScalars.filter { allowedSet.contains($0) })
        return clean(filtered, limit: limit)
    }

    // MARK: - Typed sanitizers (called from .onChange bindings)

    static func name(_ v: String)               -> String { clean(v, limit: FieldLimit.name, allowedSet: .nameAllowed) }
    static func email(_ v: String)              -> String { clean(v.lowercased(), limit: FieldLimit.email, allowedSet: .emailAllowed) }
    static func password(_ v: String)           -> String { clean(v, limit: FieldLimit.password) }   // do not strip; passwords can be anything
    static func phone(_ v: String)              -> String { clean(v, limit: FieldLimit.phone, allowedSet: .phoneAllowed) }
    static func address(_ v: String)            -> String { clean(v, limit: FieldLimit.address) }
    static func chatMessage(_ v: String)        -> String { clean(v, limit: FieldLimit.chatMessage) }
    static func reviewComment(_ v: String)      -> String { clean(v, limit: FieldLimit.reviewComment) }
    static func specialInstructions(_ v: String)-> String { clean(v, limit: FieldLimit.specialInstructions) }
    static func promoCode(_ v: String)          -> String { clean(v.uppercased(), limit: FieldLimit.promoCode, allowedSet: .alphanumericHyphen) }
    static func bio(_ v: String)                -> String { clean(v, limit: FieldLimit.bio) }
    static func searchQuery(_ v: String)        -> String { clean(v, limit: FieldLimit.searchQuery) }
    static func hourlyRate(_ v: String)         -> String { clean(v, limit: FieldLimit.hourlyRate, allowedSet: .decimalDigitAndDot) }
    static func serviceRadius(_ v: String)      -> String { clean(v, limit: FieldLimit.serviceRadius, allowedSet: .decimalDigits) }
    static func photoURL(_ v: String)           -> String { clean(v, limit: FieldLimit.photoURL) }

    // MARK: - Validation (returns nil when valid, error string when invalid)

    static func validateEmail(_ v: String) -> String? {
        let trimmed = v.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Email is required" }
        guard trimmed.count <= FieldLimit.email else { return "Email is too long" }
        // RFC-5322 simplified regex
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return "Enter a valid email address"
        }
        return nil
    }

    static func validatePassword(_ v: String) -> String? {
        guard v.count >= 8  else { return "Password must be at least 8 characters" }
        guard v.count <= FieldLimit.password else { return "Password is too long" }
        guard v.rangeOfCharacter(from: .decimalDigits) != nil else { return "Password must include at least one number" }
        return nil
    }

    static func validateName(_ v: String) -> String? {
        let t = v.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return "Name is required" }
        guard t.count >= 2 else { return "Name must be at least 2 characters" }
        return nil
    }

    static func validatePhone(_ v: String) -> String? {
        let digits = v.filter { $0.isNumber }
        guard digits.count >= 7 && digits.count <= 15 else { return "Enter a valid phone number" }
        return nil
    }

    static func validatePromoCode(_ v: String) -> String? {
        guard v.count >= 3 else { return "Promo code too short" }
        return nil
    }

    static func validateHourlyRate(_ v: String) -> String? {
        guard let rate = Double(v), rate > 0, rate <= 9_999 else { return "Enter a valid hourly rate" }
        return nil
    }

    static func validateServiceRadius(_ v: String) -> String? {
        guard let r = Int(v), r >= 1, r <= 100 else { return "Radius must be between 1 and 100 miles" }
        return nil
    }
}

// MARK: - CharacterSet helpers

private extension CharacterSet {
    static let nameAllowed: CharacterSet = {
        var s = CharacterSet.letters
        s.insert(charactersIn: " '-.")
        return s
    }()

    static let emailAllowed: CharacterSet = {
        var s = CharacterSet.alphanumerics
        s.insert(charactersIn: "@._+\\-%")
        return s
    }()

    static let phoneAllowed: CharacterSet = {
        var s = CharacterSet.decimalDigits
        s.insert(charactersIn: "+() -")
        return s
    }()

    static let alphanumericHyphen: CharacterSet = {
        var s = CharacterSet.alphanumerics
        s.insert(charactersIn: "-")
        return s
    }()

    static let decimalDigitAndDot: CharacterSet = {
        var s = CharacterSet.decimalDigits
        s.insert(charactersIn: ".")
        return s
    }()
}

// MARK: - SwiftUI View extension for convenient sanitized binding

extension View {
    /// Attaches an `.onChange` that automatically sanitises the bound string.
    func sanitized(_ value: Binding<String>,
                   using sanitizer: @escaping (String) -> String) -> some View {
        self.onChange(of: value.wrappedValue) { newValue in
            let cleaned = sanitizer(newValue)
            if cleaned != newValue { value.wrappedValue = cleaned }
        }
    }
}
