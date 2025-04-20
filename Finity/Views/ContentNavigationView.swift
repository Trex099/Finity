import SwiftUI

struct ContentNavigationView: View {
    @EnvironmentObject var jellyfinService: JellyfinService
    
    @State private var selectedTab: TabItem = .home
    @State private var showSearchView = false // State to control search presentation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(showSearchView: $showSearchView)
                    .tag(TabItem.home)
                    .environmentObject(jellyfinService)
                
                FavoritesView(showSearchView: $showSearchView)
                    .tag(TabItem.favorites)
                    .environmentObject(jellyfinService)
                
                SettingsView(showSearchView: $showSearchView)
                    .tag(TabItem.settings)
                    .environmentObject(jellyfinService)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom bottom tab bar that matches iOS standard
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            
                            Text(tab.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(
                ZStack {
                    Color.black.opacity(0.8)
                    BlurView(style: .systemMaterialDark)
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $showSearchView) { 
            SearchView()
                .preferredColorScheme(.dark)
                .environmentObject(jellyfinService)
        }
    }
}

struct ContentNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentNavigationView()
            .preferredColorScheme(.dark)
            .environmentObject(JellyfinService())
    }
} 