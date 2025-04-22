import Foundation
import MobileVLCKit   // For VLCMediaPlayer, VLCMedia, etc.
// import VLCKitSPM   // Removed this import
import SwiftUI        // For UIDevice

// Basic ViewModel protocol (optional, but good practice)
class ViewModel: ObservableObject {
    init() {}
}

// Adapted from Swiftfin's VideoPlayerViewModel
final class VideoPlayerViewModel: ViewModel, Equatable {

    let playbackURL: URL
    let itemID: String
    let itemName: String
    // For playback reporting
    var playSessionID: String? = UUID().uuidString
    // Add other necessary item details if needed (e.g., duration for UI pre-loading)
    // let runTimeSeconds: Double? // Example

    // Configuration for the VLC player
    var vlcVideoPlayerConfiguration: VLCVideoPlayer.Configuration {
        var configuration = VLCVideoPlayer.Configuration(url: playbackURL)
        configuration.autoPlay = true
        // Add other VLC configurations as needed (subtitles, audio tracks, start time etc.)
        // configuration.startTime = .seconds(...)
        // configuration.audioIndex = .absolute(...)
        // configuration.subtitleIndex = .absolute(...)
        return configuration
    }

    // Initializer requires the final playback URL
    init(
        playbackURL: URL,
        itemID: String,
        itemName: String
        // runTimeSeconds: Double? = nil // Example
    ) {
        self.playbackURL = playbackURL
        self.itemID = itemID
        self.itemName = itemName
        // self.runTimeSeconds = runTimeSeconds
        super.init()
        print("VideoPlayerViewModel initialized with URL: \(playbackURL.absoluteString)")
    }

    // Equatable conformance
    static func == (lhs: VideoPlayerViewModel, rhs: VideoPlayerViewModel) -> Bool {
        lhs.itemID == rhs.itemID &&
            lhs.playbackURL == rhs.playbackURL
    }

    // --- Static Helper for URL Construction (Moved from MediaPlayerView_New) ---

    // Fetches PlaybackInfo and constructs the appropriate URL
    static func create(itemId: String, itemName: String, jellyfinService: JellyfinService) async throws -> VideoPlayerViewModel {
        print("Creating VideoPlayerViewModel for item: \(itemId)")
        
        // We need to make this method public in JellyfinService
        let playbackInfo = try await getPlaybackInfoFromService(itemId: itemId, jellyfinService: jellyfinService)
        print("Got playback info with \(playbackInfo.mediaSources.count) media sources.")

        guard !playbackInfo.mediaSources.isEmpty else {
            throw PlayerError.noMediaSources
        }

        // Try constructing direct play/stream URL first
        if let directUrl = constructPlaybackURL(sources: playbackInfo.mediaSources, jellyfinService: jellyfinService) {
             print("Using direct playback URL: \(directUrl.absoluteString)")
             // let duration = playbackInfo.mediaSources.first?.runTimeTicks.map { Double($0) / 10_000_000.0 } // Example duration extraction
             return VideoPlayerViewModel(playbackURL: directUrl, itemID: itemId, itemName: itemName /*, runTimeSeconds: duration*/)

        } else if let hlsUrl = constructManualHLSURL(itemId: itemId, jellyfinService: jellyfinService) {
             // Fallback to manual HLS URL construction
             print("Direct playback URL construction failed or not available, using manually constructed HLS URL: \(hlsUrl.absoluteString)")
             // let duration = playbackInfo.mediaSources.first?.runTimeTicks.map { Double($0) / 10_000_000.0 } // Example duration extraction
             return VideoPlayerViewModel(playbackURL: hlsUrl, itemID: itemId, itemName: itemName /*, runTimeSeconds: duration*/)

        } else {
            print("Failed to construct any valid playback URL.")
            throw PlayerError.urlConstructionFailed
        }
    }
    
    // Helper method to access the private fetchPlaybackInfo method
    private static func getPlaybackInfoFromService(itemId: String, jellyfinService: JellyfinService) async throws -> PlaybackInfoResponse {
        // Implement a wrapper to fetch playback info
        // This will need to be implemented in JellyfinService as a public method
        return try await jellyfinService.getPlaybackInfo(for: itemId)
    }

