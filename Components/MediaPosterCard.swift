import SwiftUI

struct MediaPosterCard: View {
    // Inject service for image URLs
    @EnvironmentObject var jellyfinService: JellyfinService
    let item: MediaItem
    @State private var isHovered = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 150)
            let height = width * 1.5 // Maintain aspect ratio
            
            ZStack(alignment: .bottom) {
                // Load image using AsyncImage and service
                AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.primaryImageTag, type: .primary, maxHeight: 300)) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .scaledToFill()
                    } else if phase.error != nil {
                        Image(systemName: "photo") // Placeholder on failure
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.3))
                    } else {
                        ProgressView() // Placeholder while loading
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                .frame(width: isHovered ? width * 1.05 : width, height: isHovered ? height * 1.05 : height)
                .cornerRadius(8)
                .shadow(radius: isHovered ? 8 : 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                
                // Info overlay (visible on hover)
                if isHovered {
                    VStack(alignment: .leading, spacing: 4) {
                        // Use item.name
                        Text(item.name)
                            .font(.system(size: min(16, width * 0.11)))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            // Use item.productionYear
                            if let year = item.productionYear {
                                Text(String(year))
                                    .font(.system(size: min(12, width * 0.08)))
                            }
                            
                            Spacer()
                            
                            // Use item.communityRating
                            if let rating = item.communityRating, rating > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: min(12, width * 0.08)))
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: min(12, width * 0.08)))
                                }
                            }
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                }
            }
            .frame(width: isHovered ? width * 1.05 : width, height: isHovered ? height * 1.05 : height)
            .contentShape(Rectangle()) // Improve tap area
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .frame(width: 150, height: 225)
        .padding(4) // Add padding to ensure minimum tap target size
    }
}

// Preview provider
struct MediaPosterCard_Previews: PreviewProvider {
    // Update preview item to use the new MediaItem structure
    static let previewItem = MediaItem(
        id: "1", name: "Inception", serverId: nil, type: "Movie", 
        overview: "A thief who steals corporate secrets through dream-sharing technology.", 
        productionYear: 2010, communityRating: 8.8, officialRating: "PG-13", 
        imageTags: ["Primary": "previewTag"], backdropImageTags: [], 
        userData: nil, genres: ["Action", "Sci-Fi"], runTimeTicks: nil,
        indexNumber: nil, parentIndexNumber: nil, seriesName: nil
    )
    
    static var previews: some View {
        Group {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MediaPosterCard(item: previewItem)
            }
            .previewDevice("iPhone 13 Pro")
            // Provide mock service for image URLs in preview
            .environmentObject(JellyfinService())
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MediaPosterCard(item: previewItem)
            }
            .previewDevice("iPhone SE (3rd generation)")
             // Provide mock service for image URLs in preview
            .environmentObject(JellyfinService())
        }
        .preferredColorScheme(.dark)
    }
} 