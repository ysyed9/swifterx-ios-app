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

    var body: some View {
        Group {
            switch appState.screen {
            case .splash:
                SplashView {
                    withAnimation {
                        appState.screen = .roleSelect
                    }
                }

            case .roleSelect:
                RoleSelectView(
                    onCustomer: { withAnimation { appState.screen = .login } }
                )

            case .login:
                LoginView(
                    onSignIn:         { withAnimation { appState.screen = .main } },
                    onForgotPassword: { },
                    onGoogleSignIn:   { withAnimation { appState.screen = .main } }
                )

            case .main:
                mainTabView
            }
        }
        .environmentObject(appState)
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
}
