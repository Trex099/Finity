import SwiftUI

struct ContentNavigationView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    let barContentHeight: CGFloat = 50 // Height of the interactive part
    let totalBarVisualHeight: CGFloat = 75 // Desired total visual height of the blurred background
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) { 
                // Main content area
                VStack(spacing: 0) {
                    currentTabView(showSearchView: $showSearchView)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Layer 1: Taller Background Blur
                let safeAreaBottom = geometry.safeAreaInsets.bottom
                let totalBarHeight = barContentHeight + safeAreaBottom + extraTopPadding // Assuming extraTopPadding is defined or replace calculation
                BlurView(style: .systemMaterialDark)
                    .frame(height: totalBarVisualHeight + safeAreaBottom) // Use constant + safe area
                   // .offset(y: safeAreaBottom) // Offset might not be needed depending on frame/alignment
                    .edgesIgnoringSafeArea(.bottom)

                // Layer 2: Interactive Content (Padded UP from the true bottom)
                BottomTabBar(selectedTab: $selectedTab) // Removed extra argument
                    .padding(.bottom, safeAreaBottom)
                
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .edgesIgnoringSafeArea(.bottom) // Let ZStack manage edge-to-edge
            .sheet(isPresented: $showSearchView) { 
                SearchView()
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    // Define extraTopPadding if calculation is kept, or remove if not used
     let extraTopPadding: CGFloat = 10
    
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