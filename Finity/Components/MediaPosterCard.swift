import SwiftUI

struct MediaPosterCard: View {
    let item: MediaItem
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Mock poster image - in a real app, you'd load from a URL
            Image(item.posterPath)
                .resizable()
                .scaledToFill()
                .frame(width: isHovered ? 155 : 150, height: isHovered ? 230 : 225)
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
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(item.year)
                            .font(.caption)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", item.rating))
                                .font(.caption)
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
        .frame(width: isHovered ? 155 : 150, height: isHovered ? 230 : 225)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// Preview provider
struct MediaPosterCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
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
    }
} 