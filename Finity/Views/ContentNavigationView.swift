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
            // Set TabBar appearance to match iOS standard dark mode
            UITabBar.appearance().barTintColor = .black
            UITabBar.appearance().isTranslucent = true
            UITabBar.appearance().backgroundColor = UIColor.black.withAlphaComponent(0.8)
            
            // Set TabBar item colors
            UITabBar.appearance().unselectedItemTintColor = UIColor.gray
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