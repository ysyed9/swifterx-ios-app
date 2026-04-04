import SwiftUI
import FirebaseAuth

struct ProviderAccountView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager
    @EnvironmentObject private var providerProfileManager: ProviderProfileManager

    @State private var showPersonalInfo = false
    @State private var showLogOutAlert  = false
    @State private var showDeleteAlert  = false

    private var displayName: String {
        profileManager.profile?.name.isEmpty == false
            ? profileManager.profile!.name
            : (authManager.displayName ?? "John Doe")
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased().isEmpty ? "JD" : letters.joined().uppercased()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header — Figma: grey circle, Hi name, edit
                HStack(alignment: .center, spacing: 19) {
                    Circle()
                        .fill(Color(hex: "#dbdbdb"))
                        .frame(width: 55, height: 55)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.black)
                        )

                    Text("Hi, \(displayName)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer()

                    Button { showPersonalInfo = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)

                // Same login — switch back to customer booking experience
                providerSection(title: "App Mode") {
                    Button {
                        appState.switchRole(to: .customer)
                    } label: {
                        ProviderChevronRow(title: "Switch to Customer dashboard")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)

                // profile
                providerSection(title: "profile") {
                    VStack(spacing: 20) {
                        NavigationLink {
                            ProviderPublicProfileView()
                        } label: {
                            ProviderChevronRow(title: "My Public Profile")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PersonalInfoView()
                        } label: {
                            ProviderChevronRow(title: "Personal Info")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Customer History", message: "Past jobs and repeat customers will appear here.")
                        } label: {
                            ProviderChevronRow(title: "Customer History")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 28)

                // Payouts
                providerSection(title: "Earnings & Payouts") {
                    NavigationLink {
                        ProviderPayoutView()
                    } label: {
                        HStack {
                            Label("Payouts & Earnings", systemImage: "banknote")
                                .font(.system(size: 15))
                                .foregroundStyle(.black)
                            Spacer()
                            if let profile = providerProfileManager.profile {
                                Circle()
                                    .fill(profile.payoutsEnabled ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#aaaaaa"))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 28)

                // Manage Services
                providerSection(title: "Manage Services") {
                    VStack(spacing: 20) {
                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Leak Repair", message: "Edit pricing, duration, and description for this service.")
                        } label: {
                            ProviderChevronRow(title: "Leak Repair")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Drain Cleaning", message: "Edit pricing, duration, and description for this service.")
                        } label: {
                            ProviderChevronRow(title: "Drain Cleaning")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Fixture Installation", message: "Edit pricing, duration, and description for this service.")
                        } label: {
                            ProviderChevronRow(title: "Fixture Installation")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 28)

                // Banking
                providerSection(title: "Banking") {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Weekly Earnings")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("$0.00")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Earning History", message: "Weekly and monthly payouts will be listed here.")
                        } label: {
                            ProviderChevronRow(title: "Earning History")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProviderPlaceholderDetail(title: "Deposit Information", message: "Bank account and routing details for deposits.")
                        } label: {
                            ProviderChevronRow(title: "Deposit Information")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 28)

                // Manage Account
                providerSection(title: "Manage Account") {
                    VStack(spacing: 20) {
                        NavigationLink {
                            PersonalInfoView()
                        } label: {
                            ProviderChevronRow(title: "Edit Profile")
                        }
                        .buttonStyle(.plain)

                        Button { showLogOutAlert = true } label: {
                            ProviderChevronRow(title: "Log Out")
                        }
                        .buttonStyle(.plain)

                        Button { showDeleteAlert = true } label: {
                            HStack {
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.red)
                                    .textCase(.none)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.black)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 28)

                Spacer().frame(height: 40)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .sheet(isPresented: $showPersonalInfo) {
            PersonalInfoView()
        }
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
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private func providerSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .textCase(.lowercase)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

            content()
                .padding(.horizontal, 32)
        }
    }
}

private struct ProviderChevronRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
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

private struct ProviderPlaceholderDetail: View {
    let title: String
    let message: String

    var body: some View {
        ScrollView {
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#383838"))
                .padding(24)
        }
        .background(Color.white)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProviderAccountView()
    }
    .environmentObject(AppState())
    .environmentObject(AuthManager())
    .environmentObject(UserProfileManager())
}