    // Helper function to construct the direct playback URL (adapted from MediaPlayerView_New)
    private static func constructPlaybackURL(sources: [MediaSourceInfo], jellyfinService: JellyfinService) -> URL? {
         // Simplified: Try the first source path directly if it's HTTP/HTTPS
         // You might want to re-introduce the more specific logic from MediaPlayerView (prioritizing HLS, DirectStream, DirectPlay) here for robustness
        guard let source = sources.first, let path = source.path else {
            print("Error: No suitable media source found or first source has no path.")
            return nil
        }

        // Check if path is absolute HTTP/HTTPS URL
        if path.lowercased().hasPrefix("http://") || path.lowercased().hasPrefix("https://") {
            print("Constructing URL from absolute path: \(path)")
            return URL(string: path)
        }
        // Check if path is a relative web path (starts with /) - Needs Server Base URL
        else if path.hasPrefix("/") {
            guard let serverURL = jellyfinService.serverURL else {
                print("Error: Cannot construct relative URL, missing serverURL.")
                return nil
            }
            // Ensure no double slash
            let serverURLString = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
            let fullPath = serverURLString + path
            print("Constructing URL from relative path: \(fullPath)")

            // Add authentication if needed (example, adjust based on Jellyfin requirements)
            if var components = URLComponents(string: fullPath), let token = jellyfinService.accessToken {
                 if components.queryItems == nil { components.queryItems = [] }
                 // Only add api_key if it's not already present
                 if !(components.queryItems?.contains(where: { $0.name.lowercased() == "api_key" }) ?? false) {
                     components.queryItems?.append(URLQueryItem(name: "api_key", value: token))
                     print("Added api_key to URL.")
                 }
                 return components.url
             } else {
                // Return URL without token if token unavailable or components failed
                return URL(string: fullPath)
             }
        } else {
            print("Error: Media source path is not a recognized format (absolute http/https or relative /): \(path)")
            return nil
        }
    }


    // Helper function to construct the manual HLS URL (adapted from MediaPlayerView_New)
    private static func constructManualHLSURL(itemId: String, jellyfinService: JellyfinService) -> URL? {
        guard let serverURL = jellyfinService.serverURL,
              let token = jellyfinService.accessToken else {
            print("Error constructing manual HLS URL: Missing serverURL or accessToken.")
            return nil
        }

        // Construct base URL
        let serverURLString = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
        
        // Construct full URL path
        // Note: Swiftfin uses /Videos/{ItemID}/master.m3u8?MediaSourceId={MediaSourceId}&DeviceId=...&Tag=...
        // Your previous code used /Videos/{ItemID}/stream.m3u8?api_key=...&deviceId=...&MediaSourceId=...
        // Let's stick to your previous `stream.m3u8` for now, but be aware Swiftfin uses `master.m3u8` with more params.
        let urlString = "\(serverURLString)/Videos/\(itemId)/stream.m3u8"

        guard var components = URLComponents(string: urlString) else {
            print("Error: Could not create URL components from \(urlString)")
            return nil
        }

        // Add necessary query parameters (combine yours and potentially some from Swiftfin if needed)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString // Generate fallback if needed
        let queryItems = [
            URLQueryItem(name: "api_key", value: token), // Auth
            URLQueryItem(name: "deviceId", value: deviceId), // Identify client device
            URLQueryItem(name: "MediaSourceId", value: itemId), // Link to original media source (often same as itemId for single source items)
            // Basic transcoding parameters (adjust as needed, check Jellyfin docs/Swiftfin for optimal values)
            URLQueryItem(name: "videoCodec", value: "h264"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "maxAudioChannels", value: "2"), // Stereo
            URLQueryItem(name: "maxWidth", value: "1920"),     // Limit resolution if needed
            URLQueryItem(name: "maxHeight", value: "1080"),
            // Potentially useful parameters (might be needed for stability/compatibility)
            // URLQueryItem(name: "PlaySessionId", value: UUID().uuidString), // Helps Jellyfin track session
            // URLQueryItem(name: "Static", value: "true"), // Use 'true' for VOD, 'false' for live (Swiftfin uses this on master.m3u8)
            // URLQueryItem(name: "RequireAvc", value: "true"), // Request AVC/H.264 specifically
        ]

        components.queryItems = queryItems

        print("Constructed manual HLS streaming URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return components.url
    }
}

// Custom Error Enum for Player Setup
enum PlayerError: Error, LocalizedError {
    case noMediaSources
    case urlConstructionFailed
    case playbackInfoFetchFailed(Error)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .noMediaSources:
            return "No playable media sources found for this item."
        case .urlConstructionFailed:
            return "Could not create a valid playback URL."
        case .playbackInfoFetchFailed(let underlyingError):
            return "Failed to fetch playback information: \(underlyingError.localizedDescription)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

// REMOVED PLACEHOLDER STRUCTS FOR MediaSourceInfo and PlaybackInfoResponse
// Ensure these types are correctly defined in your Models/MediaModels.swift file. 