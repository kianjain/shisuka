import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let username: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt = "created_at"
    }
}

struct Profile: Identifiable, Codable {
    let id: UUID
    var username: String?
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 