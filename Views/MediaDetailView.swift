import SwiftUI
import Combine

struct MediaDetailView: View {
    // Receive itemId from navigation
    let itemId: String
    
    // Inject the service
    @EnvironmentObject var jellyfinService: JellyfinService
    
    // Local state for fetched details
    @State private var details: MediaItem? = nil
    @State private var isLoading = true
    @State private var relatedItems: [MediaItem] = []
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            // Show loading indicator while details are being fetched
            if isLoading {
                 ZStack {
                      Color.black.edgesIgnoringSafeArea(.all)
                      ProgressView()
                         .scaleEffect(1.5)
                 }
            } else if let item = details { // Use the fetched details
                ScrollView { 
                    VStack(alignment: .leading, spacing: 0) {
                        // --- Top Section (Backdrop + Poster + Basic Info) ---
                        ZStack(alignment: .bottomLeading) {
                            // Backdrop Image
                            AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.backdropImageTags?.first, type: .backdrop)) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                } else {
                                    Color.gray.opacity(0.2) // Placeholder color
                                }
                            }
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                            .clipped()
                            .blur(radius: 10)
                            .overlay(Color.black.opacity(0.4))
                            
                            // Foreground Content
                            HStack(alignment: .bottom, spacing: 16) {
                                // Poster Image
                                AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.primaryImageTag, type: .primary, maxHeight: 300)) { phase in
                                     if let image = phase.image {
                                         image.resizable()
                                     } else {
                                         Image(systemName: "photo").resizable().scaledToFit().background(Color.gray.opacity(0.3))
                                     }
                                }
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35 * 1.5)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                                
                                // Title and Meta Info (using fetched data)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.name)
                                        .font(.system(size: min(32, geometry.size.width * 0.08), weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .shadow(radius: 2)
                                    
                                    HStack(spacing: 12) {
                                        if let year = item.productionYear {
                                            Text(String(year))
                                        }
                                        if let rating = item.communityRating, rating > 0 {
                                            HStack(spacing: 3) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                Text(String(format: "%.1f", rating))
                                            }
                                        }
                                        Text(item.type ?? "Unknown Type") // Use type string directly
                                        if let officialRating = item.officialRating {
                                             Text(officialRating).padding(2).border(Color.gray) // Display official rating
                                        }
                                    }
                                    .font(.system(size: min(15, geometry.size.width * 0.04)))
                                    .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, min(20, geometry.size.width * 0.05))
                            .padding(.bottom, 20)
                        }
                        
                        // --- Action Buttons --- 
                        HStack(spacing: 16) {
                            Button(action: { 
                                // Play action
                                jellyfinService.playMedia(item: item)
                            }) { 
                                 Label("Play", systemImage: "play.fill")
                                     .font(.headline)
                                     .foregroundColor(.black)
                                     .padding(.vertical, 12)
                                     .frame(maxWidth: .infinity)
                                     .background(Color.white)
                                     .cornerRadius(4)
                            }
                            
                            Button(action: {
                                 // Call the service to toggle favorite status
                                 if let currentStatus = item.userData?.isFavorite {
                                     jellyfinService.toggleFavorite(itemId: item.id, currentStatus: currentStatus)
                                 } else {
                                      // If status is unknown (nil), assume we want to add it
                                      jellyfinService.toggleFavorite(itemId: item.id, currentStatus: false)
                                 }
                             }) {
                                 Label(item.userData?.isFavorite ?? false ? "Favorited" : "Add to List", systemImage: item.userData?.isFavorite ?? false ? "checkmark" : "plus")
                                     .font(.headline)
                                     .foregroundColor(.white)
                                     .padding(.vertical, 12)
                                     .frame(maxWidth: .infinity)
                                     .background(Color.white.opacity(0.15))
                                     .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, min(20, geometry.size.width * 0.05))
                        .padding(.vertical, 16)
                        
                        // --- Overview --- 
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                            
                            Text(item.overview ?? "No overview available.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(nil)
                        }
                        .padding(.horizontal, min(20, geometry.size.width * 0.05))
                        .padding(.bottom, 24)

                        // --- Genres --- (If available)
                        if let genres = item.genres, !genres.isEmpty {
                             VStack(alignment: .leading, spacing: 8) {
                                  Text("Genres")
                                       .font(.title3).bold()
                                       .foregroundColor(.white)
                                  Text(genres.joined(separator: ", "))
                                       .font(.body)
                                       .foregroundColor(.white.opacity(0.8))
                             }
                            .padding(.horizontal, min(20, geometry.size.width * 0.05))
                            .padding(.bottom, 24)
                        }
                        
                        // --- Related Content --- 
                        if !relatedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Related Content")
                                    .font(.title3).bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, min(20, geometry.size.width * 0.05))
                                    .padding(.bottom, 12)
                                
                                MediaRowView(row: MediaRow(title: "", items: relatedItems))
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .background(Color.black.edgesIgnoringSafeArea(.all))
            } else {
                 // Handle case where details couldn't be loaded
                 ZStack {
                      Color.black.edgesIgnoringSafeArea(.all)
                      VStack {
                           Text("Failed to load details.")
                               .foregroundColor(.red)
                           if let errorMsg = jellyfinService.errorMessage {
                                Text(errorMsg)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding()
                           }
                      }
                 }
            }
        }
        .onAppear {
            // Fetch the item details when the view appears
            loadDetails()
        }
    }
    
    private func loadDetails() {
        isLoading = true
        // Call our service to get item details
        jellyfinService.fetchItemDetails(id: itemId) { result in
            switch result {
            case .success(let itemDetails):
                self.details = itemDetails
                // Also fetch similar/related items
                jellyfinService.fetchSimilarItems(for: itemId) { similarResult in
                    DispatchQueue.main.async {
                        switch similarResult {
                        case .success(let similar):
                            self.relatedItems = similar
                        case .failure:
                            // Just leave related items empty if we can't fetch them
                            self.relatedItems = []
                        }
                        self.isLoading = false
                    }
                }
            case .failure(let error):
                print("Failed to fetch details: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
}

// Preview
struct MediaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetailView(itemId: "preview-id")
            .environmentObject(JellyfinService())
            .preferredColorScheme(.dark)
    }
} 