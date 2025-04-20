import SwiftUI
import Combine

struct MediaDetailView: View {
    // Receive itemId from navigation
    let itemId: String
    
    // Inject the service
    @EnvironmentObject var jellyfinService: JellyfinService
    
    // Local state for fetched details
    @State private var details: MediaItem? = nil
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss
    
    // Mock data for related content (keep for now, replace later if needed)
    private let relatedItems = [
        MediaItem(id: "R1", name: "The Dark Knight Rises", serverId: nil, type: "Movie", overview: "...", productionYear: 2012, communityRating: 8.4, officialRating: nil, imageTags: ["Primary":"darkknightTag"], backdropImageTags: nil, userData: nil, genres: nil, runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "R2", name: "Batman Begins", serverId: nil, type: "Movie", overview: "...", productionYear: 2005, communityRating: 8.2, officialRating: nil, imageTags: ["Primary":"inceptionTag"], backdropImageTags: nil, userData: nil, genres: nil, runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "R3", name: "Tenet", serverId: nil, type: "Movie", overview: "...", productionYear: 2020, communityRating: 7.3, officialRating: nil, imageTags: ["Primary":"darkknightTag"], backdropImageTags: nil, userData: nil, genres: nil, runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil),
        MediaItem(id: "R4", name: "Memento", serverId: nil, type: "Movie", overview: "...", productionYear: 2000, communityRating: 8.4, officialRating: nil, imageTags: ["Primary":"inceptionTag"], backdropImageTags: nil, userData: nil, genres: nil, runTimeTicks: nil, indexNumber: nil, parentIndexNumber: nil, seriesName: nil)
    ]
    
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
                                        Text(item.type) // Use type string directly
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
                            Button(action: { /* TODO: Play Action */ }) { /* ... */ 
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
                                     // Optimistically update local state for immediate feedback
                                     // This might get reverted if the API call fails, but feels snappier.
                                     // Need to make UserData mutable for this or handle state differently.
                                     // For now, we rely on the service potentially updating currentItemDetails.
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
                        
                        // --- Related Content (Mock data for now) --- 
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Related Content")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, min(20, geometry.size.width * 0.05))
                                .padding(.bottom, 12)
                            
                            MediaRowView(row: MediaRow(title: "", items: relatedItems)) // Remove selectedItem argument
                        }
                        .padding(.bottom, 24)
                    }
                }
                .background(Color.black.edgesIgnoringSafeArea(.all))
                // Close button removed, rely on navigation back button
                /*
                .overlay(alignment: .topTrailing) { 
                    // ... close button ... 
                }
                */
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
        // Use onReceive to react to changes in the service's published details
        .onReceive(jellyfinService.$currentItemDetails) { fetchedDetails in
             if fetchedDetails?.id == itemId { // Ensure the details match the requested ID
                 self.details = fetchedDetails
                 self.isLoading = false
             } else if !isLoading { // If details are nil or for a different item, and we aren't already loading
                 // This might happen if navigating away quickly or service state clears
                 // Could potentially trigger a re-fetch or handle as appropriate
                 print("Received details for different/nil item, expected \(itemId)")
                 if self.details != nil { // If we previously had details for this item, clear them
                    self.details = nil
                    self.isLoading = true // Set loading to trigger fetch again in onAppear
                 }
             }
        }
        .onAppear {
            // Fetch details when the view appears, only if details are not already loaded for this item
             if details == nil || details?.id != itemId {
                 print("MediaDetailView appearing for ID: \(itemId). Fetching details...")
                 isLoading = true
                 jellyfinService.fetchItemDetails(itemID: itemId)
             } else {
                  print("MediaDetailView appearing for ID: \(itemId). Details already loaded.")
             }
        }
        // Add alert modifier to show errors from the service
        .alert("Error", isPresented: Binding(
            get: { jellyfinService.errorMessage != nil },
            set: { _ in jellyfinService.errorMessage = nil } // Clear error when dismissed
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(jellyfinService.errorMessage ?? "An unknown error occurred.")
        }
    }
}

// Preview needs adjustment
/*
struct MediaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Need to provide itemId and mock service in environment
        // MediaDetailView(itemId: "previewId")
        //    .environmentObject(MockJellyfinServiceWithDetails())
        //    .preferredColorScheme(.dark)
    }
} 
*/ 