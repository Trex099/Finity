import Foundation

// Basic media item that can be a movie, TV show, or music
struct MediaItem: Identifiable {
    let id: String
    let title: String
    let posterPath: String
    let type: MediaType
    let year: String
    let rating: Double
    let overview: String
}

enum MediaType {
    case movie
    case tvShow
    case music
}

// Row of content for horizontal scrolling
struct MediaRow: Identifiable {
    let id = UUID()
    let title: String
    let items: [MediaItem]
} 