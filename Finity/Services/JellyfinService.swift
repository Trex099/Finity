import Foundation
import Combine

class JellyfinService: ObservableObject {
    private let baseURL: String
    private let apiKey: String
    
    @Published var featuredContent: [MediaItem] = []
    @Published var categories: [MediaRow] = []
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // In a real implementation, these would make actual API calls to Jellyfin
    func fetchFeaturedContent() {
        // Mock data for now
        self.featuredContent = [
            MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets through the use of dream-sharing technology."),
            MediaItem(id: "2", title: "Stranger Things", posterPath: "strangerthings", type: .tvShow, year: "2016", rating: 8.7, overview: "When a young boy disappears, his mother, a police chief, and his friends must confront terrifying forces.")
        ]
    }
    
    func fetchCategories() {
        // Mock data organized by categories
        self.categories = [
            MediaRow(title: "Recently Added", items: [
                MediaItem(id: "3", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge yet."),
                MediaItem(id: "4", title: "Breaking Bad", posterPath: "breakingbad", type: .tvShow, year: "2008", rating: 9.5, overview: "A high school chemistry teacher turned methamphetamine producer.")
            ]),
            MediaRow(title: "Action Movies", items: [
                MediaItem(id: "5", title: "Mad Max: Fury Road", posterPath: "madmax", type: .movie, year: "2015", rating: 8.1, overview: "In a post-apocalyptic wasteland, a woman rebels against a tyrannical ruler."),
                MediaItem(id: "6", title: "John Wick", posterPath: "johnwick", type: .movie, year: "2014", rating: 7.4, overview: "An ex-hitman comes out of retirement to track down the gangsters who killed his dog.")
            ]),
            MediaRow(title: "Popular TV Shows", items: [
                MediaItem(id: "7", title: "Game of Thrones", posterPath: "got", type: .tvShow, year: "2011", rating: 9.3, overview: "Nine noble families fight for control over the lands of Westeros."),
                MediaItem(id: "8", title: "The Mandalorian", posterPath: "mandalorian", type: .tvShow, year: "2019", rating: 8.8, overview: "The travels of a lone bounty hunter in the outer reaches of the galaxy.")
            ])
        ]
    }
} 