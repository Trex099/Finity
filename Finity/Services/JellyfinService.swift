import Foundation
import Combine
import UIKit

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

class JellyfinService: ObservableObject {
    // Authentication State
    @Published var isAuthenticated = false
    @Published var serverURL: String? = nil
    @Published var accessToken: String? = nil
    @Published var userID: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoadingAuth = false // Renamed for clarity
    
    // Fetched Data State
    @Published var latestItems: [MediaItem] = []
    @Published var continueWatchingItems: [MediaItem] = []
    @Published var currentItemDetails: MediaItem? = nil
    @Published var isLoadingData = false // For general data loading
    
    private var cancellables = Set<AnyCancellable>()

    // Initializer - No longer takes apiKey directly
    init() {
        // TODO: Load saved credentials from Keychain if available
        // For now, starts unauthenticated
        print("JellyfinService Initialized")
    }

    // Authentication function
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
        
        isLoadingAuth = true
        self.errorMessage = nil

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(handleHTTPResponse)
            .decode(type: AuthenticationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingAuth = false
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "Authentication")
                    self?.clearAuthentication()
                }
            }, receiveValue: { [weak self] authResponse in
                print("Authentication successful for user: \(authResponse.user.name)")
                self?.isAuthenticated = true
                self?.accessToken = authResponse.accessToken
                self?.userID = authResponse.user.id
                self?.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) // Store cleaned URL
                self?.errorMessage = nil
                // TODO: Securely save credentials
            })
            .store(in: &cancellables)
    }

    func logout() {
        clearAuthentication()
        // TODO: Remove credentials from Keychain
        print("User logged out.")
    }
    
    private func clearAuthentication() {
        isAuthenticated = false
        accessToken = nil
        userID = nil
        serverURL = nil
        // Clear fetched data as well
        latestItems = []
        continueWatchingItems = []
        currentItemDetails = nil
    }

    // MARK: - Data Fetching
    
    func fetchLatestMedia(limit: Int = 10) {
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(userID!)/Items/Latest", params: [
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
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(userID!)/Items", params: [
             "SortBy": "DatePlayed",
             "SortOrder": "Descending",
             "IncludeItemTypes": "Movie,Episode", // Typically only Movies and Episodes are resumable
             "Filters": "IsResumable",
             "Limit": "\(limit)",
             "Recursive": "true",
             "Fields": "PrimaryImageAspectRatio,UserData,ParentId,RunTimeTicks", // Add RunTimeTicks
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
     
     func fetchItemDetails(itemID: String) {
         // Add Fields parameter to get necessary data like RunTimeTicks and UserData
         guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(userID!)/Items/\(itemID)", params: [
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
        guard let request = buildAuthenticatedRequest(endpoint: "/Users/\(userID!)/FavoriteItems/\(itemId)", method: currentStatus ? "DELETE" : "POST") else { return }
        
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
    
    func getVideoStreamURL(itemId: String) -> URL? {
        // Check authentication state and required components
        guard isAuthenticated, let serverURL = serverURL, let _ = accessToken else { // accessToken is checked but not used here
            print("Error: Cannot get stream URL, not authenticated or missing server/token.")
            return nil
        }
        
        // Construct the streaming URL. Note: This doesn't require extra headers usually,
        // as the access token might be passed as a query parameter if needed by server config,
        // but often the established session cookie handles it. Check Jellyfin docs if auth fails.
        // Let's assume direct URL works for now.
        let urlString = "\(serverURL)/Videos/\(itemId)/stream?static=true" // Add static=true if needed, helps with seeking sometimes
        
        // Optionally add api_key or token if direct streaming needs it (less common)
        // urlString += "&api_key=\(accessToken)"
        
        return URL(string: urlString)
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

} 