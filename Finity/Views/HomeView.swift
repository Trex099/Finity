import SwiftUI

struct HomeView: View {
    @StateObject private var jellyfinService = JellyfinService(
        baseURL: "https://your-jellyfin-server.com",
        apiKey: "your-api-key"
    )
    @State private var selectedItem: MediaItem?
    @State private var showPlayer = false
    
    // Temporary movie data for testing
    private let tempMovies = [
        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets through the use of dream-sharing technology."),
        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge yet."),
        MediaItem(id: "3", title: "Interstellar", posterPath: "inception", type: .movie, year: "2014", rating: 8.6, overview: "A team of explorers travel through a wormhole in space."),
        MediaItem(id: "4", title: "The Matrix", posterPath: "darkknight", type: .movie, year: "1999", rating: 8.7, overview: "A computer hacker learns about the true nature of reality."),
        MediaItem(id: "5", title: "Avengers: Endgame", posterPath: "inception", type: .movie, year: "2019", rating: 8.4, overview: "The Avengers take a final stand against Thanos."),
        MediaItem(id: "6", title: "Pulp Fiction", posterPath: "darkknight", type: .movie, year: "1994", rating: 8.9, overview: "The lives of two mob hitmen, a boxer, and a pair of diner bandits intertwine.")
    ]
    
    private let categories = [
        "Recently Added",
        "Action Movies",
        "Popular Titles",
        "Trending Now",
        "Sci-Fi Classics"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top metallic title
                TopTitleBar()
                    .padding(.top, geometry.safeAreaInsets.top)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Featured content
                        if !tempMovies.isEmpty {
                            FeaturedContentView(item: tempMovies[0])
                                .onTapGesture {
                                    selectedItem = tempMovies[0]
                                    showPlayer = true
                                }
                                .accessibility(identifier: "featured_content")
                        }
                        
                        // Content rows
                        ForEach(0..<categories.count, id: \.self) { index in
                            // Create a subset of movies for each category (cycling through the temp movies)
                            let rowMovies = Array(0..<4).map { i in
                                tempMovies[(index + i) % tempMovies.count]
                            }
                            let row = MediaRow(title: categories[index], items: rowMovies)
                            MediaRowView(row: row)
                                .accessibility(identifier: "media_row_\(index)")
                        }
                        
                        // Add extra space for bottom tab bar
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                    }
                }
            }
            .background(Color.black)
            .fullScreenCover(isPresented: $showPlayer, content: {
                if let item = selectedItem {
                    MediaPlayerView(item: item)
                }
            })
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
} 