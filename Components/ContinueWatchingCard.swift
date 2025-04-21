import SwiftUI

struct ContinueWatchingCard: View {
    @EnvironmentObject var jellyfinService: JellyfinService // Needed for image URLs
    let item: MediaItem
    
    // Calculate progress (0.0 to 1.0)
    private var progress: Double {
        // Use PlayedPercentage if available (usually 0-100), otherwise calculate from ticks
        if let percentage = item.userData?.playedPercentage {
            return min(max(percentage / 100.0, 0.0), 1.0)
        } else if let position = item.userData?.playbackPositionTicks,
                  let runtime = item.runTimeTicks, runtime > 0 { // Assuming runTimeTicks exists on MediaItem
             // TODO: Add runTimeTicks to MediaItem if needed for this calculation
             return min(max(Double(position) / Double(runtime), 0.0), 1.0)
        } else {
            return 0.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .center) { // Align content to center for the play button
                 // Image
                AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.primaryImageTag, type: .primary, maxHeight: 150)) { // Adjust maxHeight if needed
                    phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .overlay(Color.black.opacity(0.2)) // Subtle darken for contrast
                    case .failure(_):
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.3))
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 180, height: 101)
                .clipped()
                .cornerRadius(4)
                
                // Play Button Overlay
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 3)
                    .accessibility(identifier: "play_button_overlay")
                
                // REMOVED: Thin Progress Bar overlay
                /*
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                    .opacity(progress > 0 && progress < 1 ? 1 : 0)
                */
            }
            
            // Title below image
            Text(item.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.top, 4)
                .frame(width: 180, alignment: .leading) // Match image width
        }
        // Ensure the tap gesture area covers the whole VStack
        .contentShape(Rectangle())
    }
}

// Extend JellyfinService to include image URL construction
// Place this extension somewhere accessible, maybe in JellyfinService.swift or a new file

// Placeholder for possible image types
enum JellyfinImageType: String {
    case primary = "Primary"
    case backdrop = "Backdrop"
    case thumb = "Thumb"
    // Add others as needed: Logo, Banner, etc.
}

extension JellyfinService {
    func imageUrl(for itemId: String, tag: String?, type: JellyfinImageType, maxWidth: Int? = nil, maxHeight: Int? = nil, quality: Int = 90) -> URL? {
        guard let serverURL = serverURL, let tag = tag else { return nil }
        
        var urlString = "\(serverURL)/Items/\(itemId)/Images/\(type.rawValue)?tag=\(tag)&quality=\(quality)"
        
        if let maxWidth = maxWidth {
            urlString += "&maxWidth=\(maxWidth)"
        }
        if let maxHeight = maxHeight {
            urlString += "&maxHeight=\(maxHeight)"
        }
        
        return URL(string: urlString)
    }
}

// Preview needs EnvironmentObject
/*
struct ContinueWatchingCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockService = JellyfinService() // Need a way to set a serverURL for preview
        let sampleItem = MediaItem(
            id: "123", name: "Movie Title That Is Quite Long", serverId: nil, type: "Movie", 
            overview: nil, productionYear: 2023, communityRating: nil, officialRating: nil, 
            imageTags: ["Primary": "tag123"], backdropImageTags: nil, 
            userData: UserData(playbackPositionTicks: 500000000, playCount: nil, isFavorite: nil, played: false, playedPercentage: 50.0), 
            genres: nil, runTimeTicks: 1000000000 // Example runtime
        )
        
        ContinueWatchingCard(item: sampleItem)
            .environmentObject(mockService)
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
*/ 