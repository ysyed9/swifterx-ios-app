import Foundation

enum MockData {
    static let categories: [ServiceCategory] = [
        ServiceCategory(title: "Cleaning", icon: "sparkles"),
        ServiceCategory(title: "Salon", icon: "scissors"),
        ServiceCategory(title: "Repair", icon: "wrench.adjustable"),
        ServiceCategory(title: "Plumber", icon: "drop"),
        ServiceCategory(title: "Painting", icon: "paintbrush")
    ]

    static let recommendations: [Recommendation] = [
        Recommendation(
            title: "Premium Home Cleaning",
            subtitle: "2 professionals, eco-friendly supplies",
            rating: 4.9,
            price: 59
        ),
        Recommendation(
            title: "Salon at Home",
            subtitle: "Facial + cleanup package, 90 mins",
            rating: 4.8,
            price: 45
        ),
        Recommendation(
            title: "AC Service",
            subtitle: "Inspection, jet wash, gas check",
            rating: 4.7,
            price: 79
        )
    ]
}
