import Foundation
import Combine

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
    // Published properties to hold authentication state
    @Published var isAuthenticated = false
    @Published var serverURL: String? = nil // Store validated server URL
    @Published var accessToken: String? = nil
    @Published var userID: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    // Initializer - No longer takes apiKey directly
    init() {
        // TODO: Load saved credentials from Keychain if available
        // For now, starts unauthenticated
        print("JellyfinService Initialized")
    }

    // Authentication function
    func authenticate(serverURL: String, username: String, password PlainPassword: String) {
        guard let url = URL(string: serverURL) else {
            self.errorMessage = "Invalid Server URL format."
            return
        }
        
        // Construct the authentication URL
        // IMPORTANT: Ensure the base URL doesn't end with a slash if the path starts with one.
        let authURL = url.appendingPathComponent("/Users/AuthenticateByName")

        // Prepare request body
        let requestBody: [String: String] = [
            "Username": username,
            "Pw": PlainPassword // Jellyfin expects 'Pw' for password
        ]
        
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            self.errorMessage = "Failed to encode request body."
            return
        }

        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add necessary Jellyfin headers (X-Emby-Authorization)
        let clientInfo = "AppName=\"Finity\", DeviceName=\"iOS Device\", DeviceId=\"unique-device-id\", Version=\"1.0.0\""
        request.setValue(clientInfo, forHTTPHeaderField: "X-Emby-Authorization")
        request.httpBody = httpBody
        
        isLoading = true
        self.errorMessage = nil

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                print("Auth Response Status Code: \(httpResponse.statusCode)")
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to decode error message if possible, otherwise throw status code error
                    // Often Jellyfin returns plain text errors for auth failures
                     let errorText = String(data: output.data, encoding: .utf8) ?? "Unknown authentication error"
                     print("Auth Error Body: \(errorText)")
                     throw URLError(.init(rawValue: httpResponse.statusCode), userInfo: [NSLocalizedDescriptionKey: errorText])
                }
                return output.data
            }
            .decode(type: AuthenticationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main) // Switch back to main thread for UI updates
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    print("Authentication request finished.")
                    break // Success handled in value receiver
                case .failure(let error):
                    print("Authentication failed: \(error)")
                    if let urlError = error as? URLError, let description = urlError.userInfo[NSLocalizedDescriptionKey] as? String {
                         self?.errorMessage = "Authentication failed: \(description)" 
                    } else {
                         self?.errorMessage = "Authentication failed: \(error.localizedDescription)"
                    }
                   
                    self?.isAuthenticated = false
                    self?.accessToken = nil
                    self?.userID = nil
                    self?.serverURL = nil
                }
            }, receiveValue: { [weak self] authResponse in
                print("Authentication successful for user: \(authResponse.user.name)")
                self?.isAuthenticated = true
                self?.accessToken = authResponse.accessToken
                self?.userID = authResponse.user.id
                self?.serverURL = serverURL // Store the validated URL
                self?.errorMessage = nil
                // TODO: Securely save serverURL, accessToken, userID (e.g., Keychain)
            })
            .store(in: &cancellables)
    }

    func logout() {
        // Clear authentication state
        self.isAuthenticated = false
        self.accessToken = nil
        self.userID = nil
        self.serverURL = nil
        // TODO: Remove credentials from Keychain
        print("User logged out.")
    }

    // Placeholder for fetching data - Will be implemented next
    func fetchLatestMedia(limit: Int = 10) {
        guard isAuthenticated, let serverURL = serverURL, let userID = userID, let accessToken = accessToken else {
            print("Not authenticated or missing info to fetch media.")
            return
        }
        print("Fetching latest media... (Implementation needed)")
        // Example URL: /Users/{UserId}/Items/Latest?Limit={limit}&IncludeItemTypes=Movie,Series&Fields=PrimaryImageAspectRatio,BasicSyncInfo&ImageTypeLimit=1
        // Requires 'Authorization' header: MediaBrowser Token="{accessToken}"
    }
    
     func fetchContinueWatching(limit: Int = 10) {
         guard isAuthenticated, let serverURL = serverURL, let userID = userID, let accessToken = accessToken else {
             print("Not authenticated or missing info to fetch continue watching.")
             return
         }
         print("Fetching continue watching... (Implementation needed)")
         // Example URL: /Users/{UserId}/Items?SortBy=DatePlayed&SortOrder=Descending&IncludeItemTypes=Movie,Episode&Filters=IsResumable&Limit={limit}&Recursive=true&Fields=PrimaryImageAspectRatio,BasicSyncInfo&ImageTypeLimit=1
          // Requires 'Authorization' header: MediaBrowser Token="{accessToken}"
     }
     
     func fetchItemDetails(itemID: String) {
         guard isAuthenticated, let serverURL = serverURL, let userID = userID, let accessToken = accessToken else {
             print("Not authenticated or missing info to fetch item details.")
             return
         }
         print("Fetching details for item \(itemID)... (Implementation needed)")
         // Example URL: /Users/{UserId}/Items/{itemId}
          // Requires 'Authorization' header: MediaBrowser Token="{accessToken}"
     }

} 