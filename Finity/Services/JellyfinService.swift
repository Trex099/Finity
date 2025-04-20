import Foundation
import Combine

class JellyfinService: ObservableObject {
    private let baseURL: String
    private let apiKey: String
    
    // Will be implemented in the future with actual API integration
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // Methods for future implementation
    func connectToServer() {
        // Will establish connection to Jellyfin server
        print("Connection to \(baseURL) will be implemented")
    }
    
    func authenticate() {
        // Will handle authentication
        print("Authentication using API key will be implemented")
    }
} 