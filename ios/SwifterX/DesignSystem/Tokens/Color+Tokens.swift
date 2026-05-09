import SwiftUI

extension Color {
    /// Hex string `#RGB`, `#RRGGBB`, or `#RRGGBBAA` (also accepts forms without `#`). Named `sxHex` to avoid clashing with SDK `Color` APIs that use `hex:`.
    init(sxHex: String) {
        let hex = sxHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    static let sxBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let sxSurface = Color.white
    static let sxPrimaryText = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let sxSecondaryText = Color(red: 0.42, green: 0.42, blue: 0.46)
    static let sxAccent = Color(red: 1.00, green: 0.56, blue: 0.10)
    static let sxBorder = Color(red: 0.90, green: 0.90, blue: 0.92)
    static let sxCardShadow = Color.black.opacity(0.06)
}

extension ShapeStyle where Self == Color {
    static var sxPrimaryText: Color { Color.sxPrimaryText }
    static var sxSecondaryText: Color { Color.sxSecondaryText }
    static var sxAccent: Color { Color.sxAccent }
}
