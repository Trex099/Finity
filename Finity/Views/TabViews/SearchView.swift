import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Temporary categories for search
    private let searchCategories = [
        "Movies", "TV Shows", "Actors", "Directors", "Genres"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top metallic title
                TopTitleBar()
                    .padding(.top, geometry.safeAreaInsets.top)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                        .padding(.leading, 12)
                    
                    TextField("Search for movies, TV shows...", text: $searchText)
                        .padding(12)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .onChange(of: searchText) { newValue in
                            isSearching = !newValue.isEmpty
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding(.trailing, 12)
                        }
                    }
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Search content
                if isSearching {
                    // Show search results
                    VStack(alignment: .center) {
                        Spacer()
                        Text("Searching for '\(searchText)'")
                            .foregroundColor(.white)
                            .font(.headline)
                        Text("No results found")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else {
                    // Show search categories
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Search Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(searchCategories, id: \.self) { category in
                                    Button(action: {
                                        // Would handle category selection
                                    }) {
                                        Text(category)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 100)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                        }
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .preferredColorScheme(.dark)
    }
} 