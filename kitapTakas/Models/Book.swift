import Foundation
import FirebaseFirestore


struct Book: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var description: String
    var price: Double?
    var bookValue: Int
    var condition: String
    var category: String
    var isForSale: Bool
    var isForTrade: Bool
    var imageURLs: [String]
    var ownerId: String
    var ownerDisplayName: String
    var location: String?
    var status: String = "available" // available, reserved, sold
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case description
        case price
        case bookValue
        case condition
        case category
        case isForSale
        case isForTrade
        case imageURLs
        case ownerId
        case ownerDisplayName
        case location
        case status
        case createdAt
        case updatedAt
    }
} 
