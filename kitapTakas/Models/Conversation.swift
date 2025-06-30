import Foundation
import FirebaseFirestore


struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var participantNames: [String: String]
    var participantPhotos: [String: String]?
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var unreadCount: [String: Int]?
    var bookId: String?
    var bookTitle: String?
    var bookImageURL: String?
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case participantNames
        case participantPhotos
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderId
        case unreadCount
        case bookId
        case bookTitle
        case bookImageURL
        case createdAt
    }
} 
