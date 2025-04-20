import Foundation
import Combine
import UIKit
import FirebaseFirestore // Keep Firestore

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

// Define Codable struct for Firestore
struct UserCredentials: Codable {
    let serverURL: String
    let userID: String
    let accessToken: String
}

class JellyfinService: ObservableObject {
    // Authentication State
    @Published var isAuthenticated = false
    @Published var serverURL: String? = nil
    @Published var accessToken: String? = nil
    @Published var userID: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoadingAuth = false // Renamed for clarity
    @Published var isCheckingAuth = true // New state for initial credential check
    
    // Fetched Data State
    @Published var latestItems: [MediaItem] = []
    @Published var continueWatchingItems: [MediaItem] = []
    @Published var currentItemDetails: MediaItem? = nil
    @Published var isLoadingData = false // For general data loading
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore() // Firestore database reference
    private var firestoreListener: ListenerRegistration? // For potential real-time updates if needed later

    // Initializer - Load credentials on init
    init() {
        print("JellyfinService Initializing - Loading credentials...")
        loadCredentialsFromFirestore()
        // isCheckingAuth will be set to false within loadCredentialsFromFirestore
    }

    // --- Firestore Credential Management ---

    private func saveCredentialsToFirestore() {
        guard let serverURL = self.serverURL, let userID = self.userID, let accessToken = self.accessToken else {
            print("Error: Missing credentials to save.")
            return
        }
        
        // Create a dictionary instead of using Codable
        let credentialsData: [String: Any] = [
            "serverURL": serverURL,
            "userID": userID,
            "accessToken": accessToken
        ]
        
        // Use setData with dictionary instead of setData(from:)
        db.collection("userSessions").document("currentUserSession").setData(credentialsData) { error in
            if let error = error {
                print("Error saving credentials to Firestore: \(error.localizedDescription)")
                // Optionally set an error message for the user
            } else {
                print("Credentials successfully saved to Firestore.")
            }
        }
    }

    private func loadCredentialsFromFirestore() {
        // Start checking auth state
        DispatchQueue.main.async {
             self.isCheckingAuth = true
        }
        
        db.collection("userSessions").document("currentUserSession").getDocument { (document, error) in
            DispatchQueue.main.async { // Ensure UI updates happen on main thread
                self.isCheckingAuth = false // Finished checking
                if let error = error {
                    print("Error loading credentials from Firestore: \(error.localizedDescription)")
                    // Don't treat loading error as critical, just means no saved session
                    self.clearAuthenticationLocally() // Ensure clean state
                    return
                }

                if let document = document, document.exists, let data = document.data() {
                    // Extract values from dictionary instead of using Codable
                    if let serverURL = data["serverURL"] as? String,
                       let userID = data["userID"] as? String,
                       let accessToken = data["accessToken"] as? String {
                        
                        print("Credentials loaded from Firestore for user: \(userID)")
                        self.serverURL = serverURL
                        self.userID = userID
                        self.accessToken = accessToken
                        self.isAuthenticated = true
                        self.errorMessage = nil
                        
                        // Optionally, trigger data fetches now that we are authenticated
                        // self.fetchInitialData() // You might create a helper function for this
                    } else {
                        print("Invalid credentials data format in Firestore document.")
                        self.clearAuthenticationLocally()
                    }
                } else {
                    print("Credentials document does not exist in Firestore.")
                    self.clearAuthenticationLocally()
                }
            }
        }
    }

    private func clearCredentialsFromFirestore(completion: (() -> Void)? = nil) {
        db.collection("userSessions").document("currentUserSession").delete() { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error removing credentials from Firestore: \(error.localizedDescription)")
                    // Handle error if needed, maybe show message?
                } else {
                    print("Credentials successfully removed from Firestore.")
                }
                 completion?() // Call completion handler regardless of error
            }
        }
    }
    
    // Separate function to clear local state without touching Firestore
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
                self?.isLoadingAuth = false // Stop loading indicator
                if case .failure(let error) = completion {
                    self?.handleAPIError(error, context: "Authentication")
                    self?.clearAuthenticationLocally() // Clear local state on failure
                    // Don't clear Firestore here, keep the failed attempt potentially
                }
            }, receiveValue: { [weak self] authResponse in
                print("Authentication successful for user: \(authResponse.user.name)")
                self?.isAuthenticated = true
                self?.accessToken = authResponse.accessToken
                self?.userID = authResponse.user.id
                self?.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) // Store cleaned URL
                self?.errorMessage = nil
                
                // Save credentials on successful authentication
                self?.saveCredentialsToFirestore() 
                
                // Optionally trigger initial data fetch after login
                // self?.fetchInitialData()
            })
            .store(in: &cancellables)
    }

    func logout() {
        // 1. Clear credentials from Firestore
        clearCredentialsFromFirestore { [weak self] in
            // 2. Clear local authentication state AFTER Firestore clear completes (or fails)
            DispatchQueue.main.async {
                 self?.clearAuthenticationLocally()
                 print("User logged out and local/Firestore state cleared.")
            }
        }
    }
    
    // MARK: - Data Fetching
    
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