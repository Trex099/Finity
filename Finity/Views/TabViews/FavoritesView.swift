import SwiftUI

struct FavoritesView: View {
    // Temporary favorites data
    private let favoriteMovies = [
        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets through the use of dream-sharing technology."),
        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge yet.")
    ]
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static)
                TopTitleBar(showSearchView: $showSearchView)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(Color.black)
                
                // Scrollable content below the title bar
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("My Favorites")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16) // Add padding below title bar
                        
                        // Favorites content
                        if favoriteMovies.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
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
                            }
                            Spacer()
                                .frame(height: geometry.size.height * 0.3) // Push empty message down
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                                ForEach(favoriteMovies) { movie in
                                    VStack(alignment: .leading) {
                                        Image(movie.posterPath)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 225)
                                            .cornerRadius(8)
                                        
                                        Text(movie.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            Text(movie.year)
                                                .font(.caption)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption)
                                                
                                                Text(String(format: "%.1f", movie.rating))
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.bottom, 8)
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
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a constant binding for the preview
        @State var showSearch = false
        
        FavoritesView(showSearchView: $showSearch)
            .preferredColorScheme(.dark)
    }
} 