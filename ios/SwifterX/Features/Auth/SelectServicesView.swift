import SwiftUI

struct SelectServicesView: View {
    @State private var selected: Set<String> = []
    var onContinue: () -> Void
    var onSkip: () -> Void

    let services: [(name: String, icon: String)] = [
        ("Cleaning",    "sparkles"),
        ("Repairing",   "wrench.and.screwdriver"),
        ("Painting",    "paintbrush"),
        ("Plumbing",    "drop"),
        ("Pest Control","shield.lefthalf.filled"),
        ("Landscaping", "leaf"),
        ("Electrician", "bolt"),
        ("Appliance\nMaintenance","gearshape")
    ]

    let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)

                    Text("Select your \nservices you Need")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)

                    Spacer().frame(height: 12)

                    Text("Lorem ipsum dolor sit amet consectetur. Faucibus sit non nibh orci scelerisque gravida.")
                        .font(.system(size: 13, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)
                        .frame(width: 301)

                    Spacer().frame(height: 30)

                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(services, id: \.name) { service in
                            ServiceTileView(
                                name: service.name,
                                icon: service.icon,
                                isSelected: selected.contains(service.name)
                            )
                            .onTapGesture {
                                if selected.contains(service.name) {
                                    selected.remove(service.name)
                                } else {
                                    selected.insert(service.name)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 32)

                    Button {
                        onContinue()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .buttonStyle(.plain)

                    Spacer().frame(height: 40)
                }
            }

            Button {
                onSkip()
            } label: {
                Text("Skip")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ServiceTileView: View {
    let name: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 155)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.black.opacity(0.6) : Color.black, lineWidth: isSelected ? 3 : 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    SelectServicesView(onContinue: {}, onSkip: {})
}
