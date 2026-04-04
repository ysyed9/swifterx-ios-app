import Foundation

// MARK: - Day Availability

struct DayAvailability: Codable, Identifiable, Equatable {
    var id: String { day }
    var day: String        // "Mon" | "Tue" | ...
    var isAvailable: Bool
    var startHour: Int     // 0–23 (8 = 8 AM)
    var endHour: Int       // 0–23 (18 = 6 PM)

    var startLabel: String { hourLabel(startHour) }
    var endLabel:   String { hourLabel(endHour) }

    private func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h % 12 == 0 ? 12 : h % 12
        return "\(display):00 \(suffix)"
    }

    static let defaultWeek: [DayAvailability] = [
        .init(day: "Mon", isAvailable: true,  startHour: 8, endHour: 18),
        .init(day: "Tue", isAvailable: true,  startHour: 8, endHour: 18),
        .init(day: "Wed", isAvailable: true,  startHour: 8, endHour: 18),
        .init(day: "Thu", isAvailable: true,  startHour: 8, endHour: 18),
        .init(day: "Fri", isAvailable: true,  startHour: 8, endHour: 18),
        .init(day: "Sat", isAvailable: false, startHour: 9, endHour: 15),
        .init(day: "Sun", isAvailable: false, startHour: 9, endHour: 15),
    ]
}

// MARK: - Provider Profile

struct ProviderProfile: Codable, Identifiable {
    var id: String                       // = Firebase Auth UID
    var name: String
    var bio: String
    var photoURL: String
    var serviceCategories: [String]      // category names they offer
    var hourlyRate: Double               // USD per hour
    var serviceRadiusMiles: Double
    var availability: [DayAvailability]
    var backgroundCheckConsented: Bool
    var backgroundCheckConsentDate: Date?
    var isOnboarded: Bool
    var rating: Double
    var reviewCount: Int
    var createdAt: Date
    /// Stripe Connect Express account ID (set by Cloud Function on payout setup)
    var stripeConnectAccountId: String?
    /// True once provider completes Stripe Express onboarding
    var connectOnboardingComplete: Bool
    /// Operator-approved for paid jobs & public listing. New signups start `false`.
    /// Omitted in legacy Firestore docs → treated as approved in app logic.
    var approved: Bool
    /// When SwifterX approved this provider (set in Firebase Console / Admin SDK).
    var approvedAt: Date?
    /// Optional note when access is restricted (set by operator only).
    var rejectionReason: String?

    // MARK: - Computed

    var payoutsEnabled: Bool { connectOnboardingComplete && !(stripeConnectAccountId?.isEmpty ?? true) }

    /// `false` only when the provider explicitly has `approved == false` after onboarding.
    var isApprovedForJobs: Bool { approved }

    /// Operator-facing rejection note (Firestore / Admin only), when present and non-empty.
    var trimmedRejectionReason: String? {
        guard let r = rejectionReason?.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty else { return nil }
        return r
    }

    init(id: String,
         name: String = "",
         bio: String = "",
         photoURL: String = "",
         serviceCategories: [String] = [],
         hourlyRate: Double = 50,
         serviceRadiusMiles: Double = 10,
         availability: [DayAvailability] = DayAvailability.defaultWeek,
         backgroundCheckConsented: Bool = false,
         backgroundCheckConsentDate: Date? = nil,
         isOnboarded: Bool = false,
         rating: Double = 0,
         reviewCount: Int = 0,
         createdAt: Date = Date(),
         stripeConnectAccountId: String? = nil,
         connectOnboardingComplete: Bool = false,
         approved: Bool = true,
         approvedAt: Date? = nil,
         rejectionReason: String? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.photoURL = photoURL
        self.serviceCategories = serviceCategories
        self.hourlyRate = hourlyRate
        self.serviceRadiusMiles = serviceRadiusMiles
        self.availability = availability
        self.backgroundCheckConsented = backgroundCheckConsented
        self.backgroundCheckConsentDate = backgroundCheckConsentDate
        self.isOnboarded = isOnboarded
        self.rating = rating
        self.reviewCount = reviewCount
        self.createdAt = createdAt
        self.stripeConnectAccountId = stripeConnectAccountId
        self.connectOnboardingComplete = connectOnboardingComplete
        self.approved = approved
        self.approvedAt = approvedAt
        self.rejectionReason = rejectionReason
    }

    enum CodingKeys: String, CodingKey {
        case id, name, bio, photoURL, serviceCategories, hourlyRate, serviceRadiusMiles
        case availability, backgroundCheckConsented, backgroundCheckConsentDate, isOnboarded
        case rating, reviewCount, createdAt, stripeConnectAccountId, connectOnboardingComplete
        case approved, approvedAt, rejectionReason
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        bio = try c.decodeIfPresent(String.self, forKey: .bio) ?? ""
        photoURL = try c.decodeIfPresent(String.self, forKey: .photoURL) ?? ""
        serviceCategories = try c.decodeIfPresent([String].self, forKey: .serviceCategories) ?? []
        hourlyRate = try c.decodeIfPresent(Double.self, forKey: .hourlyRate) ?? 50
        serviceRadiusMiles = try c.decodeIfPresent(Double.self, forKey: .serviceRadiusMiles) ?? 10
        availability = try c.decodeIfPresent([DayAvailability].self, forKey: .availability) ?? DayAvailability.defaultWeek
        backgroundCheckConsented = try c.decodeIfPresent(Bool.self, forKey: .backgroundCheckConsented) ?? false
        backgroundCheckConsentDate = try c.decodeIfPresent(Date.self, forKey: .backgroundCheckConsentDate)
        isOnboarded = try c.decodeIfPresent(Bool.self, forKey: .isOnboarded) ?? false
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        stripeConnectAccountId = try c.decodeIfPresent(String.self, forKey: .stripeConnectAccountId)
        connectOnboardingComplete = try c.decodeIfPresent(Bool.self, forKey: .connectOnboardingComplete) ?? false
        // Legacy profiles without `approved` stay bookable/listable.
        approved = try c.decodeIfPresent(Bool.self, forKey: .approved) ?? true
        approvedAt = try c.decodeIfPresent(Date.self, forKey: .approvedAt)
        rejectionReason = try c.decodeIfPresent(String.self, forKey: .rejectionReason)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(bio, forKey: .bio)
        try c.encode(photoURL, forKey: .photoURL)
        try c.encode(serviceCategories, forKey: .serviceCategories)
        try c.encode(hourlyRate, forKey: .hourlyRate)
        try c.encode(serviceRadiusMiles, forKey: .serviceRadiusMiles)
        try c.encode(availability, forKey: .availability)
        try c.encode(backgroundCheckConsented, forKey: .backgroundCheckConsented)
        try c.encodeIfPresent(backgroundCheckConsentDate, forKey: .backgroundCheckConsentDate)
        try c.encode(isOnboarded, forKey: .isOnboarded)
        try c.encode(rating, forKey: .rating)
        try c.encode(reviewCount, forKey: .reviewCount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(stripeConnectAccountId, forKey: .stripeConnectAccountId)
        try c.encode(connectOnboardingComplete, forKey: .connectOnboardingComplete)
        try c.encode(approved, forKey: .approved)
        try c.encodeIfPresent(approvedAt, forKey: .approvedAt)
        try c.encodeIfPresent(rejectionReason, forKey: .rejectionReason)
    }
}
