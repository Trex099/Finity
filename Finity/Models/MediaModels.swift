import Foundation

// Represents a Jellyfin Item (BaseItemDto) - adaptable for Movies, Shows, Episodes etc.
struct MediaItem: Identifiable, Codable, Hashable {
    let id: String // Jellyfin's Item ID
    let name: String // Title
    let serverId: String? // Server ID (useful if handling multiple servers)
    let type: String // e.g., "Movie", "Series", "Episode"
    let overview: String?
    let productionYear: Int?
    let communityRating: Double?
    let officialRating: String? // e.g., "PG-13"
    let imageTags: [String: String]? // Contains keys like "Primary", value is the tag
    let backdropImageTags: [String]? // Array of tags for backdrops
    let userData: UserData? // User-specific data like played status, progress
    let genres: [String]? // List of genres
    // Add other relevant fields as needed: People (cast), Studios, RunTimeTicks etc.
    
    // Conformance to Identifiable using Jellyfin's ID
    var identifier: String { id }
    
    // Conformance to Hashable (needed for NavigationDestination)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }

    // CodingKeys to map JSON names (PascalCase) to Swift names (camelCase)
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case serverId = "ServerId"
        case type = "Type"
        case overview = "Overview"
        case productionYear = "ProductionYear"
        case communityRating = "CommunityRating"
        case officialRating = "OfficialRating"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case userData = "UserData"
        case genres = "Genres"
        // Map other fields if added
    }
    
    // Helper to get the primary image tag
    var primaryImageTag: String? {
        return imageTags?["Primary"]
    }
}

// Represents the UserData part of a Jellyfin Item
struct UserData: Codable, Hashable {
    let playbackPositionTicks: Int?
    let playCount: Int?
    let isFavorite: Bool?
    let played: Bool?
    let playedPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
        case playedPercentage = "PlayedPercentage"
    }
    
    // Helper to check if item is resumable (has position and not fully played)
    var isResumable: Bool {
        (playbackPositionTicks ?? 0) > 0 && !(played ?? false)
    }
}

// Generic response structure for API calls returning lists of items
struct JellyfinItemsResponse<T: Codable>: Codable {
    let items: [T]
    let totalRecordCount: Int
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
    }
}

// Row of content for horizontal scrolling
struct MediaRow: Identifiable {
    let id = UUID()
    let title: String
    let items: [MediaItem]
} 