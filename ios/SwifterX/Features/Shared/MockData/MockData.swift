import Foundation

enum MockData {
    static let categories: [(name: String, icon: String)] = [
        ("Cleaning",    "sparkles"),
        ("Repairing",   "wrench.and.screwdriver"),
        ("Painting",    "paintbrush"),
        ("Gardening",   "leaf"),
        ("Plumbing",    "drop"),
        ("Pest Control","shield"),
        ("Landscaping", "tree"),
        ("Electrician", "bolt"),
        ("Appliance\nMaintenance", "gearshape")
    ]

    static let providers: [ServiceProvider] = [
        ServiceProvider(
            id: "provider-pipers-plumbing",
            name: "Piper's Plumbing",
            category: "Plumbing",
            description: "Piper's Plumbing offers expert plumbing services, specializing in leak detection, drain cleaning, pipe repairs, and fixture installations. Our licensed plumbers ensure fast, reliable service with a satisfaction guarantee.",
            rating: 4.8, distanceMi: 2.4,
            imageName: "img_plumber_work",
            reviewCount: 214
        ),
        ServiceProvider(
            id: "provider-nets-handyman",
            name: "Net's a Handyman",
            category: "Repairing",
            description: "Professional handyman services for all your repair and maintenance needs. Serving the area for over 10 years with 5-star rated service.",
            rating: 4.8, distanceMi: 1.2,
            imageName: "img_repair_tech",
            reviewCount: 189
        ),
        ServiceProvider(
            id: "provider-your-lawn-guy",
            name: "Your Lawn Guy",
            category: "Gardening",
            description: "Full-service lawn care and gardening. From mowing and trimming to fertilization and landscaping design.",
            rating: 4.7, distanceMi: 0.8,
            imageName: "img_lawn_mowing",
            reviewCount: 156
        ),
        ServiceProvider(
            id: "provider-marcus-electric",
            name: "Marcus Electric",
            category: "Electrician",
            description: "Licensed and insured electrician with 20+ years experience. Specializing in rewiring, panel upgrades, and emergency electrical repairs. Available 24/7.",
            rating: 4.9, distanceMi: 1.5,
            imageName: "img_provider_marcus",
            reviewCount: 302
        ),
        ServiceProvider(
            id: "provider-jasmine-cleaning",
            name: "Jasmine Clean Co.",
            category: "Cleaning",
            description: "Top-rated residential and commercial cleaning service. Eco-friendly products, detailed attention, and flexible scheduling. Your home will shine.",
            rating: 4.9, distanceMi: 0.5,
            imageName: "img_provider_jasmine",
            reviewCount: 421
        ),
        ServiceProvider(
            id: "provider-james-pest",
            name: "James Pest Solutions",
            category: "Pest Control",
            description: "Safe, effective pest control for homes and businesses. Treating termites, rodents, ants, and more. Guaranteed results or we come back for free.",
            rating: 4.6, distanceMi: 3.8,
            imageName: "img_provider_james",
            reviewCount: 97
        ),
        ServiceProvider(
            id: "provider-swift-support",
            name: "Swift Home Services",
            category: "Repairing",
            description: "Full-service home concierge and project management team. We coordinate all your home service needs in one place so you never have to chase contractors.",
            rating: 4.7, distanceMi: 2.1,
            imageName: "img_customer_service",
            reviewCount: 178
        )
    ]

    static let providerServices: [String: [ServiceItem]] = {
        var dict = [String: [ServiceItem]]()
        for p in providers {
            dict[p.id] = serviceItems(for: p.category)
        }
        return dict
    }()

