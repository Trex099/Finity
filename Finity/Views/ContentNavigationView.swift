import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Content based on selected tab
                VStack(spacing: 0) {
                    tabView
                }
                
                // Bottom tab bar
                BottomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    @ViewBuilder
    private var tabView: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .search:
            SearchView()
        case .favorites:
            FavoritesView()
        case .settings:
            SettingsView()
        }
    }
}

struct ContentNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentNavigationView()
            .preferredColorScheme(.dark)
    }
} 