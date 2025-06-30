import Foundation
import FirebaseFirestore


struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var senderId: String
    var senderName: String
    var timestamp: Date = Date()
    var read: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case senderId
        case senderName
        case timestamp
        case read
    }
} 
