import SwiftUI

struct ProviderScheduleAppointment: Identifiable {
    let id = UUID()
    var title: String
    var detail: String
}

struct ProviderScheduleView: View {
    @State private var selectedDate = Date()
    @State private var showAddSheet = false
    @State private var appointments: [ProviderScheduleAppointment] = [
        ProviderScheduleAppointment(
            title: "New Job for Client Ashley for Plumbing Job.",
            detail: "10:00 AM"
        ),
        ProviderScheduleAppointment(
            title: "New Job for Client Sam for Plumbing Job.",
            detail: "2:00 PM"
        )
    ]

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yy"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Month / Year row (Figma)
                    HStack {
                        Spacer()
                        Text(monthYearString(from: selectedDate))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.black)
                    .padding(.horizontal, 8)
                    .environment(\.locale, Locale(identifier: "en_US_POSIX"))

                    Text("Today: \(todayString)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(hex: "#a2a2a2"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Text("Up Coming Appointments")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    ForEach(filteredAppointments) { apt in
                        appointmentRow(apt)
                    }

                    if filteredAppointments.isEmpty {
                        Text("No appointments for this day.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#828282"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }

                    Spacer().frame(height: 100)
                }
            }
            .background(Color.white)

            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 38))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.black, .white)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 100)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                VStack {
                    Text("Add appointment")
                        .font(.headline)
                        .padding(.top, 24)
                    Text("Schedule a new job from here. (Connect to calendar backend in a future phase.)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#828282"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showAddSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var filteredAppointments: [ProviderScheduleAppointment] {
        appointments
    }

    private func monthYearString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func appointmentRow(_ apt: ProviderScheduleAppointment) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(apt.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text(apt.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#828282"))
            }
            Spacer()
            Text("More +")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#f0f0f0"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack { ProviderScheduleView() }
}
