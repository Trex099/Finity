import SwiftUI

struct FeaturedContentView: View {
    let item: MediaItem
    @State private var showDetails = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Image(item.posterPath)
                .resizable()
                .scaledToFill()
                .frame(height: 500)
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
                Text(item.title)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                HStack(spacing: 16) {
                    Text(item.year)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", item.rating))
                    }
                    
                    Text(item.type == .movie ? "Movie" : "TV Show")
                }
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 16))
                
                if showDetails {
                    Text(item.overview)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .font(.headline)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showDetails ? "info.circle.fill" : "info.circle")
                            Text(showDetails ? "Less Info" : "More Info")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .font(.headline)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct FeaturedContentView_Previews: PreviewProvider {
    static var previews: some View {
        FeaturedContentView(item: MediaItem(
            id: "1",
            title: "Inception",
            posterPath: "inception",
            type: .movie,
            year: "2010",
            rating: 8.8,
            overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O."
        ))
    }
} 