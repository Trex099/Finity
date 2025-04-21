import Foundation
import Combine
import UIKit
// REMOVED: import FirebaseFirestore // No longer needed for credentials

// Basic structure for Jellyfin Authentication Response
struct AuthenticationResponse: Codable {
    let user: User
    let sessionInfo: SessionInfo
    let accessToken: String
    let serverId: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case sessionInfo = "SessionInfo"
        case accessToken = "AccessToken"
        case serverId = "ServerId"
    }
}

struct User: Codable {
    let name: String
    let id: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
    }
}

struct SessionInfo: Codable {
    // Add relevant fields if needed
}

// Define Keychain keys as constants
private enum KeychainKeys {
    static let service = "com.finity.jellyfin"
    static let account = "userCredentials"
    static let serverURLKey = "serverURL"
    static let userIDKey = "userID"
    static let accessTokenKey = "accessToken"
}

class JellyfinService: ObservableObject {
    // Authentication State
    @Published var isAuthenticated = false
    @Published var serverURL: String? = nil
    @Published var accessToken: String? = nil
    @Published var userID: String? = nil
    @Published var username: String? = nil  // Add missing username property
    @Published var errorMessage: String? = nil
    @Published var isLoadingAuth = false // Renamed for clarity
    @Published var isCheckingAuth = true // New state for initial credential check
    
    // Fetched Data State
    @Published var latestItems: [MediaItem] = []
    @Published var continueWatchingItems: [MediaItem] = []
    @Published var recentlyAddedItems: [MediaItem] = [] // Assuming you might fetch this later
    @Published var movieItems: [MediaItem] = [] // New state for Movies
    @Published var showItems: [MediaItem] = [] // New state for TV Shows
    @Published var currentItemDetails: MediaItem? = nil
    @Published var isLoadingData = false // For general data loading
    
    private var cancellables = Set<AnyCancellable>()
    // REMOVED: private let db = Firestore.firestore()
    // REMOVED: private var firestoreListener: ListenerRegistration?

    // Initializer - Load credentials from Keychain
    init() {
        print("JellyfinService Initializing - Loading credentials from Keychain...")
        loadCredentialsFromKeychain()
        // isCheckingAuth will be set to false within loadCredentialsFromKeychain
    }
    
    // --- Keychain Credential Management ---
    
    private func saveCredentialsToKeychain() {
        guard let serverURL = self.serverURL, let userID = self.userID, let accessToken = self.accessToken else {
            print("Error: Missing credentials to save to Keychain.")
            return
        }

        do {
            // Store credentials as a dictionary encoded to Data
            let credentials = [
                KeychainKeys.serverURLKey: serverURL,
                KeychainKeys.userIDKey: userID,
                KeychainKeys.accessTokenKey: accessToken
            ]
            let data = try JSONEncoder().encode(credentials)
            
            // Delete existing item first to ensure update works
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: KeychainKeys.service,
                kSecAttrAccount as String: KeychainKeys.account
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // Add new item
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: KeychainKeys.service,
                kSecAttrAccount as String: KeychainKeys.account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // Good security practice
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status == errSecSuccess {
                print("Credentials successfully saved to Keychain.")
            } else {
                print("Error saving credentials to Keychain. Status: \(status)")
            }
        } catch {
            print("Error encoding credentials for Keychain: \(error.localizedDescription)")
        }
    }

    private func loadCredentialsFromKeychain() {
        // Start checking state
        DispatchQueue.main.async { self.isCheckingAuth = true }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKeys.service,
            kSecAttrAccount as String: KeychainKeys.account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        DispatchQueue.main.async { // Ensure UI updates happen on main thread
            self.isCheckingAuth = false // Finished checking
            if status == errSecSuccess {
                if let data = item as? Data {
                    do {
                        let credentials = try JSONDecoder().decode([String: String].self, from: data)
                        if let serverURL = credentials[KeychainKeys.serverURLKey],
                           let userID = credentials[KeychainKeys.userIDKey],
                           let accessToken = credentials[KeychainKeys.accessTokenKey] {
                            
                            print("Credentials loaded from Keychain for user: \(userID)")
                            self.serverURL = serverURL
                            self.userID = userID
                            self.accessToken = accessToken
                            self.isAuthenticated = true
                            self.errorMessage = nil
                            // Optionally trigger data fetch
                            // self.fetchInitialData()
                        } else {
                             print("Invalid credentials data format in Keychain item.")
                             self.clearAuthenticationLocally()
                        }
                    } catch {
                        print("Error decoding credentials from Keychain: \(error.localizedDescription)")
                        self.clearAuthenticationLocally()
                    }
                } else {
                    print("Keychain item found but data is not valid.")
                    self.clearAuthenticationLocally()
                }
            } else if status == errSecItemNotFound {
                 print("Credentials not found in Keychain.")
                 self.clearAuthenticationLocally()
            } else {
                print("Error loading credentials from Keychain. Status: \(status)")
                self.clearAuthenticationLocally()
            }
        }
    }

