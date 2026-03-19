import SwiftUI

enum AppScreen {
    case splash
    case roleSelect
    case login
    case main
}

class AppState: ObservableObject {
    @Published var screen: AppScreen = .splash
    @Published var activeTab: AppTab = .home
}

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager

    var body: some View {
        Group {
            if authManager.isLoading {
                // Firebase is checking the persisted session — show splash while waiting
                SplashView(onFinished: {})
            } else {
                switch appState.screen {
                case .splash:
                    SplashView {
                        withAnimation {
                            // If already logged in, skip role/login and go straight to main
                            appState.screen = authManager.isSignedIn ? .main : .roleSelect
                        }
                    }

                case .roleSelect:
                    RoleSelectView(
                        onCustomer: { withAnimation { appState.screen = .login } }
                    )

                case .login:
                    LoginView {
                        withAnimation { appState.screen = .main }
                    }

                case .main:
                    mainTabView
                        .onAppear {
                            // Start listening for profile updates when entering main
                            if let uid = authManager.userUID {
                                profileManager.startListening(uid: uid)
                            }
                        }
                }
            }
        }
        .environmentObject(appState)
        // When auth state changes to signed-out, return to login
        .onChange(of: authManager.isSignedIn) { isSignedIn in
            if !isSignedIn {
                profileManager.stopListening()
                withAnimation { appState.screen = .login }
            }
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

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        let item = UITabBarItemAppearance()
        item.normal.iconColor   = .white
        item.normal.titleTextAttributes  = [.foregroundColor: UIColor.white]
        item.selected.iconColor = .white
        item.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance     = item
        appearance.inlineLayoutAppearance      = item
        appearance.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    AppRootView()
        .environmentObject(AuthManager())
        .environmentObject(UserProfileManager())
}
