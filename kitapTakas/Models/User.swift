import Foundation
import FirebaseFirestore


struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var profileImageUrl: String?
    var bio: String?
    var location: String?
    var bookCount: Int = 0
    var averageRating: Double = 0.0
    var totalRatings: Int = 0
    var completedTrades: Int = 0
    var notifications: Bool = true
    var publicProfile: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case profileImageUrl
        case bio
        case location
        case bookCount
        case averageRating
        case totalRatings
        case completedTrades
        case notifications
        case publicProfile
        case createdAt
        case updatedAt
    }
} 
