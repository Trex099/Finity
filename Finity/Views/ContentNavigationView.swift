import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showSearchView: $showSearchView)
                .tabItem {
                    Image(systemName: TabItem.home.icon)
                    Text(TabItem.home.rawValue)
                }
                .tag(TabItem.home)
            
            FavoritesView(showSearchView: $showSearchView)
                .tabItem {
                    Image(systemName: TabItem.favorites.icon)
                    Text(TabItem.favorites.rawValue)
                }
                .tag(TabItem.favorites)
            
            SettingsView(showSearchView: $showSearchView)
                .tabItem {
                    Image(systemName: TabItem.settings.icon)
                    Text(TabItem.settings.rawValue)
                }
                .tag(TabItem.settings)
        }
        .accentColor(.white) // Active tab color
        .onAppear {
            // Configure tab bar to match iOS standard appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            
            // Set colors for the tab items
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            
            // Apply the appearance to the tab bar
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .sheet(isPresented: $showSearchView) { 
            SearchView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentNavigationView()
            .preferredColorScheme(.dark)
    }
} 