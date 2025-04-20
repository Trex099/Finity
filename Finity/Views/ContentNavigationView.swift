import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        // Main content container
        VStack(spacing: 0) {
            currentTabView(showSearchView: $showSearchView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .safeAreaInset(edge: .bottom, spacing: 0) { // Use safeAreaInset for the bar
            BottomTabBar(selectedTab: $selectedTab)
                .padding(.vertical, 10) // Add 10pt padding above and below icons/text
        }
        .edgesIgnoringSafeArea(.bottom) // Allow main content AND inset background to go edge-to-edge
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