import SwiftUI

struct FeaturedContentView: View {
    @EnvironmentObject var jellyfinService: JellyfinService
    let item: MediaItem
    @State private var showDetails = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background image
                AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.primaryImageTag, type: .primary, maxHeight: 600)) { phase in
                     if let image = phase.image {
                         image.resizable()
                     } else {
                         Rectangle().fill(Color.gray.opacity(0.3)) // Placeholder
                     }
                 }
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: min(500, geometry.size.height * 0.6))
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .black.opacity(0.1),
                                .black.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Content information
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name)
                        .font(.system(size: min(40, geometry.size.width * 0.09), weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .lineLimit(2)
                        .accessibility(identifier: "featured_title")
                    
                    HStack(spacing: 16) {
                        if let year = item.productionYear {
                            Text(String(year))
                        }
                        
                        if let rating = item.communityRating, rating > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                        }
                        
                        Text(item.type)
                    }
                    .font(.system(size: min(16, geometry.size.width * 0.04)))
                    .foregroundColor(.white.opacity(0.8))
                    
                    if showDetails {
                        Text(item.overview ?? "")
                            .font(.system(size: min(16, geometry.size.width * 0.04)))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .padding(.top, 8)
                            .transition(.opacity)
                            .accessibility(identifier: "featured_overview")
                    }
                    
                    HStack(spacing: geometry.size.width * 0.03) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .padding(.horizontal, min(24, geometry.size.width * 0.06))
                            .padding(.vertical, 12)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                            .font(.headline)
                        }
                        .accessibility(identifier: "play_button")
                        
                        Button(action: {
                            withAnimation {
                                showDetails.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showDetails ? "info.circle.fill" : "info.circle")
                                Text(showDetails ? "Less Info" : "More Info")
                            }
                            .padding(.horizontal, min(24, geometry.size.width * 0.06))
                            .padding(.vertical, 12)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .font(.headline)
                        }
                        .accessibility(identifier: "info_button")
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, min(32, geometry.size.width * 0.06))
                .padding(.bottom, min(48, geometry.size.height * 0.06))
            }
            .frame(width: geometry.size.width, height: min(500, geometry.size.height * 0.6))
        }
        .frame(height: 500)
    }
}

struct FeaturedContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a valid MediaItem for the preview
        let previewItem = MediaItem(
            id: "1",
            name: "Inception", // Use 'name'
            serverId: nil,
            type: "Movie", // Use String
            overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
            productionYear: 2010, // Use 'productionYear' (Int?)
            communityRating: 8.8, // Use 'communityRating' (Double?)
            officialRating: "PG-13", // Optional
            imageTags: ["Primary": "inceptionPreviewTag"], // Use 'imageTags'
            backdropImageTags: ["inceptionBackdropPreviewTag"], // Optional
            userData: nil, // Optional
            genres: ["Action", "Sci-Fi"], // Optional
            runTimeTicks: 72000000000, // Optional
            indexNumber: nil,
            parentIndexNumber: nil,
            seriesName: nil
        )

        Group {
            FeaturedContentView(item: previewItem) // Use the created item
            .previewDevice("iPhone 13 Pro")
            .environmentObject(JellyfinService()) // Add environment object for image loading

            FeaturedContentView(item: previewItem) // Use the created item
            .previewDevice("iPhone SE (3rd generation)")
            .environmentObject(JellyfinService()) // Add environment object for image loading
        }
        .preferredColorScheme(.dark) // Apply dark scheme to the group
    }
} 