import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main content area
                VStack(spacing: 0) {
                    // Pass binding to TopTitleBar in each view
                    currentTabView(showSearchView: $showSearchView)
                }
                
                // Bottom tab bar
                BottomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .edgesIgnoringSafeArea(.bottom)
            .sheet(isPresented: $showSearchView) { // Present SearchView as a sheet
                SearchView()
                    .preferredColorScheme(.dark)
            }
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