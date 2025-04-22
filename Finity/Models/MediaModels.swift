import Foundation

// MARK: - Media Items

// Standard Media Item structure (from Jellyfin)
struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let serverId: String?
    let type: String?
    let path: String?
    
    // Media details
    let overview: String?
    let taglines: [String]?
    let genres: [String]?
    let studios: [MediaStudio]?
    let productionYear: Int?
    let officialRating: String?
    let communityRating: Double?
    let runTimeTicks: Int64?
    
    // Media metadata
    let seriesName: String?
    let seriesId: String?
    let seasonId: String?
    let parentId: String?
    let indexNumber: Int?  // Episode number or disc number
    let parentIndexNumber: Int? // Season number
    
    // Image paths and properties
    let imageTags: [String: String]?
    let primaryImageTag: String?
    let primaryImageAspectRatio: Double?
    let backdropImageTags: [String]?
    
    // User specific data
    let userData: UserItemData?
    
    // Computed properties (for convenience)
    var imageUrl: URL? {
        // Simplified example - construct based on id and primaryImageTag if available
        guard let tag = primaryImageTag else { return nil }
        return URL(string: "PLACEHOLDER_SERVER_URL/Items/\(id)/Images/Primary?tag=\(tag)")
    }
    
    var backdropUrl: URL? {
        // Simplified example - construct first backdrop if available
        guard let tags = backdropImageTags, !tags.isEmpty else { return nil }
        return URL(string: "PLACEHOLDER_SERVER_URL/Items/\(id)/Images/Backdrop?tag=\(tags[0])")
    }
    
    var runtimeFormatted: String {
        guard let ticks = runTimeTicks else { return "Unknown" }
        let seconds = Double(ticks) / 10_000_000.0
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Minimal studio information
struct MediaStudio: Codable, Hashable {
    let name: String
    let id: String
}

// User-specific data for items (like watched status)
struct UserItemData: Codable, Hashable {
    let playedPercentage: Double?
    let playbackPositionTicks: Int64?
    let playCount: Int?
    let isFavorite: Bool
    let played: Bool
    
    // Constructor with defaults for convenience
    init(playbackPositionTicks: Int64? = nil, playCount: Int? = nil, isFavorite: Bool = false, played: Bool = false, playedPercentage: Double? = nil) {
        self.playbackPositionTicks = playbackPositionTicks
        self.playCount = playCount
        self.isFavorite = isFavorite
        self.played = played
        self.playedPercentage = playedPercentage
    }
    
    var formattedProgress: String {
        guard let progress = playedPercentage else { return "" }
        return "\(Int(progress))%"
    }
    
    var progressValueForBar: Float {
        guard let progress = playedPercentage else { return 0 }
        return Float(progress) / 100.0
    }
}

// MARK: - Response Structures

// Container for Multiple Items
struct JellyfinItemsResponse<T: Codable>: Codable {
    let items: [T]
    let totalRecordCount: Int
}

// MARK: - Playback Structures

// Response from PlaybackInfo endpoint
struct PlaybackInfoResponse: Codable {
    let mediaSources: [MediaSourceInfo]
    // Add other fields as needed from actual API response
}

// Detailed info about a media source
struct MediaSourceInfo: Codable {
    let id: String
    let name: String?
    let path: String?
    let protocolName: String?
    let encoderProtocol: String?
    let encoderPath: String?
    let type: String?
    let container: String?
    let size: Int64?
    let isRemote: Bool?
    let isInfiniteStream: Bool?
    let runTimeTicks: Int64?
    
    // Video/Audio/Subtitle info
    let mediaStreams: [MediaStreamInfo]?
    
    // Transcoding flags
    let supportsDirectPlay: Bool?
    let supportsDirectStream: Bool?
    let supportsTranscoding: Bool?
    let requiresTranscoding: Bool?
    let requiresOpening: Bool?
    
    // Other useful fields
    let bitrate: Int?
    let defaultAudioStreamIndex: Int?
    let defaultSubtitleStreamIndex: Int?
}

// Information about specific media streams (video/audio/subtitle tracks)
struct MediaStreamInfo: Codable {
    let codec: String?
    let language: String?
    let displayTitle: String?
    let isDefault: Bool?
    let type: String? // "Video", "Audio", "Subtitle"
    let index: Int?
    let channels: Int?
    let sampleRate: Int?
    let bitRate: Int?
    let width: Int?
    let height: Int?
    let aspectRatio: String?
    let averageFrameRate: Float?
    let realFrameRate: Float?
    let profile: String?
    let level: Int?
    let pixelFormat: String?
    let deliveryMethod: String?
    let deliveryUrl: String?
    let isExternal: Bool?
    let isTextSubtitleStream: Bool?
    let supportsExternalStream: Bool?
    
    // Probably more fields available based on media type
}

// MARK: - Device & Playback Reporting

// Device Info structure
struct DeviceInfo: Encodable {
    let deviceName: String
    let deviceId: String
    let appName: String
    let appVersion: String
}

// Jellyfin Error Types
enum JellyfinError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL(String)
    case networkError(String)
    case serverError(String)
    case decodingError(String)
    case serializationError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in first."
        case .invalidURL(let detail):
            return "Invalid URL: \(detail)"
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .serverError(let detail):
            return "Server error: \(detail)"
        case .decodingError(let detail):
            return "Failed to decode response: \(detail)"
        case .serializationError(let detail):
            return "Failed to serialize request: \(detail)"
        case .unknown(let detail):
            return "Unknown error: \(detail)"
        }
    }
}

// MARK: - UI Models

// MediaRow model for horizontal media rows in the UI
struct MediaRow: Identifiable {
    var id = UUID()
    let title: String
    let items: [MediaItem]
} 