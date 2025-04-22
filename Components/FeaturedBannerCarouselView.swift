import SwiftUI
import Combine // Needed for Timer

struct FeaturedBannerCarouselView: View {
    let items: [MediaItem] // Items to display in the carousel
    
    // State for controlling the automatic scroll
    @State private var currentTab = 0
    @State private var timerSubscription: Cancellable? = nil
    private let timerInterval = 5.0 // 5 seconds
    
    // Callback for selecting an item (for navigation)
    var onItemSelected: (MediaItem) -> Void
    // Callback for play button
    var onPlaySelected: (MediaItem) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let itemHeight = geometry.size.height * 0.9 // Use most of the geometry height
            let itemWidth = geometry.size.width
            
            if items.isEmpty {
                // Placeholder if no items are available
                ZStack {
                    Color.gray.opacity(0.1)
                    ProgressView()
                }
                .frame(width: itemWidth, height: itemHeight)
                .clipped()
            } else {
                TabView(selection: $currentTab) {
                    ForEach(items) { item in
                        FeaturedBannerItemView(
                            item: item,
                            itemWidth: itemWidth,
                            itemHeight: itemHeight,
                            onPlaySelected: { onPlaySelected(item) },
                            onMoreInfoSelected: { onItemSelected(item) }
                        )
                        .tag(items.firstIndex(of: item) ?? 0)
                    }
                }
                .frame(width: itemWidth, height: itemHeight)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default page indicator
                .onAppear(perform: startTimer)
                .onDisappear(perform: stopTimer)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.55) // Set a significant height for the banner area
    }
    
    private func startTimer() {
        // Only start if there's more than one item
        guard items.count > 1 else { return }
        
        stopTimer() // Ensure any existing timer is stopped
        
        timerSubscription = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentTab = (currentTab + 1) % items.count
                }
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}

// Individual Item View for the Banner
struct FeaturedBannerItemView: View {
    @EnvironmentObject var jellyfinService: JellyfinService // Inject service for image URL
    let item: MediaItem
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    var onPlaySelected: () -> Void
    var onMoreInfoSelected: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Use AsyncImage with the imageUrl helper
            AsyncImage(url: jellyfinService.imageUrl(for: item.id, tag: item.primaryImageTag, type: .primary, maxHeight: 600)) { phase in // Request a decent res image
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemWidth, height: itemHeight)
                case .failure(_):
                    Image(systemName: "photo") // Placeholder on failure
                         .resizable()
                         .scaledToFit()
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                         .background(Color.gray.opacity(0.3))
                         .frame(width: itemWidth, height: itemHeight)
                case .empty:
                     ProgressView() // Placeholder while loading
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                         .background(Color.gray.opacity(0.1))
                         .frame(width: itemWidth, height: itemHeight)
                @unknown default:
                    EmptyView()
                }
            }
            .clipped() // Clip image to bounds
            // Gradient overlay
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .clear, .black.opacity(0.8), .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Content Overlay (Title, Description, Buttons)
            VStack(alignment: .leading, spacing: 12) {
                Spacer() // Push content to bottom
                
                // Use item.name and item.overview from new model
                Text(item.name)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 3)
                
                Text(item.overview ?? "No description available.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .shadow(radius: 2)
                
                HStack(spacing: 15) {
                    // Play Button
                    Button(action: onPlaySelected) {
                        Label("Play", systemImage: "play.fill")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .accessibility(identifier: "banner_play_button_\(item.id)")
                    
                    // More Info Button
                    Button(action: onMoreInfoSelected) {
                        Label("More Info", systemImage: "info.circle")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                     .accessibility(identifier: "banner_more_info_button_\(item.id)")
                }
                .padding(.top, 8)
                
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .frame(width: itemWidth, height: itemHeight)
        .background(Color.black) // Fallback background
    }
}

// Preview Provider
/*
struct FeaturedBannerCarouselView_Previews: PreviewProvider {
    static let previewItems = [
        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who enters the dreams of others to steal secrets from their subconscious."),
        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham... This is a slightly longer description to test line limits and how text wraps."),
        MediaItem(id: "3", title: "Interstellar", posterPath: "inception", type: .movie, year: "2014", rating: 8.6, overview: "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.")
    ]
    
    static var previews: some View {
        FeaturedBannerCarouselView(
            items: previewItems,
            onItemSelected: { item in print("Selected: \(item.title)") },
            onPlaySelected: { item in print("Play: \(item.title)") }
        )
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
*/ 