import SwiftUI

struct HomeView: View {
    // Access the shared JellyfinService from the environment
    @EnvironmentObject var jellyfinService: JellyfinService 
    
    // State to hold fetched media items
    @State private var featuredItems: [MediaItem] = [] // For the banner
    @State private var recentlyAddedItems: [MediaItem] = [] // Example category
    // TODO: Add state for other categories like Continue Watching
    
    @State private var selectedItemForDetail: MediaItem? // State for detail view presentation
    @State private var showPlayer = false
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    
    // REMOVE the hardcoded tempMovies
    /*
    private var tempMovies: [MediaItem] {
        // ... removed hardcoded data ...
    }
    */
   
    // REMOVE the hardcoded categories
    /*
    private var categories: [String] {
        // ... removed hardcoded data ...
    }
    */
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static, with Logo and Search)
                TopTitleBar(showSearchView: $showSearchView, showLogo: true, showSearchIcon: true)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(Color.black.edgesIgnoringSafeArea(.top))
                
                // Scrollable content below the title bar
                ScrollView {
                    VStack(spacing: 0) {
                        // Featured content - Use fetched data
                        // TODO: Replace with FeaturedBannerCarouselView
                        if let firstFeatured = featuredItems.first { // Use fetched items
                            FeaturedContentView(item: firstFeatured)
                                .onTapGesture {
                                    selectedItemForDetail = firstFeatured
                                }
                                .accessibility(identifier: "featured_content")
                                .padding(.top, 8)
                        } else {
                            // Placeholder while loading or if empty
                            Rectangle() // Or ProgressView()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: geometry.size.width * 0.8) // Approx height for banner
                                .padding(.top, 8)
                        }
                        
                        // TODO: Replace with dynamic rows fetched from Jellyfin
                        // Example: Recently Added Row
                        if !recentlyAddedItems.isEmpty {
                           let row = MediaRow(title: "Recently Added", items: recentlyAddedItems)
                           MediaRowView(row: row, selectedItem: $selectedItemForDetail)
                                .accessibility(identifier: "media_row_recently_added")
                        }

                        // TODO: Add Continue Watching Row
                        
                        // Remove hardcoded category loops
                        /*
                        ForEach(categories.indices, id: \.self) { index in
                            // ... removed loop using tempMovies ...
                        }
                        */
                        
                        // Add extra space for bottom tab bar
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.black)
            .sheet(item: $selectedItemForDetail) { item in // Present Detail View (Will change later)
                 MediaDetailView(item: item)
                    .preferredColorScheme(.dark)
            }
            .fullScreenCover(isPresented: $showPlayer, content: {
                if let item = selectedItemForDetail { 
                     MediaPlayerView(item: item) // Will need enhancement
                }
            })
            // Fetch data when the view appears
            .onAppear(perform: loadData)
        }
    }
    
    // Function to load data from JellyfinService
    private func loadData() {
        print("HomeView appearing. Loading data...")
        // TODO: Implement actual fetching in JellyfinService and update state here
        // jellyfinService.fetchLatestMedia()
        // jellyfinService.fetchRecentlyAdded()
        // jellyfinService.fetchContinueWatching()
        
        // For now, simulate fetching placeholder data after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             // Use the existing MediaItem structure for now
             // We need to define a proper Codable struct mapping to Jellyfin API later
            self.featuredItems = [
                MediaItem(id: "jf1", title: "Jellyfin Feature 1", posterPath: "inception", type: .movie, year: "2024", rating: 8.0, overview: "Fetched from Jellyfin (simulated)."),
                MediaItem(id: "jf2", title: "Jellyfin Feature 2", posterPath: "darkknight", type: .movie, year: "2023", rating: 7.5, overview: "Another item from the server.")
                // Add more up to 6 for the banner later
            ]
            self.recentlyAddedItems = [
                 MediaItem(id: "jf3", title: "Recent Movie", posterPath: "inception", type: .movie, year: "2024", rating: 8.8, overview: "Recently added movie."),
                 MediaItem(id: "jf4", title: "Recent Show", posterPath: "darkknight", type: .tvShow, year: "2024", rating: 9.0, overview: "Recently added TV show.")
            ]
            print("Simulated data loaded.")
        }
    }
}

// Preview needs adjustment - requires EnvironmentObject
/*
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSearch = false
        
        // Preview will fail without EnvironmentObject
        // Need to provide a mock JellyfinService
        Group {
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 13 Pro")
                // .environmentObject(MockJellyfinService()) // Example
            
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
                 // .environmentObject(MockJellyfinService()) // Example
        }
    }
} 
*/ 