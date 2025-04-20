import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content based on selected tab
            VStack(spacing: 0) {
                currentTabView(showSearchView: $showSearchView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Tab bar at the bottom
            BottomTabBar(selectedTab: $selectedTab)
                .edgesIgnoringSafeArea(.bottom)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showSearchView) { 
            SearchView()
                .preferredColorScheme(.dark)
        }
    }
    
    // Function to create the correct view based on the selected tab
    @ViewBuilder
    private func currentTabView(showSearchView: Binding<Bool>) -> some View {
        switch selectedTab {
        case .home:
            HomeView(showSearchView: showSearchView)
        case .favorites:
            FavoritesView(showSearchView: showSearchView)
        case .settings:
            SettingsView(showSearchView: showSearchView)
        }
    }
}

struct ContentNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentNavigationView()
            .preferredColorScheme(.dark)
    }
} 