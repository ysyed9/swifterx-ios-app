import Foundation

enum MockData {
    static let categories: [(name: String, icon: String)] = [
        ("Cleaning",   "sparkles"),
        ("Repairing",  "wrench.and.screwdriver"),
        ("Painting",   "paintbrush"),
        ("Gardening",  "leaf"),
        ("Plumbing",   "drop"),
        ("Pest Control","shield"),
        ("Landscaping","tree"),
        ("Electrician","bolt"),
        ("Appliance\nMaintenance","gearshape")
    ]

    static let providerServices: [UUID: [ServiceItem]] = {
        var dict = [UUID: [ServiceItem]]()
        for p in providers {
            dict[p.id] = serviceItems(for: p.category)
        }
        return dict
    }()

    static func serviceItems(for category: String) -> [ServiceItem] {
        switch category {
        case "Plumbing":
            return [ServiceItem(name: "Leak Repair", price: 80),
                    ServiceItem(name: "Drain Cleaning", price: 100),
                    ServiceItem(name: "Fixture Installation", price: 120)]
        case "Repairing":
            return [ServiceItem(name: "General Repair", price: 60),
                    ServiceItem(name: "Appliance Fix", price: 90)]
        case "Planning":
            return [ServiceItem(name: "Consultation", price: 50),
                    ServiceItem(name: "Project Planning", price: 150)]
        case "Gardening":
            return [ServiceItem(name: "Lawn Mowing", price: 45),
                    ServiceItem(name: "Tree Trimming", price: 80),
                    ServiceItem(name: "Fertilization", price: 60)]
        default:
            return [ServiceItem(name: "Standard Service", price: 75)]
        }
    }

    static let providers: [ServiceProvider] = [
        ServiceProvider(name: "Piper's Plumbing",    category: "Plumbing",  description: "Piper's Plumbing offers expert plumbing services, specializing in leak detection, drain cleaning, pipe repairs, and fixture installations. Our licensed plumbers ensure fast, reliable service with a satisfaction guarantee.", rating: 4.8, distanceMi: 2.4),
        ServiceProvider(name: "Net's a Handyman",    category: "Repairing", description: "Professional handyman services for all your repair and maintenance needs. Serving the area for over 10 years with 5-star rated service.", rating: 4.8, distanceMi: 1.2),
        ServiceProvider(name: "Best Planner in Town",category: "Planning",  description: "Expert project planning and consultation. We help you organize and execute your home improvement projects from start to finish.", rating: 4.5, distanceMi: 3.1),
        ServiceProvider(name: "Your Lawn Guy",       category: "Gardening", description: "Full-service lawn care and gardening. From mowing and trimming to fertilization and landscaping design.", rating: 4.7, distanceMi: 0.8)
    ]

    static let reviews: [(reviewer: String, rating: Int, date: String, text: String)] = [
        ("Sarah K.", 4, "2 months ago", "Absolutely fantastic service! Highly recommend for any plumbing emergencies!"),
        ("Mike R.", 5, "3 months ago", "Very professional, arrived on time and fixed everything quickly. Will use again."),
        ("Emily T.", 5, "1 month ago",  "Outstanding work! Clean, efficient, and reasonably priced.")
    ]

    static let orders: [ServiceOrder] = [
        ServiceOrder(providerName: "Piper's Plumbing", price: 97, date: "Dec 31", status: .reserved, services: [
            OrderLineItem(name: "Leak Repair", price: 22),
            OrderLineItem(name: "Drain Cleaning", price: 30),
            OrderLineItem(name: "Fixture Installation", price: 45)
        ]),
        ServiceOrder(providerName: "Spark Electrical", price: 199, date: "Aug 14", status: .canceled, services: [
            OrderLineItem(name: "Rewiring", price: 199)
        ]),
        ServiceOrder(providerName: "Clean Home Pro", price: 50, date: "Mar 13", status: .completed, services: [
            OrderLineItem(name: "House Cleaning", price: 50)
        ])
    ]
}
