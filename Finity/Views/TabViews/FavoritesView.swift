import SwiftUI

struct FavoritesView: View {
    // Inject the JellyfinService
    @EnvironmentObject var jellyfinService: JellyfinService
    
    // Updated Temporary favorites data using the new MediaItem structure
    // TODO: Replace this with actual favorite fetching from JellyfinService
    private let favoriteMovies: [MediaItem] = [
        MediaItem(id: "1", name: "Inception", serverId: nil, type: "Movie", overview: "A thief who steals corporate secrets through the use of dream-sharing technology.", productionYear: 2010, communityRating: 8.8, officialRating: "PG-13", imageTags: ["Primary":"inceptionTag"], backdropImageTags: [], userData: UserData(playbackPositionTicks: 0, playCount: 1, isFavorite: true, played: true, playedPercentage: 100), genres: ["Action", "Sci-Fi"], runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "2", name: "The Dark Knight", serverId: nil, type: "Movie", overview: "Batman faces his greatest challenge yet.", productionYear: 2008, communityRating: 9.0, officialRating: "PG-13", imageTags: ["Primary":"darkknightTag"], backdropImageTags: [], userData: UserData(playbackPositionTicks: 0, playCount: 1, isFavorite: true, played: true, playedPercentage: 100), genres: ["Action", "Drama"], runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "4", name: "The Matrix", serverId: nil, type: "Movie", overview: "A computer hacker learns about the true nature of reality.", productionYear: 1999, communityRating: 8.7, officialRating: "R", imageTags: ["Primary":"darkknightTag"], backdropImageTags: [], userData: UserData(playbackPositionTicks: 0, playCount: 0, isFavorite: true, played: false, playedPercentage: 0), genres: ["Action", "Sci-Fi"], runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "7", name: "Forrest Gump", serverId: nil, type: "Movie", overview: "Perspectives of an Alabama man with an IQ of 75.", productionYear: 1994, communityRating: 8.8, officialRating: "PG-13", imageTags: ["Primary":"inceptionTag"], backdropImageTags: [], userData: UserData(playbackPositionTicks: 0, playCount: 0, isFavorite: true, played: false, playedPercentage: 0), genres: ["Comedy", "Drama"], runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "8", name: "Gladiator", serverId: nil, type: "Movie", overview: "A former Roman General sets out to exact vengeance.", productionYear: 2000, communityRating: 8.5, officialRating: "R", imageTags: ["Primary":"darkknightTag"], backdropImageTags: [], userData: UserData(playbackPositionTicks: 0, playCount: 1, isFavorite: true, played: true, playedPercentage: 100), genres: ["Action", "Drama"], runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil)
    ]
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    @State private var selectedItemForDetail: MediaItem? // State for detail view
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static, Custom Title, Search Icon)
                TopTitleBar(showSearchView: $showSearchView, title: "My Favorites", showLogo: false, showSearchIcon: true)
                    .padding(.top, geometry.safeAreaInsets.top)
                    // Ensure background is black and covers safe area
                    .background(Color.black.edgesIgnoringSafeArea(.top))
                
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
            .sheet(item: $selectedItemForDetail) { item in 
                 MediaDetailView(itemId: item.id)
                    .preferredColorScheme(.dark)
                    .environmentObject(jellyfinService)
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