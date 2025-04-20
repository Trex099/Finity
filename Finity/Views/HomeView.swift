import SwiftUI

struct HomeView: View {
    @StateObject private var jellyfinService = JellyfinService(
        baseURL: "https://your-jellyfin-server.com",
        apiKey: "your-api-key"
    )
    @State private var selectedTab: NavigationTab = .home
    @State private var selectedItem: MediaItem?
    @State private var showPlayer = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Featured content
                        if !jellyfinService.featuredContent.isEmpty {
                            FeaturedContentView(item: jellyfinService.featuredContent[0])
                                .onTapGesture {
                                    selectedItem = jellyfinService.featuredContent[0]
                                    showPlayer = true
                                }
                                .accessibility(identifier: "featured_content")
                        }
                        
                        // Content rows
                        ForEach(jellyfinService.categories) { row in
                            MediaRowView(row: row)
                                .accessibility(identifier: "media_row_\(row.id)")
                        }
                        
                        // Add extra space at bottom to ensure content isn't covered by tab bars, etc.
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 20)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
                
                // Top navigation bar
                VStack {
                    TopNavigationBar(selectedTab: $selectedTab)
                        .padding(.top, geometry.safeAreaInsets.top)
                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)
            }
            .fullScreenCover(isPresented: $showPlayer, content: {
                if let item = selectedItem {
                    MediaPlayerView(item: item)
                }
            })
            .onAppear {
                // Load data
                jellyfinService.fetchFeaturedContent()
                jellyfinService.fetchCategories()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 13 Pro")
            
            HomeView()
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 