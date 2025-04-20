import SwiftUI

struct HomeView: View {
    // Access the shared JellyfinService from the environment
    @EnvironmentObject var jellyfinService: JellyfinService 
    
    // State to hold fetched media items
    @State private var featuredItems: [MediaItem] = [] // For the banner
    @State private var recentlyAddedItems: [MediaItem] = [] // Example category
    // TODO: Add state for other categories like Continue Watching
    
    @State private var selectedItemForNavigation: MediaItem? = nil // For NavigationLink value
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
            // NavigationStack allows push navigation
            NavigationStack {
                VStack(spacing: 0) {
                    // Top Title Bar (Static, with Logo and Search)
                    TopTitleBar(showSearchView: $showSearchView, showLogo: true, showSearchIcon: true)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .background(Color.black.edgesIgnoringSafeArea(.top))
                    
                    // Scrollable content below the title bar
                    ScrollView {
                        VStack(spacing: 0) {
                            // Featured content - Use fetched data
                            FeaturedBannerCarouselView(
                                items: featuredItems,
                                onItemSelected: { item in
                                    // Set the item to trigger navigation via .navigationDestination
                                    print("Navigation triggered for: \(item.title)")
                                    selectedItemForNavigation = item 
                                },
                                onPlaySelected: { item in
                                    // Action for Play button
                                    print("Play selected for: \(item.title)")
                                    selectedItemForNavigation = item // Also set for player context if needed
                                    showPlayer = true
                                }
                            )
                            .padding(.bottom, 20) // Add some space below the banner
                            
                            // TODO: Replace with dynamic rows fetched from Jellyfin
                            // Example: Recently Added Row
                            if !recentlyAddedItems.isEmpty {
                               let row = MediaRow(title: "Recently Added", items: recentlyAddedItems)
                               // TODO: Modify MediaRowView to use NavigationLink or pass selection up
                               MediaRowView(row: row, selectedItem: $selectedItemForNavigation)
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
                // Navigation title managed by TopTitleBar, so keep this hidden
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                 // Fetch data when the view appears
                .onAppear(perform: loadData)
                // Define the destination for the NavigationLink based on the selected item
                .navigationDestination(for: MediaItem.self) { item in
                    MediaDetailView(item: item)
                        .preferredColorScheme(.dark)
                        // Hide the default back button title if desired
                        .navigationBarTitle("", displayMode: .inline) 
                }
            }
            .fullScreenCover(isPresented: $showPlayer, content: {
                 // Pass the selected item to the player view
                if let itemToPlay = selectedItemForNavigation { 
                     MediaPlayerView(item: itemToPlay)
                } else {
                    // Optional: Placeholder or error view if item is nil
                    Text("Error loading player").foregroundColor(.white)
                }
            })
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
                MediaItem(id: "jf1", title: "Jellyfin Feature 1", posterPath: "inception", type: .movie, year: "2024", rating: 8.0, overview: "Fetched from Jellyfin (simulated). A slightly longer description to test wrapping."),
                MediaItem(id: "jf2", title: "Jellyfin Feature 2", posterPath: "darkknight", type: .movie, year: "2023", rating: 7.5, overview: "Another item from the server."),
                MediaItem(id: "jf3", title: "Jellyfin Feature 3", posterPath: "inception", type: .tvShow, year: "2022", rating: 8.2, overview: "A featured TV Show.")
                // Need 6 items total eventually
            ]
            self.recentlyAddedItems = [
                 MediaItem(id: "jf4", title: "Recent Movie", posterPath: "inception", type: .movie, year: "2024", rating: 8.8, overview: "Recently added movie."),
                 MediaItem(id: "jf5", title: "Recent Show", posterPath: "darkknight", type: .tvShow, year: "2024", rating: 9.0, overview: "Recently added TV show.")
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