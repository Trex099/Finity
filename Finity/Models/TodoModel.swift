import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombine_Community

struct Todo: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var completed: Bool
    var createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case completed
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 