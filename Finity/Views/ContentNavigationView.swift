import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        ZStack(alignment: .bottom) { // Align ZStack content to bottom
            // Main content area fills the space
            VStack(spacing: 0) {
                currentTabView(showSearchView: $showSearchView)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom tab bar positioned at the bottom
            BottomTabBar(selectedTab: $selectedTab)
                // No padding needed here now, bar handles its own safe area
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .edgesIgnoringSafeArea(.bottom) // Let the ZStack manage bottom edge
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
        // case .search: // Removed Search case
        //     SearchView()
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