import SwiftUI

struct MainTabView: View {
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        TabView {
            NavigationStack {
                RoadmapView()
            }
            .tabItem { Label(lang.t("home"), systemImage: "house.fill") }

            NavigationStack {
                ShopView()
            }
            .tabItem { Label(lang.t("shop"), systemImage: "cart.fill") }

            NavigationStack {
                BudgetView()
            }
            .tabItem { Label(lang.t("budget"), systemImage: "wallet.bifold.fill") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label(lang.t("profile"), systemImage: "person.fill") }
        }
        .tint(brandGreen)
    }
}
