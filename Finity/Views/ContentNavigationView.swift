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
                BlurView(style: .systemMaterialDark)
                    .frame(height: totalBarVisualHeight + geometry.safeAreaInsets.bottom)
                    .offset(y: geometry.safeAreaInsets.bottom) // Offset slightly if needed, usually not
                    // Alternatively, just let edgesIgnoringSafeArea handle it:
                   // .frame(height: totalBarVisualHeight)
                   // .edgesIgnoringSafeArea(.bottom)

                // Layer 2: Interactive Content (Padded UP from the true bottom)
                BottomTabBar(selectedTab: $selectedTab, contentAreaHeight: barContentHeight)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .edgesIgnoringSafeArea(.bottom) // Let ZStack manage edge-to-edge
            .sheet(isPresented: $showSearchView) { 
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