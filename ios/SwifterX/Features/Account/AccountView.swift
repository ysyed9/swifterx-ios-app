import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager
    @State private var showPersonalInfo = false
    @State private var showLogOutAlert  = false
    @State private var showHelpSheet    = false
    @State private var showTermsSheet   = false
    @State private var showDeleteAlert  = false
    @State private var inboxMessagesOn  = true
    @State private var notificationsOn  = false

    private var displayName: String {
        profileManager.profile?.name.isEmpty == false
            ? profileManager.profile!.name
            : (authManager.displayName ?? "User")
    }
    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased().isEmpty ? "U" : letters.joined().uppercased()
    }

    let quickActions: [(title: String, icon: String, color: Color)] = [
        ("Favourite\nServices", "heart.fill",       Color(hex: "#093dc2")),
        ("Bookmark",            "bookmark.fill",     Color(hex: "#db4500")),
        ("Wallet",              "creditcard.fill",   Color(hex: "#704127")),
        ("Orders",              "doc.text.fill",     Color(hex: "#e6b70b"))
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {

                // Profile header
                HStack(spacing: 16) {
                    Circle()
                        .fill(.black)
                        .frame(width: 57, height: 57)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )

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

                // Quick action tiles
                HStack(spacing: 12) {
                    ForEach(quickActions, id: \.title) { action in
                        Button {
                            if action.title == "Orders" {
                                appState.activeTab = .orders
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

                // Notification Preferences
                AccountSection(title: "Notification Preferences") {
                    VStack(spacing: 20) {
                        ToggleRow(label: "Inbox messages", isOn: $inboxMessagesOn)
                        ToggleRow(label: "Notification",   isOn: $notificationsOn)
                    }
                }

                // Help & Policies
                AccountSection(title: "Help & Polices") {
                    VStack(spacing: 20) {
                        Button { showHelpSheet = true } label: {
                            ChevronRow(label: "Help")
                        }
                        .buttonStyle(.plain)

                        Button { showTermsSheet = true } label: {
                            ChevronRow(label: "Application Terms")
                        }
                        .buttonStyle(.plain)

                        Button { showDeleteAlert = true } label: {
                            ChevronRow(label: "Delete Account")
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Accounts Center
                AccountSection(title: "Accounts Center") {
                    VStack(spacing: 20) {
                        Button {} label: {
                            ChevronRow(label: "Add more accounts")
                        }
                        .buttonStyle(.plain)

                        Button {} label: {
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
        .sheet(isPresented: $showPersonalInfo) { PersonalInfoView() }
        .sheet(isPresented: $showHelpSheet) { InfoSheet(title: "Help", content: "For support, email us at support@swifterx.com or call (555) 000-1234. Our team is available Mon–Fri 9AM–6PM.") }
        .sheet(isPresented: $showTermsSheet) { InfoSheet(title: "Application Terms", content: "By using SwifterX you agree to our Terms of Service and Privacy Policy. All bookings are subject to provider availability. Cancellations must be made 2 hours before the scheduled time.") }
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
            Button("Log Out", role: .destructive) {
                try? authManager.signOut()
                // AppRootView's onChange(of: isSignedIn) handles the navigation
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
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
                    .padding(24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.black)
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
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black)
                .textCase(.none)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.black)
        }
    }
}

private struct ChevronRow: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black)
                .textCase(.none)
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
}
