import SwiftUI
import PhotosUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject private var appState:      AppState
    @EnvironmentObject private var authManager:   AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var showPersonalInfo  = false
    @State private var showLogOutAlert   = false
    @State private var showHelpSheet     = false
    @State private var showTermsSheet    = false
    @State private var showDeleteAlert   = false
    @State private var showWallet        = false
    @State private var showFavorites     = false
    @State private var showBookmarks     = false
    @State private var inboxMessagesOn   = true
    @State private var notificationsOn   = false

    // Profile picture
    @State private var profileImage:     Image?
    @State private var photosItem:       PhotosPickerItem?

    private var displayName: String {
        profileManager.profile?.name.isEmpty == false
            ? profileManager.profile!.name
            : (authManager.displayName ?? "User")
    }
    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        let joined = letters.joined().uppercased()
        return joined.isEmpty ? "U" : joined
    }

    let quickActions: [(title: String, icon: String, color: Color)] = [
        ("Favourite\nServices", "heart.fill",     Color(hex: "#093dc2")),
        ("Bookmark",            "bookmark.fill",   Color(hex: "#db4500")),
        ("Wallet",              "creditcard.fill", Color(hex: "#704127")),
        ("Orders",              "doc.text.fill",   Color(hex: "#e6b70b"))
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {

                // MARK: Profile header
                HStack(spacing: 16) {
                    PhotosPicker(selection: $photosItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.black
                                        .overlay(
                                            Text(initials)
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(.white)
                                        )
                                }
                            }
                            .frame(width: 57, height: 57)
                            .clipShape(Circle())

                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.black)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }
                    .onChange(of: photosItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                                // Persist to disk
                                UserDefaults.standard.set(data, forKey: "swifterx_pfp_data")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hi, \(displayName)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.black)
                        Text(authManager.userEmail ?? "")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.black)
                    }

                    Spacer()

                    Button { showPersonalInfo = true } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: Quick action tiles
                HStack(spacing: 12) {
                    ForEach(quickActions, id: \.title) { action in
                        Button {
                            switch action.title {
                            case "Orders":             appState.activeTab = .orders
                            case "Wallet":             showWallet    = true
                            case "Bookmark":           showBookmarks = true
                            case "Favourite\nServices": showFavorites = true
                            default: break
                            }
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(action.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: action.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white)
                                    )
                                Text(action.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.black)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 84)
                            .background(Color(hex: "#f7f7f7"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                // MARK: App mode switch
                AccountSection(title: "App Mode") {
                    Button { appState.switchRole(to: .provider) } label: {
                        HStack {
                            Text("Switch to Provider dashboard")
                                .font(.system(size: 16))
                                .foregroundStyle(.black)
                            Spacer()
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.black)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // MARK: Notification Preferences
                AccountSection(title: "Notification Preferences") {
                    VStack(spacing: 20) {
                        ToggleRow(label: "Inbox messages", isOn: $inboxMessagesOn)
                        ToggleRow(label: "Notifications",  isOn: $notificationsOn)
                    }
                }

                // MARK: Help & Policies
                AccountSection(title: "Help & Policies") {
                    VStack(spacing: 20) {
                        Button { showHelpSheet  = true } label: { ChevronRow(label: "Help") }.buttonStyle(.plain)
                        Button { showTermsSheet = true } label: { ChevronRow(label: "Application Terms") }.buttonStyle(.plain)
                        Button { showDeleteAlert = true } label: { ChevronRow(label: "Delete Account") }.buttonStyle(.plain)
                    }
                }

                // MARK: Accounts Center
                AccountSection(title: "Accounts Center") {
                    VStack(spacing: 20) {
                        // "Add more accounts" opens login screen
                        Button { try? authManager.signOut() } label: {
                            ChevronRow(label: "Add more accounts")
                        }
                        .buttonStyle(.plain)

                        Button { showTermsSheet = true } label: {
                            ChevronRow(label: "Ad Preference")
                        }
                        .buttonStyle(.plain)

                        Button { showLogOutAlert = true } label: {
                            HStack {
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer().frame(height: 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { loadSavedProfileImage() }

        // MARK: Sheets & navigation
        .sheet(isPresented: $showPersonalInfo) { PersonalInfoView() }
        .sheet(isPresented: $showWallet) { WalletView() }
        .sheet(isPresented: $showHelpSheet) {
            InfoSheet(title: "Help", content: "For support, email us at support@swifterx.com or call (555) 000-1234.\n\nOur team is available Mon–Fri 9AM–6PM.")
        }
        .sheet(isPresented: $showTermsSheet) {
            InfoSheet(title: "Application Terms", content: "By using SwifterX you agree to our Terms of Service and Privacy Policy.\n\nAll bookings are subject to provider availability. Cancellations must be made 2 hours before the scheduled time.\n\nFor full terms visit swifterx.com/terms")
        }
        .navigationDestination(isPresented: $showFavorites) { FavoritesView() }
        .navigationDestination(isPresented: $showBookmarks) { BookmarksView() }

        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if let uid = authManager.userUID {
                        try? await profileManager.deleteProfile(uid: uid)
                    }
                    try? await Auth.auth().currentUser?.delete()
                }
            }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
        .alert("Log Out?", isPresented: $showLogOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { try? authManager.signOut() }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Helpers

    private func loadSavedProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "swifterx_pfp_data"),
           let uiImage = UIImage(data: data) {
            profileImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Bookmarks (alias for Favourites with bookmark icon framing)

struct BookmarksView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        FavoritesView()
            .navigationTitle("Bookmarks")
    }
}

// MARK: - Info Sheet

private struct InfoSheet: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .lineSpacing(4)
                    .padding(24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.black)
                }
            }
        }
    }
}

// MARK: - Helpers

private struct AccountSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 30)
            content()
                .padding(10)
                .background(Color(hex: "#f9f9f9"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 20)
        }
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.black)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.black)
        }
    }
}

private struct ChevronRow: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    NavigationStack { AccountView() }
        .environmentObject(AppState())
        .environmentObject(AuthManager())
        .environmentObject(UserProfileManager())
        .environmentObject(FavoritesStore())
}
