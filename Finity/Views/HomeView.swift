import SwiftUI

struct HomeView: View {
    @StateObject private var jellyfinService = JellyfinService(
        baseURL: "https://your-jellyfin-server.com",
        apiKey: "your-api-key"
    )
    @State private var selectedItemForDetail: MediaItem? // State for detail view presentation
    @State private var showPlayer = false
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    
    // Expanded Temporary movie data for testing
    private let tempMovies = [
        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who enters the dreams of others to steal secrets from their subconscious."),
        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice."),
        MediaItem(id: "3", title: "Interstellar", posterPath: "inception", type: .movie, year: "2014", rating: 8.6, overview: "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival."),
        MediaItem(id: "4", title: "The Matrix", posterPath: "darkknight", type: .movie, year: "1999", rating: 8.7, overview: "A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers."),
        MediaItem(id: "5", title: "Avengers: Endgame", posterPath: "inception", type: .movie, year: "2019", rating: 8.4, overview: "After the devastating events of Avengers: Infinity War (2018), the universe is in ruins. With the help of remaining allies, the Avengers assemble once more in order to reverse Thanos' actions and restore balance to the universe."),
        MediaItem(id: "6", title: "Pulp Fiction", posterPath: "darkknight", type: .movie, year: "1994", rating: 8.9, overview: "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption."),
        MediaItem(id: "7", title: "Forrest Gump", posterPath: "inception", type: .movie, year: "1994", rating: 8.8, overview: "The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal and other historical events unfold from the perspective of an Alabama man with an IQ of 75, whose only desire is to be reunited with his childhood sweetheart."),
        MediaItem(id: "8", title: "Gladiator", posterPath: "darkknight", type: .movie, year: "2000", rating: 8.5, overview: "A former Roman General sets out to exact vengeance against the corrupt emperor who murdered his family and sent him into slavery.")
    ]
    
    private let categories = [
        "Recently Added",
        "Action Movies",
        "Popular Titles",
        "Trending Now",
        "Sci-Fi Classics",
        "Award Winners",
        "Critically Acclaimed"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static, with Logo and Search)
                TopTitleBar(showSearchView: $showSearchView, showLogo: true, showSearchIcon: true)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(BlurView(style: .systemUltraThinMaterialDark).edgesIgnoringSafeArea(.top))
                
                // Scrollable content below the title bar
                ScrollView {
                    VStack(spacing: 0) {
                        // Featured content
                        if !tempMovies.isEmpty {
                            FeaturedContentView(item: tempMovies[0])
                                .onTapGesture {
                                    selectedItemForDetail = tempMovies[0]
                                }
                                .accessibility(identifier: "featured_content")
                                .padding(.top, 8)
                        }
                        
                        // Content rows
                        ForEach(categories.indices, id: \.self) { index in
                            // Create a subset of movies for each category
                            let startIndex = index % tempMovies.count
                            let rowItems = Array(0..<5).map { i in
                                tempMovies[(startIndex + i) % tempMovies.count]
                            }
                            let row = MediaRow(title: categories[index], items: rowItems)
                            MediaRowView(row: row, selectedItem: $selectedItemForDetail)
                                .accessibility(identifier: "media_row_\(index)")
                        }
                        
                        // Add extra space for bottom tab bar
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.black)
            .sheet(item: $selectedItemForDetail) { item in // Present Detail View
                 MediaDetailView(item: item)
                    .preferredColorScheme(.dark)
            }
            .fullScreenCover(isPresented: $showPlayer, content: {
                // Keep player presentation if needed, otherwise remove
                if let item = selectedItemForDetail { // Use same item for player if needed
                     MediaPlayerView(item: item)
                }
            })
        }
    }
}

// Modify MediaRowView to accept the binding
struct MediaRowView: View {
    let row: MediaRow
    @Binding var selectedItem: MediaItem? // Accept binding

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                Text(row.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .accessibility(identifier: "row_title_\(row.title)")

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: geometry.size.width * 0.04) {
                        ForEach(row.items) { item in
                            MediaPosterCard(item: item)
                                .frame(width: min(geometry.size.width * 0.3, 150))
                                .accessibility(identifier: "media_card_\(item.id)")
                                .onTapGesture { // Trigger detail view
                                    selectedItem = item
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(height: 270)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSearch = false
        
        Group {
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 13 Pro")
            
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 