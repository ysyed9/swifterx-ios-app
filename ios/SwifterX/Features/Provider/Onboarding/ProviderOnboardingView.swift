import SwiftUI
import PhotosUI

// MARK: - Main Onboarding Shell

struct ProviderOnboardingView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var providerProfileManager: ProviderProfileManager
    @EnvironmentObject private var dataService: DataService

    @State private var step = 0
    @State private var draft = ProviderProfile(id: "")

    // Step 1 — Services & details
    @State private var selectedCategories: Set<String> = []
    @State private var hourlyRateText = "50"
    @State private var serviceRadiusText = "10"
    @State private var bio = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?

    // Step 2 — Availability
    @State private var availability = DayAvailability.defaultWeek

    // Step 3 — Background check
    @State private var bgConsented = false

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            stepContent
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .id(step)
        }
        .background(Color.white)
        .onAppear {
            if let uid = authManager.userUID {
                draft.id = uid
                draft.name = authManager.displayName ?? ""
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.black : Color(hex: "#e0e0e0"))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: step0
        case 1: step1
        case 2: step2
        default: EmptyView()
        }
    }

    // MARK: - Step 0: Services, rate, radius, bio, photo

    private var step0: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                stepHeader(
                    number: "1 of 3",
                    title: "Your services",
                    subtitle: "Tell us what you offer and set your rate."
                )

                // Photo picker
                VStack(alignment: .leading, spacing: 10) {
                    label("Profile photo")
                    HStack(spacing: 16) {
                        Group {
                            if let img = profileImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(hex: "#999999"))
                            }
                        }
                        .frame(width: 72, height: 72)
                        .background(Color(hex: "#f2f2f2"))
                        .clipShape(Circle())

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Choose photo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.black)
                                .clipShape(Capsule())
                        }
                        .onChange(of: selectedPhoto) { item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img  = UIImage(data: data) {
                                    profileImage = img
                                }
                            }
                        }
                    }
                }

                // Service categories
                VStack(alignment: .leading, spacing: 10) {
                    label("Services offered (select all that apply)")
                    let cats = dataService.categories.map(\.name)
                    let displayed = cats.isEmpty
                        ? ["Plumbing","Electrician","Cleaning","Lawn Care","Painting","Repairing","Pest Control","Handyman"]
                        : cats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(displayed, id: \.self) { cat in
                            categoryChip(cat)
                        }
                    }
                }

                // Hourly rate
                VStack(alignment: .leading, spacing: 10) {
                    label("Hourly rate (USD)")
                    HStack {
                        Text("$")
                            .font(.system(size: 16, weight: .medium))
                        TextField("50", text: $hourlyRateText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16))
                            .sanitized($hourlyRateText, using: InputSanitizer.hourlyRate)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(hex: "#f5f5f5"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Service radius
                VStack(alignment: .leading, spacing: 10) {
                    label("Service radius")
                    HStack {
                        TextField("10", text: $serviceRadiusText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16))
                            .sanitized($serviceRadiusText, using: InputSanitizer.serviceRadius)
                        Text("miles")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#888888"))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(hex: "#f5f5f5"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Bio
                VStack(alignment: .leading, spacing: 10) {
                    label("Bio")
                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Tell customers about yourself and your experience…")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#bbbbbb"))
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                        }
                        TextEditor(text: $bio)
                            .font(.system(size: 14))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .sanitized($bio, using: InputSanitizer.bio)
                    }
                    .background(Color(hex: "#f5f5f5"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                nextButton(title: "Continue") {
                    withAnimation { step = 1 }
                }
                .disabled(selectedCategories.isEmpty)
                .opacity(selectedCategories.isEmpty ? 0.45 : 1)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 1: Availability

    private var step1: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                stepHeader(
                    number: "2 of 3",
                    title: "Your schedule",
                    subtitle: "Set the days and hours you're available to take jobs."
                )

                VStack(spacing: 14) {
                    ForEach($availability) { $day in
                        availabilityRow($day)
                    }
                }

                nextButton(title: "Continue") {
                    withAnimation { step = 2 }
                }

                backButton()
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 2: Background check consent

    private var step2: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    stepHeader(
                        number: "3 of 3",
                        title: "Background check",
                        subtitle: "SwifterX is a trust-first platform. We require all providers to consent to a background check before going live."
                    )

                    // What it covers
                    VStack(alignment: .leading, spacing: 14) {
                        label("What we check")
                        checkItem(icon: "checkmark.shield.fill", text: "Criminal background")
                        checkItem(icon: "checkmark.shield.fill", text: "Sex offender registry")
                        checkItem(icon: "checkmark.shield.fill", text: "Identity verification")
                    }

                    // Note
                    Text("Background checks are conducted by a third-party partner. You will receive an email with instructions after completing this onboarding.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#888888"))
                        .padding(14)
                        .background(Color(hex: "#f5f5f5"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Consent toggle
                    HStack(alignment: .top, spacing: 12) {
                        Toggle("", isOn: $bgConsented)
                            .labelsHidden()
                            .tint(.black)
                        Text("I consent to a background check and certify that the information I have provided is accurate and complete.")
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }

                    nextButton(title: isSaving ? "Saving…" : "Complete setup") {
                        Task { await submit() }
                    }
                    .disabled(!bgConsented || isSaving)
                    .opacity(!bgConsented || isSaving ? 0.45 : 1)

                    backButton()
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Helpers

    private func categoryChip(_ name: String) -> some View {
        let selected = selectedCategories.contains(name)
        return Button {
            if selected { selectedCategories.remove(name) }
            else         { selectedCategories.insert(name) }
        } label: {
            Text(name)
                .font(.system(size: 14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.black : Color(hex: "#f2f2f2"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? Color.clear : Color(hex: "#e0e0e0"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func availabilityRow(_ day: Binding<DayAvailability>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: day.isAvailable) {
                    Text(day.wrappedValue.day)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .tint(.black)
            }

            if day.wrappedValue.isAvailable {
                HStack(spacing: 12) {
                    timePicker(label: "From", hour: day.startHour)
                    Text("→")
                        .foregroundStyle(Color(hex: "#888888"))
                    timePicker(label: "To", hour: day.endHour)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#f8f8f8"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func timePicker(label: String, hour: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#888888"))
            Picker("", selection: hour) {
                ForEach(6..<22, id: \.self) { h in
                    Text(hourLabel(h)).tag(h)
                }
            }
            .pickerStyle(.menu)
            .tint(.black)
            .labelsHidden()
            .frame(height: 32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h % 12 == 0 ? 12 : h % 12
        return "\(display):00 \(suffix)"
    }

    private func checkItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.black)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.black)
        }
    }

    private func stepHeader(number: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#888888"))
                .tracking(0.5)
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.black)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#666666"))
        }
        .padding(.top, 8)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "#444444"))
    }

    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.black)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func backButton() -> some View {
        Button { withAnimation { step -= 1 } } label: {
            Text("Back")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#666666"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit

    private func submit() async {
        guard let uid = authManager.userUID else { return }

        let cleanBio    = InputSanitizer.bio(bio)
        let cleanRate   = InputSanitizer.hourlyRate(hourlyRateText)
        let cleanRadius = InputSanitizer.serviceRadius(serviceRadiusText)

        if let err = InputSanitizer.validateHourlyRate(cleanRate) { errorMessage = err; return }
        if let err = InputSanitizer.validateServiceRadius(cleanRadius) { errorMessage = err; return }

        isSaving = true
        errorMessage = nil

        var profile = ProviderProfile(
            id: uid,
            name: InputSanitizer.name(authManager.displayName ?? draft.name),
            bio: cleanBio,
            serviceCategories: Array(selectedCategories),
            hourlyRate: Double(cleanRate) ?? 50,
            serviceRadiusMiles: Double(cleanRadius) ?? 10,
            availability: availability,
            backgroundCheckConsented: bgConsented,
            backgroundCheckConsentDate: Date(),
            isOnboarded: true,
            approved: false
        )

        if let img = profileImage {
            do {
                profile.photoURL = try await ProviderProfilePhotoStorage.uploadProviderProfilePhoto(uid: uid, image: img)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Could not upload your photo. Try again."
                isSaving = false
                return
            }
        }

        do {
            try await providerProfileManager.save(profile)
            isSaving = false
            onComplete()
        } catch {
            errorMessage = "Failed to save profile. Please try again."
            isSaving = false
        }
    }
}
