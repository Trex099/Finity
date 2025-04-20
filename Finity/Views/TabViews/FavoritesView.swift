import SwiftUI

struct FavoritesView: View {
    // Expanded Temporary favorites data
    private let favoriteMovies = [
        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets through the use of dream-sharing technology."),
        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge yet."),
        MediaItem(id: "4", title: "The Matrix", posterPath: "darkknight", type: .movie, year: "1999", rating: 8.7, overview: "A computer hacker learns about the true nature of reality."),
        MediaItem(id: "7", title: "Forrest Gump", posterPath: "inception", type: .movie, year: "1994", rating: 8.8, overview: "Perspectives of an Alabama man with an IQ of 75."),
        MediaItem(id: "8", title: "Gladiator", posterPath: "darkknight", type: .movie, year: "2000", rating: 8.5, overview: "A former Roman General sets out to exact vengeance.")
    ]
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    @State private var selectedItemForDetail: MediaItem? // State for detail view
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static, Custom Title, Search Icon)
                TopTitleBar(showSearchView: $showSearchView, title: "My Favorites", showLogo: false, showSearchIcon: true)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(BlurView(style: .systemUltraThinMaterialDark).edgesIgnoringSafeArea(.top))
                
                // Scrollable content below the title bar
                ScrollView {
                    VStack(spacing: 0) {
                        // Favorites content
                        if favoriteMovies.isEmpty {
                            // Empty State
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No favorites yet")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Movies and shows you mark as favorites will appear here")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                Spacer()
                            }
                            .frame(height: geometry.size.height - geometry.safeAreaInsets.top - 60 - 60) // Fill available space
                        } else {
                            // Grid definition - adaptive column based on width
                            let columns = [GridItem(.adaptive(minimum: geometry.size.width / 3 - 24), spacing: 16)]
                            
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(favoriteMovies) { movie in
                                    // Reusable Poster Card component for consistency
                                    MediaPosterCard(item: movie)
                                        .onTapGesture {
                                            selectedItemForDetail = movie
                                        }
                                        .accessibility(identifier: "favorite_card_\(movie.id)")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        
                        // Add extra space for bottom tab bar
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .sheet(item: $selectedItemForDetail) { item in // Present Detail View
                 MediaDetailView(item: item)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSearch = false
        
        FavoritesView(showSearchView: $showSearch)
            .preferredColorScheme(.dark)
    }
} 