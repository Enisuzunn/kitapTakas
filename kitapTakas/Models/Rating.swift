import Foundation
import FirebaseFirestore


struct Rating: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var targetUserId: String
    var ratedUserId: String?
    var rating: Int
    var comment: String
    var bookId: String?
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case targetUserId
        case ratedUserId
        case rating
        case comment
        case bookId
        case createdAt
    }
} 
