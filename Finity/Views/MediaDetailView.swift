import SwiftUI

struct MediaDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) var dismiss
    
    // Mock data for related content
    private let relatedItems = [
        MediaItem(id: "R1", title: "The Dark Knight Rises", posterPath: "darkknight", type: .movie, year: "2012", rating: 8.4, overview: "Eight years after the Joker's reign of anarchy, Batman must return."),
        MediaItem(id: "R2", title: "Batman Begins", posterPath: "inception", type: .movie, year: "2005", rating: 8.2, overview: "After training with his mentor, Bruce Wayne begins his war on crime."),
        MediaItem(id: "R3", title: "Tenet", posterPath: "darkknight", type: .movie, year: "2020", rating: 7.3, overview: "Armed with only one word, Tenet, and fighting for the survival of the entire world."),
        MediaItem(id: "R4", title: "Memento", posterPath: "inception", type: .movie, year: "2000", rating: 8.4, overview: "A man with short-term memory loss attempts to track down his wife's murderer.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView { // Make the whole detail view scrollable
                VStack(alignment: .leading, spacing: 0) {
                    // --- Top Section (Backdrop + Poster + Basic Info) ---
                    ZStack(alignment: .bottomLeading) {
                        // Backdrop Image (Blurred)
                        Image(item.posterPath) // Use poster as placeholder backdrop
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                            .clipped()
                            .blur(radius: 10)
                            .overlay(Color.black.opacity(0.4))
                        
                        // Foreground Content (Poster + Title/Info)
                        HStack(alignment: .bottom, spacing: 16) {
                            // Poster Image
                            Image(item.posterPath)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35 * 1.5)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                            
                            // Title and Meta Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: min(32, geometry.size.width * 0.08), weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .shadow(radius: 2)
                                
                                HStack(spacing: 12) {
                                    Text(item.year)
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", item.rating))
                                    }
                                    Text(item.type == .movie ? "Movie" : "TV Show")
                                }
                                .font(.system(size: min(15, geometry.size.width * 0.04)))
                                .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer() // Push content left
                        }
                        .padding(.horizontal, min(20, geometry.size.width * 0.05))
                        .padding(.bottom, 20)
                    }
                    
                    // --- Action Buttons --- (Netflix Style)
                    HStack(spacing: 16) {
                        Button(action: { /* Play Action */ }) {
                            Label("Play", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(4)
                        }
                        
                        Button(action: { /* Add to favorites/watchlist */ }) {
                            Label("Add to List", systemImage: "plus")
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
                    
                    // --- Overview / Description --- (Netflix/Apple TV Mix)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                        
                        Text(item.overview)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(nil) // Show full overview
                    }
                    .padding(.horizontal, min(20, geometry.size.width * 0.05))
                    .padding(.bottom, 24)
                    
                    // --- Related Content --- (Netflix Style Row)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Related Content")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, min(20, geometry.size.width * 0.05))
                            .padding(.bottom, 12)
                        
                        // Use the existing MediaRowView for consistency
                        // Need to provide a dummy binding for selection here
                        MediaRowView(row: MediaRow(title: "", items: relatedItems), selectedItem: .constant(nil))
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .overlay(alignment: .topTrailing) { // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding()
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 10)
                }
            }
        }
    }
}

struct MediaDetailView_Previews: PreviewProvider {
    static let sampleItem = MediaItem(
        id: "1",
        title: "Inception",
        posterPath: "inception",
        type: .movie,
        year: "2010",
        rating: 8.8,
        overview: "A thief who enters the dreams of others to steal secrets from their subconscious. His skill has made him a coveted player in industrial espionage, but has also cost him everything he loves. Cobb gets a chance redemption when he is offered a task to plant an idea into the mind of a C.E.O."
    )
    
    static var previews: some View {
        MediaDetailView(item: sampleItem)
            .preferredColorScheme(.dark)
    }
} 