    static func serviceItems(for category: String) -> [ServiceItem] {
        switch category {
        case "Plumbing":
            return [
                ServiceItem(id: "plumbing-leak-repair",        name: "Leak Repair",          price: 80),
                ServiceItem(id: "plumbing-drain-cleaning",     name: "Drain Cleaning",        price: 100),
                ServiceItem(id: "plumbing-fixture-install",    name: "Fixture Installation",  price: 120)
            ]
        case "Repairing":
            return [
                ServiceItem(id: "repairing-general",           name: "General Repair",        price: 60),
                ServiceItem(id: "repairing-appliance",         name: "Appliance Fix",         price: 90)
            ]
        case "Planning":
            return [
                ServiceItem(id: "planning-consultation",       name: "Consultation",          price: 50),
                ServiceItem(id: "planning-project",            name: "Project Planning",      price: 150)
            ]
        case "Gardening":
            return [
                ServiceItem(id: "gardening-mowing",            name: "Lawn Mowing",           price: 45),
                ServiceItem(id: "gardening-trimming",          name: "Tree Trimming",         price: 80),
                ServiceItem(id: "gardening-fertilization",     name: "Fertilization",         price: 60)
            ]
        case "Electrician":
            return [
                ServiceItem(id: "electric-panel-upgrade",      name: "Panel Upgrade",         price: 350),
                ServiceItem(id: "electric-rewiring",           name: "Rewiring",              price: 200),
                ServiceItem(id: "electric-outlet-install",     name: "Outlet Installation",   price: 85),
                ServiceItem(id: "electric-ceiling-fan",        name: "Ceiling Fan Install",   price: 120)
            ]
        case "Cleaning":
            return [
                ServiceItem(id: "cleaning-standard",           name: "Standard Clean",        price: 80),
                ServiceItem(id: "cleaning-deep",               name: "Deep Clean",            price: 150),
                ServiceItem(id: "cleaning-move-in-out",        name: "Move In/Out Clean",     price: 220),
                ServiceItem(id: "cleaning-windows",            name: "Window Cleaning",       price: 65)
            ]
        case "Pest Control":
            return [
                ServiceItem(id: "pest-inspection",             name: "Pest Inspection",       price: 60),
                ServiceItem(id: "pest-termite",                name: "Termite Treatment",     price: 300),
                ServiceItem(id: "pest-rodent",                 name: "Rodent Control",        price: 150),
                ServiceItem(id: "pest-general",                name: "General Pest Spray",    price: 90)
            ]
        default:
            return [ServiceItem(id: "default-standard",       name: "Standard Service",      price: 75)]
        }
    }

    static let mockReviews: [Review] = [
        Review(
            id: "review-1",
            providerID: "provider-pipers-plumbing",
            customerUID: "mock-user",
            customerName: "Sarah K.",
            rating: 4,
            comment: "Absolutely fantastic service! Highly recommend for any plumbing emergencies!",
            createdAt: Date(timeIntervalSinceNow: -60 * 24 * 3600)
        ),
        Review(
            id: "review-2",
            providerID: "provider-pipers-plumbing",
            customerUID: "mock-user-2",
            customerName: "Mike R.",
            rating: 5,
            comment: "Very professional, arrived on time and fixed everything quickly. Will use again.",
            createdAt: Date(timeIntervalSinceNow: -90 * 24 * 3600)
        ),
        Review(
            id: "review-3",
            providerID: "provider-pipers-plumbing",
            customerUID: "mock-user-3",
            customerName: "Emily T.",
            rating: 5,
            comment: "Outstanding work! Clean, efficient, and reasonably priced.",
            createdAt: Date(timeIntervalSinceNow: -30 * 24 * 3600)
        )
    ]

    static let orders: [ServiceOrder] = [
        ServiceOrder(
            id: "mock-order-1",
            providerName: "Piper's Plumbing",
            price: 97,
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31)) ?? Date(),
            status: .confirmed,
            services: [
                OrderLineItem(id: "li-1", name: "Leak Repair",         price: 22),
                OrderLineItem(id: "li-2", name: "Drain Cleaning",       price: 30),
                OrderLineItem(id: "li-3", name: "Fixture Installation", price: 45)
            ],
            paymentStatus: .paid
        ),
        ServiceOrder(
            id: "mock-order-2",
            providerName: "Spark Electrical",
            price: 199,
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 14)) ?? Date(),
            status: .cancelled,
            services: [
                OrderLineItem(id: "li-4", name: "Rewiring", price: 199)
            ],
            paymentStatus: .paid
        ),
        ServiceOrder(
            id: "mock-order-3",
            providerName: "Clean Home Pro",
            price: 50,
            scheduledDate: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 13)) ?? Date(),
            status: .completed,
            services: [
                OrderLineItem(id: "li-5", name: "House Cleaning", price: 50)
            ],
            paymentStatus: .paid
        )
    ]
}
