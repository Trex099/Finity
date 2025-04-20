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
    var userData: UserData? // Make mutable for optimistic updates
    let genres: [String]? // List of genres
    let runTimeTicks: Int? // Add runtime ticks
    let indexNumber: Int? // Episode number
    let parentIndexNumber: Int? // Season number
    let seriesName: String? // Name of the parent series
    // Add other relevant fields as needed: People (cast), Studios etc.
    
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
        case runTimeTicks = "RunTimeTicks"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case seriesName = "SeriesName"
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
    var isFavorite: Bool? // Make mutable for optimistic updates
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

// MARK: - Playback Info Structures (from /PlaybackInfo endpoint)

// Payload to send TO the server
struct DeviceInfo: Codable {
    let deviceName: String
    let deviceId: String
    let appName: String
    let appVersion: String
    // Add more fields as needed, e.g., SupportedCodecs, MaxStreamingBitrate
    // For now, keep it simple
    
    enum CodingKeys: String, CodingKey {
        case deviceName = "DeviceName"
        case deviceId = "DeviceId"
        case appName = "AppName"
        case appVersion = "AppVersion"
    }
}

// Response FROM the server
struct PlaybackInfoResponse: Codable {
    let mediaSources: [MediaSourceInfo]
    let playSessionId: String?

    enum CodingKeys: String, CodingKey {
        case mediaSources = "MediaSources"
        case playSessionId = "PlaySessionId"
    }
}

struct MediaSourceInfo: Codable, Identifiable {
    let `protocol`: String? // e.g., "Http", "Hls"
    let id: String? // Often the item ID, but can differ
    let path: String? // The URL path (can be relative or absolute)
    let type: String? // e.g., "Default", "Grouping"
    let container: String? // e.g., "mkv", "mp4", "ts"
    let size: Int64?
    let name: String?
    
    let isRemote: Bool?
    let runTimeTicks: Int64?
    let supportsDirectPlay: Bool?
    let supportsDirectStream: Bool?
    let supportsTranscoding: Bool?
    let isInfiniteStream: Bool?
    let requiresOpening: Bool?
    let requiresClosing: Bool?
    let videoType: String? // e.g., "h264", "hevc"
    let audioStreamIndex: Int?
    let videoStreamIndex: Int?
    let transcodeReasons: [String]? // Why transcoding might be needed
    
    // Simplified mapping for common fields
    enum CodingKeys: String, CodingKey {
        case `protocol` = "Protocol"
        case id = "Id"
        case path = "Path"
        case type = "Type"
        case container = "Container"
        case size = "Size"
        case name = "Name"
        case isRemote = "IsRemote"
        case runTimeTicks = "RunTimeTicks"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsDirectStream = "SupportsDirectStream"
        case supportsTranscoding = "SupportsTranscoding"
        case isInfiniteStream = "IsInfiniteStream"
        case requiresOpening = "RequiresOpening"
        case requiresClosing = "RequiresClosing"
        case videoType = "VideoType" // Correct based on typical Jellyfin API
        case audioStreamIndex = "AudioStreamIndex"
        case videoStreamIndex = "VideoStreamIndex"
        case transcodeReasons = "TranscodeReasons"
    }
    
    // Add Identifiable conformance if needed (using 'id' or generating one)
     var identifiableId: String { id ?? UUID().uuidString }
} 