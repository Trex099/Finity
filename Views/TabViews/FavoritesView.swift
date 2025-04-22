import SwiftUI

struct FavoritesView: View {
    // Inject the JellyfinService
    @EnvironmentObject var jellyfinService: JellyfinService
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    @State private var selectedItemForDetail: MediaItem? // State for detail view
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Title Bar (Static, Custom Title, Search Icon)
                TopTitleBar(showSearchView: $showSearchView, title: "My Favorites", showLogo: false, showSearchIcon: true)
                    // Ensure background is black and covers safe area
                    .background(Color.black.edgesIgnoringSafeArea(.top))
                
                // Scrollable content below the title bar
                ScrollView {
                    VStack(spacing: 0) {
                        // Favorites content
                        if jellyfinService.favoriteItems.isEmpty {
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
                                ForEach(jellyfinService.favoriteItems) { movie in
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
            .onAppear {
                // Fetch favorites when the view appears
                jellyfinService.fetchFavorites()
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSearch = false
        
        FavoritesView(showSearchView: $showSearch)
            .preferredColorScheme(.dark)
            .environmentObject(JellyfinService())
    }
} 