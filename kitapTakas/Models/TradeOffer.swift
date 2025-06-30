import Foundation
import FirebaseFirestore


struct TradeOffer: Identifiable, Codable {
    @DocumentID var id: String?
    var offeredBookId: String
    var requestedBookId: String
    var offererId: String
    var receiverId: String
    var status: String // pending, accepted, rejected, completed, shipping
    var message: String?
    var receiverConfirmed: Bool?
    var offererConfirmed: Bool?
    var shippingCode: String?
    var shippingConfirmedByOfferer: Bool?
    var shippingConfirmedByReceiver: Bool?
    var offererRated: Bool?
    var receiverRated: Bool?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case offeredBookId
        case requestedBookId
        case offererId
        case receiverId
        case status
        case message
        case receiverConfirmed
        case offererConfirmed
        case shippingCode
        case shippingConfirmedByOfferer
        case shippingConfirmedByReceiver
        case offererRated
        case receiverRated
        case createdAt
        case updatedAt
    }
} 