    private func clearCredentialsFromKeychain(completion: (() -> Void)? = nil) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKeys.service,
            kSecAttrAccount as String: KeychainKeys.account
        ]
        
        DispatchQueue.global(qos: .background).async { // Keychain operations can block
            let status = SecItemDelete(query as CFDictionary)
            DispatchQueue.main.async { // Update UI/state on main thread
                if status == errSecSuccess || status == errSecItemNotFound {
                    print("Credentials successfully removed from Keychain (or were not found).")
                } else {
                    print("Error removing credentials from Keychain. Status: \(status)")
                    // Handle error if needed
                }
                completion?()
            }
        }
    }
    
    // Separate function to clear local state without touching Keychain
    private func clearAuthenticationLocally() {
        isAuthenticated = false
        accessToken = nil
        userID = nil
        serverURL = nil // Clear server URL on local clear as well
        latestItems = []
        continueWatchingItems = []
        currentItemDetails = nil
        // Don't clear errorMessage here, might be useful
    }

    // --- Authentication Flow ---

    func authenticate(serverURL: String, username: String, password PlainPassword: String) {
        guard let url = URL(string: serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else { // Ensure no trailing slash
            self.errorMessage = "Invalid Server URL format."
            return
        }
        let authURL = url.appendingPathComponent("/Users/AuthenticateByName")
        let requestBody = ["Username": username, "Pw": PlainPassword]
        
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            self.errorMessage = "Failed to encode request body."
            return
        }

        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(clientAuthHeaderValue(), forHTTPHeaderField: "X-Emby-Authorization")
        request.httpBody = httpBody
        
        // Start loading state
        DispatchQueue.main.async {
            self.isLoadingAuth = true
            self.errorMessage = nil
        }

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(handleHTTPResponse)
            .decode(type: AuthenticationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingAuth = false
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "Authentication")
                    self?.clearAuthenticationLocally()
                    // Don't clear keychain on failed login attempt
                }
            }, receiveValue: { [weak self] authResponse in
                print("Authentication successful for user: \(authResponse.user.name)")
                self?.isAuthenticated = true
                self?.accessToken = authResponse.accessToken
                self?.userID = authResponse.user.id
                self?.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                self?.errorMessage = nil
                
                // Save credentials to Keychain on successful authentication
                self?.saveCredentialsToKeychain()
                
                // Optionally trigger initial data fetch
                // self?.fetchInitialData()
            })
            .store(in: &cancellables)
    }

    func logout() {
        print("Logging out...")
        // Clear local state FIRST
        clearAuthenticationLocally()
        // Then clear Keychain
        clearCredentialsFromKeychain() { [weak self] in
             print("User logged out and local/Keychain state cleared.")
        }
    }
    
    // MARK: - Data Fetching
    
    // Helper to fetch initial data (call after authentication or from relevant views)
    func fetchInitialHomeData() {
        // Ensure user is authenticated and we have userID
        guard isAuthenticated, userID != nil else {
            print("Cannot fetch initial home data: User not authenticated.")
            return
        }
        print("Fetching initial home data...")
        fetchLatestMedia(limit: 6)
        fetchContinueWatching()
        // fetchRecentlyAdded() // Call if/when implemented
        fetchMovies()
        fetchShows()
    }
    
    func fetchLatestMedia(limit: Int = 10) {
        // Safely unwrap userID
        guard let currentUserID = userID else {
            print("Error: Cannot fetch latest media, missing userID.")
            return
        }
        
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items/Latest", params: [
            "Limit": "\(limit)",
            "IncludeItemTypes": "Movie,Series", // Fetch both for banner variety
            "Fields": "PrimaryImageAspectRatio,UserData,Overview,Genres",
            "ImageTypeLimit": "1"
        ]) else { return }
        
        isLoadingData = true
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(handleHTTPResponse)
            .decode(type: [MediaItem].self, decoder: JSONDecoder()) // API returns array directly for Latest
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                 self?.isLoadingData = false
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Latest Media") }
             }, receiveValue: { [weak self] items in
                 print("Fetched \(items.count) latest items.")
                 self?.latestItems = items
             })
            .store(in: &cancellables)
    }
    
     func fetchContinueWatching(limit: Int = 10) {
        // Safely unwrap userID
        guard let currentUserID = userID else {
            print("Error: Cannot fetch continue watching, missing userID.")
            return
        }
        
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items", params: [
             "SortBy": "DatePlayed",
             "SortOrder": "Descending",
             "IncludeItemTypes": "Movie,Episode", // Typically only Movies and Episodes are resumable
             "Filters": "IsResumable",
             "Limit": "\(limit)",
             "Recursive": "true",
             "Fields": "PrimaryImageAspectRatio,UserData,ParentId,RunTimeTicks,IndexNumber,ParentIndexNumber,SeriesName", // Added IndexNumber, ParentIndexNumber, SeriesName
             "ImageTypeLimit": "1"
         ]) else { return }
         
         isLoadingData = true
         URLSession.shared.dataTaskPublisher(for: request)
             .tryMap(handleHTTPResponse)
             .decode(type: JellyfinItemsResponse<MediaItem>.self, decoder: JSONDecoder())
             .receive(on: DispatchQueue.main)
             .map { $0.items } // Extract the items array
             .sink(receiveCompletion: { [weak self] completion in
                 self?.isLoadingData = false
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Continue Watching") }
             }, receiveValue: { [weak self] items in
                 print("Fetched \(items.count) continue watching items.")
                 self?.continueWatchingItems = items
             })
             .store(in: &cancellables)
     }
     
     func fetchRecentlyAdded(limit: Int = 20) { // Example implementation
        guard let currentUserID = userID else { return }
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items", params: [
            "SortBy": "DateCreated", // Or DateAdded?
            "SortOrder": "Descending",
            "IncludeItemTypes": "Movie,Episode", // Or maybe just Movie, Series?
            "Filters": "IsUnplayed", // Optional filter
            "Limit": "\(limit)",
            "Recursive": "true",
            "Fields": "PrimaryImageAspectRatio,UserData,ParentId,RunTimeTicks,IndexNumber,ParentIndexNumber,SeriesName",
            "ImageTypeLimit": "1"
        ]) else { return }
        
        isLoadingData = true
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(handleHTTPResponse)
            .decode(type: JellyfinItemsResponse<MediaItem>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .map { $0.items }
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingData = false // Manage loading state more granularly if needed
                if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Recently Added") }
            }, receiveValue: { [weak self] items in
                print("Fetched \(items.count) recently added items.")
                self?.recentlyAddedItems = items // Update the correct state
            })
            .store(in: &cancellables)
     }
     
     // New function to fetch Movies
     func fetchMovies(limit: Int = 20, sortBy: String = "SortName", sortOrder: String = "Ascending") {
        guard let currentUserID = userID else { return }
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items", params: [
             "IncludeItemTypes": "Movie",
             "Recursive": "true",
             "SortBy": sortBy,
             "SortOrder": sortOrder,
             "Limit": "\(limit)",
             "Fields": "PrimaryImageAspectRatio,UserData", // Add other fields as needed by MediaRowView/MediaPosterCard
             "ImageTypeLimit": "1"
         ]) else { return }
         
         // Consider a separate isLoading flag for movies if needed
         // isLoadingData = true 
         URLSession.shared.dataTaskPublisher(for: request)
             .tryMap(handleHTTPResponse)
             .decode(type: JellyfinItemsResponse<MediaItem>.self, decoder: JSONDecoder())
             .receive(on: DispatchQueue.main)
             .map { $0.items }
             .sink(receiveCompletion: { [weak self] completion in
                 // self?.isLoadingData = false
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Movies") }
             }, receiveValue: { [weak self] items in
                 print("Fetched \(items.count) movie items.")
                 self?.movieItems = items
             })
             .store(in: &cancellables)
     }
     
     // New function to fetch TV Shows (Series)
     func fetchShows(limit: Int = 20, sortBy: String = "SortName", sortOrder: String = "Ascending") {
        guard let currentUserID = userID else { return }
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items", params: [
             "IncludeItemTypes": "Series", // Fetch Series type
             "Recursive": "true",
             "SortBy": sortBy,
             "SortOrder": sortOrder,
             "Limit": "\(limit)",
             "Fields": "PrimaryImageAspectRatio,UserData", // Add other fields as needed
             "ImageTypeLimit": "1"
         ]) else { return }
         
         // Consider a separate isLoading flag for shows if needed
         // isLoadingData = true
         URLSession.shared.dataTaskPublisher(for: request)
             .tryMap(handleHTTPResponse)
             .decode(type: JellyfinItemsResponse<MediaItem>.self, decoder: JSONDecoder())
             .receive(on: DispatchQueue.main)
             .map { $0.items }
             .sink(receiveCompletion: { [weak self] completion in
                 // self?.isLoadingData = false
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Shows") }
             }, receiveValue: { [weak self] items in
                 print("Fetched \(items.count) show items.")
                 self?.showItems = items
             })
             .store(in: &cancellables)
     }

     func fetchItemDetails(itemID: String) {
        // Safely unwrap userID
        guard let currentUserID = userID else {
            print("Error: Cannot fetch item details, missing userID.")
            return
        }
        
         // Add Fields parameter to get necessary data like RunTimeTicks and UserData
         guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/Items/\(itemID)", params: [
            "Fields": "PrimaryImageAspectRatio,UserData,Overview,Genres,RunTimeTicks" // Add fields needed by detail view
         ]) else { return }
         
         isLoadingData = true
         URLSession.shared.dataTaskPublisher(for: request)
             .tryMap(handleHTTPResponse)
             .decode(type: MediaItem.self, decoder: JSONDecoder())
             .receive(on: DispatchQueue.main)
             .sink(receiveCompletion: { [weak self] completion in
                 self?.isLoadingData = false
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Fetch Item Details (\(itemID))") }
             }, receiveValue: { [weak self] item in
                 print("Fetched details for item: \(item.name)")
                 self?.currentItemDetails = item
             })
             .store(in: &cancellables)
     }

    // MARK: - User Actions (Mark Favorite/Watched etc.)
    
    func toggleFavorite(itemId: String, currentStatus: Bool) {
        // Safely unwrap userID
        guard let currentUserID = userID else {
            print("Error: Cannot toggle favorite, missing userID.")
            return
        }
        
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(currentUserID)/FavoriteItems/\(itemId)", method: currentStatus ? "DELETE" : "POST") else { return }
        
        // We don't expect a meaningful body back, just check status code
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(handleHTTPResponse) // Checks for 2xx status
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                 if case .failure(let error) = completion { self?.handleAPIError(error, context: "Toggle Favorite (\(itemId))") }
                 else { 
                     print("Successfully toggled favorite status for \(itemId) to \(!currentStatus)")
                     // Optionally: Re-fetch item details or update local state if needed for immediate UI feedback
                     // self?.fetchItemDetails(itemID: itemId) // Might be too slow
                     // Or update the `currentItemDetails` directly if it matches itemId
                      if self?.currentItemDetails?.id == itemId {
                           self?.currentItemDetails?.userData?.isFavorite = !currentStatus // Note: Modifying nested state directly needs care
                      }
                     // TODO: Update the item in latestItems/continueWatchingItems if it exists there too
                 }
             }, receiveValue: { _ in /* No body expected */ })
            .store(in: &cancellables)
    }
    
    // TODO: Add methods for marking watched/unwatched, updating progress etc.

    // MARK: - Playback
    
    // Public wrapper for the private fetchPlaybackInfo method
    func getPlaybackInfo(for itemId: String) async throws -> PlaybackInfoResponse {
        return try await fetchPlaybackInfo(itemId: itemId)
    }
    
    // Report playback start to Jellyfin server
    func reportPlaybackStart(itemId: String, sessionId: String) async throws {
        guard isAuthenticated, let serverURL = serverURL, let userID = userID else {
            throw JellyfinError.notAuthenticated
        }
        
        let endpoint = "/Sessions/Playing"
        guard var urlComponents = URLComponents(string: serverURL + endpoint) else {
            throw JellyfinError.invalidURL("Invalid endpoint URL")
        }
        
        guard let url = urlComponents.url else {
            throw JellyfinError.invalidURL("Could not create final URL from components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MediaBrowser Token=\"\(accessToken ?? "")\"", forHTTPHeaderField: "Authorization")
        request.setValue(clientAuthHeaderValue(), forHTTPHeaderField: "X-Emby-Authorization")
        
        // Create the playback report payload
        let payload: [String: Any] = [
            "ItemId": itemId,
            "SessionId": sessionId,
            "PlaySessionId": sessionId,
            "MediaSourceId": itemId,
            "PositionTicks": 0,
            "IsPaused": false,
            "PlayMethod": "DirectPlay"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw JellyfinError.serializationError("Failed to serialize playback data: \(error.localizedDescription)")
        }
        
        // Send the request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? -1
            throw JellyfinError.serverError("Server returned error: \(statusCode)")
        }
        
        print("Successfully reported playback start for item: \(itemId)")
    }
    
    // New function to get PlaybackInfo
    private func fetchPlaybackInfo(itemId: String) async throws -> PlaybackInfoResponse {
        guard let serverURL = self.serverURL, let accessToken = self.accessToken else {
            throw JellyfinError.notAuthenticated
        }
        
        // Construct URL for PlaybackInfo endpoint
        let playbackInfoURLString = "\(serverURL)/Items/\(itemId)/PlaybackInfo"
        guard let playbackInfoURL = URL(string: playbackInfoURLString) else {
            throw JellyfinError.invalidURL("Invalid playback info URL")
        }
        
        // Create request with the appropriate headers
        var request = URLRequest(url: playbackInfoURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("MediaBrowser Client=\"Finity\", Device=\"iOS\", DeviceId=\"\(UIDevice.current.identifierForVendor?.uuidString ?? "Unknown")\", Version=\"1.0.0\"", forHTTPHeaderField: "X-Emby-Authorization")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create the body data
        let bodyData = [
            "DeviceProfile": [
                "MaxStreamingBitrate": 20000000, // 20Mbps
                "MaxStaticBitrate": 20000000,    // 20Mbps
                "MusicStreamingTranscodingBitrate": 192000, // 192kbps
                "DirectPlayProfiles": [
                    ["Type": "Video", "Container": "mp4,m4v,mov", "VideoCodec": "h264,hevc,mpeg4", "AudioCodec": "aac,mp3,ac3,eac3,flac,mp2,pcm"]
                ],
                "TranscodingProfiles": [
                    ["Type": "Video", "Container": "ts", "VideoCodec": "h264", "AudioCodec": "aac", "Protocol": "hls", "EstimateContentLength": false]
                ],
                "ContainerProfiles": [],
                "CodecProfiles": [],
                "SubtitleProfiles": [
                    ["Format": "srt", "Method": "External"],
                    ["Format": "srt", "Method": "Embed"],
                    ["Format": "ass", "Method": "External"],
                    ["Format": "ass", "Method": "Embed"],
                    ["Format": "vtt", "Method": "External"],
                    ["Format": "vtt", "Method": "Embed"],
                    ["Format": "sub", "Method": "External"],
                    ["Format": "sub", "Method": "Embed"]
                ]
            ]
        ] as [String: Any]
        
        // Serialize the body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData)
        } catch {
            throw JellyfinError.serializationError("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        // Send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for successful HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? -1
                let dataString = String(data: data, encoding: .utf8) ?? "No data"
                throw JellyfinError.serverError("Server returned error: \(statusCode). Response: \(dataString)")
            }
            
            // Parse the response
            let decoder = JSONDecoder()
            let playbackInfo = try decoder.decode(PlaybackInfoResponse.self, from: data)
            
            return playbackInfo
        } catch let decodingError as DecodingError {
            // Handle JSON decoding errors specifically
            throw JellyfinError.decodingError("Failed to decode server response: \(decodingError.localizedDescription)")
        } catch let urlError as URLError {
            // Handle network errors
            throw JellyfinError.networkError("Network error: \(urlError.localizedDescription)")
        } catch {
            // Re-throw our custom errors or wrap unknown errors
            if let jellyfinError = error as? JellyfinError {
                throw jellyfinError
            }
            throw JellyfinError.unknown("Unknown error: \(error.localizedDescription)")
        }
    }
    
    // Helper to create DeviceInfo
    private func createDeviceInfo() -> DeviceInfo {
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Finity"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let deviceName = UIDevice.current.name
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
        return DeviceInfo(deviceName: deviceName, deviceId: deviceId, appName: appName, appVersion: appVersion)
    }

    // MARK: - Request Building & Handling Helpers

    private func buildAuthenticatedRequest(endpoint: String, method: String = "GET", params: [String: String]? = nil) -> URLRequest? {
        // Check authentication state and required components
        guard isAuthenticated, let serverURL = serverURL, let _ = userID, let accessToken = accessToken else { // userID is checked but not used here
            print("Error: Attempted to build request while not authenticated or missing server/user/token.")
            return nil
        }
        
        guard var urlComponents = URLComponents(string: serverURL + endpoint) else {
            print("Error: Invalid endpoint for URLComponents - \(endpoint)")
            return nil
        }
        
        if let params = params {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            print("Error: Could not create final URL from components.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        // Standard Jellyfin API token header
        request.setValue("MediaBrowser Token=\"\(accessToken)\"", forHTTPHeaderField: "Authorization")
        // Also include the client info header
        request.setValue(clientAuthHeaderValue(), forHTTPHeaderField: "X-Emby-Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Expect JSON response

        return request
    }
    
    private func handleHTTPResponse(output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
             print("Error: Invalid HTTP response received.")
             throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
         }
         print("Response Status Code [\(httpResponse.url?.lastPathComponent ?? "")]: \(httpResponse.statusCode)")
         guard (200...299).contains(httpResponse.statusCode) else {
              let errorText = String(data: output.data, encoding: .utf8) ?? "Unknown API error (Status: \(httpResponse.statusCode))"
              print("API Error Body: \(errorText)")
              // Include status code in the error userInfo
              var userInfo: [String: Any] = [NSLocalizedDescriptionKey: errorText]
              userInfo[NSURLErrorKey] = httpResponse.statusCode
              throw URLError(.init(rawValue: httpResponse.statusCode), userInfo: userInfo)
         }
         return output.data
     }
     
     private func handleAPIError(_ error: Error, context: String) {
         print("API Error [\(context)]: \(error)")
         if let urlError = error as? URLError, let description = urlError.userInfo[NSLocalizedDescriptionKey] as? String {
             errorMessage = "[\(context)] Error: \(description)"
         } else {
              errorMessage = "[\(context)] Error: \(error.localizedDescription)"
         }
         // Optionally clear specific data on error
         // if context == "Fetch Latest Media" { latestItems = [] }
     }
     
     private func clientAuthHeaderValue() -> String {
         // Construct the X-Emby-Authorization header value
         // TODO: Use actual device name and generate/store a unique DeviceId
         let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Finity"
         let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
         let deviceName = UIDevice.current.name
         let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
         
         return "MediaBrowser Client=\"\(appName)\", Device=\"iOS\", DeviceName=\"\(deviceName)\", Version=\"\(appVersion)\", Token=\"\(accessToken ?? "")\", DeviceId=\"\(deviceId)\""
     }

    // MARK: - URL Helpers
    func sanitizeServerURL(_ url: String) -> String {
        var sanitized = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if protocol is missing
        if !sanitized.lowercased().hasPrefix("http://") && !sanitized.lowercased().hasPrefix("https://") {
            sanitized = "https://" + sanitized
        }
        
        // Ensure URL ends with a trailing slash
        if !sanitized.hasSuffix("/") {
            sanitized += "/"
        }
        
        return sanitized
    }

    // MARK: - Authentication
    func loadCredentials() {
        print("JellyfinService Initializing - Loading credentials from Keychain...")
        
        // Get credentials from Keychain using our new KeychainHelper
        let serverURL = KeychainHelper.standard.readString(for: "serverURL")
        let username = KeychainHelper.standard.readString(for: "username")
        let userId = KeychainHelper.standard.readString(for: "userId")
        let accessToken = KeychainHelper.standard.readString(for: "accessToken")
        
        // If credentials exist, set them
        if let savedServerURL = serverURL, let savedUsername = username,
           let savedUserId = userId, let savedAccessToken = accessToken {
            
            // Sanitize the server URL to ensure it has protocol and ends with slash
            let sanitizedURL = sanitizeServerURL(savedServerURL)
            
            self.serverURL = sanitizedURL
            self.username = savedUsername
            self.userID = savedUserId // Note: using userID (not userId) to match the property name
            self.accessToken = savedAccessToken
            
            print("Credentials loaded from Keychain for user: \(self.userID ?? "unknown")")
        } else {
            print("No credentials found in Keychain.")
        }
    }
    
    func saveCredentials(serverURL: String, username: String, userId: String, accessToken: String) {
        // Sanitize the server URL to ensure it has protocol and ends with slash
        let sanitizedURL = sanitizeServerURL(serverURL)
        
        // Save to keychain using our new KeychainHelper
        KeychainHelper.standard.save(sanitizedURL, for: "serverURL")
        KeychainHelper.standard.save(username, for: "username")
        KeychainHelper.standard.save(userId, for: "userId")
        KeychainHelper.standard.save(accessToken, for: "accessToken")
        
        // Set instance variables
        self.serverURL = sanitizedURL
        self.username = username
        self.userID = userId // Note: using userID (not userId) to match the property name
        self.accessToken = accessToken
        
        print("Credentials saved to Keychain.")
    }

} 