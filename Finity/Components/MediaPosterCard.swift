import SwiftUI

struct MediaPosterCard: View {
    let item: MediaItem
    @State private var isHovered = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 150)
            let height = width * 1.5 // Maintain aspect ratio
            
            ZStack(alignment: .bottom) {
                // Mock poster image - in a real app, you'd load from a URL
                Image(item.posterPath)
                    .resizable()
                    .scaledToFill()
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
                        Text(item.title)
                            .font(.system(size: min(16, width * 0.11)))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(item.year)
                                .font(.system(size: min(12, width * 0.08)))
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: min(12, width * 0.08)))
                                
                                Text(String(format: "%.1f", item.rating))
                                    .font(.system(size: min(12, width * 0.08)))
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
    static var previews: some View {
        Group {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                MediaPosterCard(item: MediaItem(
                    id: "1",
                    title: "Inception",
                    posterPath: "inception",
                    type: .movie,
                    year: "2010",
                    rating: 8.8,
                    overview: "A thief who steals corporate secrets through dream-sharing technology."
                ))
            }
            .previewDevice("iPhone 13 Pro")
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                MediaPosterCard(item: MediaItem(
                    id: "1",
                    title: "Inception",
                    posterPath: "inception",
                    type: .movie,
                    year: "2010",
                    rating: 8.8,
                    overview: "A thief who steals corporate secrets through dream-sharing technology."
                ))
            }
            .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 