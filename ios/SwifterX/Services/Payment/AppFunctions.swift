import Foundation
import FirebaseFunctions

/// Single `Functions` instance for the app’s region (see `FirebaseFunctionsRegion` in `SwifterX-Info.plist`).
enum AppFunctions {
    static let instance: Functions = {
        if let region = Bundle.main.object(forInfoDictionaryKey: "FirebaseFunctionsRegion") as? String,
           !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Functions.functions(region: region)
        }
        return Functions.functions()
    }()
}
