import SwiftUI
import PhotosUI

struct ProviderPublicProfileView: View {
    @EnvironmentObject private var providerProfileManager: ProviderProfileManager
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var dataService: DataService

    @State private var isEditing = false
    @State private var editBio = ""
    @State private var editRate = ""
    @State private var editRadius = ""
    @State private var editCategories: Set<String> = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isSaving = false
    @State private var saveError: String?

    private var profile: ProviderProfile? { providerProfileManager.profile }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header card
                headerCard

                if isEditing {
                    editSection
                } else {
                    readSection
                }

                Spacer().frame(height: 40)
            }
        }
        .background(Color.white)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { Task { await saveEdits() } }
                    else         { startEditing() }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)
            }
        }
    }

    // MARK: - Header card

    private var headerCard: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else if let url = URL(string: profile?.photoURL ?? ""), !(profile?.photoURL ?? "").isEmpty {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase { image.resizable().scaledToFill() }
                            else { placeholderAvatar }
                        }
                    } else {
                        placeholderAvatar
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())

                if isEditing {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                            )
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

            Text(profile?.name ?? authManager.displayName ?? "Your Name")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)

            if let p = profile, p.isOnboarded, !p.isApprovedForJobs {
                if let reason = p.trimmedRejectionReason {
                    Text("Not approved: \(reason)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#92400e"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                } else {
                    Text("Under review — you will appear in search and can accept jobs after SwifterX approves your profile.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#666666"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            // Rating + reviews
            if let p = profile, p.rating > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.black)
                    Text(String(format: "%.1f", p.rating))
                        .font(.system(size: 14, weight: .semibold))
                    Text("(\(p.reviewCount) reviews)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#888888"))
                }
            }

            // Category pills
            let cats = isEditing ? Array(editCategories) : (profile?.serviceCategories ?? [])
            if !cats.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cats, id: \.self) { cat in
                            Text(cat)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#f2f2f2"))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white)
    }

    // MARK: - Read view

    private var readSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            infoRow(icon: "dollarsign.circle", label: "Hourly rate",
                    value: profile.map { "$\(Int($0.hourlyRate))/hr" } ?? "–")
            Divider().padding(.leading, 52)
            infoRow(icon: "location.circle", label: "Service radius",
                    value: profile.map { "\(Int($0.serviceRadiusMiles)) miles" } ?? "–")
            Divider().padding(.leading, 52)

            if let bio = profile?.bio, !bio.isEmpty {
                infoRow(icon: "text.bubble", label: "About", value: bio)
                Divider().padding(.leading, 52)
            }

            // Availability
            let days = profile?.availability ?? []
            if !days.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                            .frame(width: 24)
                        Text("Availability")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                    ForEach(days) { day in
                        HStack {
                            Text(day.day)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 36, alignment: .leading)
                            if day.isAvailable {
                                Text("\(day.startLabel) – \(day.endLabel)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#444444"))
                            } else {
                                Text("Unavailable")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#bbbbbb"))
                            }
                        }
                        .padding(.horizontal, 62)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color.white)
    }

    // MARK: - Edit view

    private var editSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                editField(label: "Hourly rate ($/hr)", text: $editRate, keyboard: .decimalPad)
                editField(label: "Service radius (miles)", text: $editRadius, keyboard: .decimalPad)
                editBioField
            }
            .padding(.horizontal, 24)

            // Category multi-select
            VStack(alignment: .leading, spacing: 10) {
                Text("Services offered")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#444444"))
                    .padding(.horizontal, 24)

                let cats = dataService.categories.map(\.name).isEmpty
                    ? ["Plumbing","Electrician","Cleaning","Lawn Care","Painting","Repairing","Pest Control","Handyman"]
                    : dataService.categories.map(\.name)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(cats, id: \.self) { cat in
                        categoryChip(cat)
                    }
                }
                .padding(.horizontal, 24)
            }

            if isSaving {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Helpers

    private var placeholderAvatar: some View {
        Circle()
            .fill(Color(hex: "#f2f2f2"))
            .overlay(Image(systemName: "person.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#cccccc")))
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#888888"))
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func editField(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#444444"))
            TextField("", text: text)
                .keyboardType(keyboard)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(hex: "#f5f5f5"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var editBioField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About / Bio")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#444444"))
            ZStack(alignment: .topLeading) {
                if editBio.isEmpty {
                    Text("Tell customers about yourself…")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#cccccc"))
                        .padding(14)
                }
                TextEditor(text: $editBio)
                    .font(.system(size: 14))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(hex: "#f5f5f5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func categoryChip(_ name: String) -> some View {
        let selected = editCategories.contains(name)
        return Button {
            if selected { editCategories.remove(name) } else { editCategories.insert(name) }
        } label: {
            Text(name)
                .font(.system(size: 14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(selected ? Color.black : Color(hex: "#f2f2f2"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startEditing() {
        if let p = profile {
            editBio      = p.bio
            editRate     = String(Int(p.hourlyRate))
            editRadius   = String(Int(p.serviceRadiusMiles))
            editCategories = Set(p.serviceCategories)
        }
        isEditing = true
    }

    private func saveEdits() async {
        guard var p = profile else { isEditing = false; return }
        isSaving = true
        saveError = nil

        if let img = profileImage, let uid = authManager.userUID {
            do {
                p.photoURL = try await ProviderProfilePhotoStorage.uploadProviderProfilePhoto(uid: uid, image: img)
            } catch {
                saveError = (error as? LocalizedError)?.errorDescription ?? "Photo upload failed."
                isSaving = false
                return
            }
        }

        p.bio                = editBio
        p.hourlyRate         = Double(editRate) ?? p.hourlyRate
        p.serviceRadiusMiles = Double(editRadius) ?? p.serviceRadiusMiles
        p.serviceCategories  = Array(editCategories)
        do {
            try await providerProfileManager.save(p)
            profileImage = nil
            selectedPhoto = nil
            isEditing = false
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
