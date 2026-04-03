import SwiftUI

enum UserRole: String {
    case customer
    case provider
}

enum ProviderTab: Hashable {
    case home
    case services
    case schedule
    case account
}

enum AppScreen {
    case splash
    case roleSelect
    case login
    case main
    case providerMain
}

class AppState: ObservableObject {
    /// Persisted so relaunch restores customer vs provider experience.
    static let userRoleDefaultsKey = "swifterx_user_role"

    @Published var screen: AppScreen = .splash
    @Published var activeTab: AppTab = .home
    @Published var userRole: UserRole = .customer
    @Published var providerActiveTab: ProviderTab = .home

    /// Switch between customer and provider dashboards (same login). Persists preference.
    func switchRole(to role: UserRole) {
        userRole = role
        UserDefaults.standard.set(role.rawValue, forKey: Self.userRoleDefaultsKey)
        activeTab = .home
        providerActiveTab = .home
        withAnimation(.easeInOut(duration: 0.35)) {
            screen = role == .provider ? .providerMain : .main
        }
    }
}

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @EnvironmentObject private var authManager:    AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager
    @EnvironmentObject private var dataService:    DataService
    @EnvironmentObject private var orderManager:   OrderManager

    var body: some View {
        Group {
            if authManager.isLoading {
                SplashView(onFinished: {})
            } else {
                switch appState.screen {
                case .splash:
                    SplashView {
                        withAnimation {
                            if authManager.isSignedIn {
                                restoreRoleFromDefaults()
                                appState.screen = appState.userRole == .provider ? .providerMain : .main
                            } else {
                                appState.screen = .roleSelect
                            }
                        }
                    }

                case .roleSelect:
                    RoleSelectView(
                        onCustomer: {
                            appState.userRole = .customer
                            withAnimation { appState.screen = .login }
                        },
                        onProvider: {
                            appState.userRole = .provider
                            withAnimation { appState.screen = .login }
                        }
                    )

                case .login:
                    LoginView {
                        UserDefaults.standard.set(appState.userRole.rawValue, forKey: AppState.userRoleDefaultsKey)
                        withAnimation {
                            appState.screen = appState.userRole == .provider ? .providerMain : .main
                        }
                    }

                case .main:
                    mainTabView
                        .onAppear {
                            if let uid = authManager.userUID {
                                profileManager.startListening(uid: uid)
                            }
                        }

                case .providerMain:
                    providerTabView
                        .onAppear {
                            if let uid = authManager.userUID {
                                profileManager.startListening(uid: uid)
                            }
                        }
                }
            }
        }
        .environmentObject(appState)
        .task(id: appState.screen) {
            syncOrderListening(for: appState.screen)
        }
        .onChange(of: authManager.isSignedIn) { isSignedIn in
            if !isSignedIn {
                profileManager.stopListening()
                orderManager.stopListening()
                orderManager.stopListeningAsProvider()
                withAnimation { appState.screen = .login }
            }
        }
    }

    private func restoreRoleFromDefaults() {
        if let raw = UserDefaults.standard.string(forKey: AppState.userRoleDefaultsKey),
           let role = UserRole(rawValue: raw) {
            appState.userRole = role
        } else {
            appState.userRole = .customer
        }
    }

    /// Start the correct order listener based on which mode is active.
    private func syncOrderListening(for screen: AppScreen) {
        guard let uid = authManager.userUID else { return }
        switch screen {
        case .main:
            orderManager.stopListeningAsProvider()
            orderManager.startListening(uid: uid)
        case .providerMain:
            orderManager.stopListening()
            orderManager.startListeningAsProvider(uid: uid)
        default:
            break
        }
    }

    private var mainTabView: some View {
        TabView(selection: $appState.activeTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home",     systemImage: "house") }
                .tag(AppTab.home)

            NavigationStack { ServicesView() }
                .tabItem { Label("Services", systemImage: "list.bullet") }
                .tag(AppTab.services)

            NavigationStack { OrdersView() }
                .tabItem { Label("Orders",   systemImage: "doc.text") }
                .tag(AppTab.orders)

            NavigationStack { AccountView() }
                .tabItem { Label("Account",  systemImage: "person") }
                .tag(AppTab.account)
        }
        .tint(.white)
        .onAppear { configureTabBar() }
    }

    private var providerTabView: some View {
        TabView(selection: $appState.providerActiveTab) {
            NavigationStack { ProviderHomeView() }
                .tabItem { Label("Home",     systemImage: "house") }
                .tag(ProviderTab.home)

            NavigationStack { ProviderServicesView() }
                .tabItem { Label("Services", systemImage: "magnifyingglass") }
                .tag(ProviderTab.services)

            NavigationStack { ProviderScheduleView() }
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(ProviderTab.schedule)

            NavigationStack { ProviderAccountView() }
                .tabItem { Label("Account",  systemImage: "person") }
                .tag(ProviderTab.account)
        }
        .tint(.white)
        .onAppear { configureTabBar() }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        let item = UITabBarItemAppearance()
        item.normal.iconColor                    = .white
        item.normal.titleTextAttributes          = [.foregroundColor: UIColor.white]
        item.selected.iconColor                  = .white
        item.selected.titleTextAttributes        = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance       = item
        appearance.inlineLayoutAppearance        = item
        appearance.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    AppRootView()
        .environmentObject(AuthManager())
        .environmentObject(UserProfileManager())
        .environmentObject(DataService(client: MockAPIClient.shared))
        .environmentObject(OrderManager())
}
