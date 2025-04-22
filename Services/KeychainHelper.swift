import Foundation
import Security

class KeychainHelper {
    
    static let standard = KeychainHelper()
    private init() {}
    
    // MARK: - Constants
    
    private let service = "com.finity.app"
    
    // MARK: - Public Methods
    
    func save(_ data: Data, for key: String) {
        // Create query
        let query = [
            kSecValueData: data,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        // Delete existing entry and add new one
        SecItemDelete(query)
        SecItemAdd(query, nil)
    }
    
    func read(for key: String) -> Data? {
        // Create query
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        return status == errSecSuccess ? result as? Data : nil
    }
    
    func delete(for key: String) {
        // Create query
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        // Delete item
        SecItemDelete(query)
    }
    
    // Helper methods for common data types
    
    func save(_ string: String, for key: String) {
        if let data = string.data(using: .utf8) {
            save(data, for: key)
        }
    }
    
    func readString(for key: String) -> String? {
        guard let data = read(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
} 