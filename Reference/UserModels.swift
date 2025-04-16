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

struct Project: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let filePath: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case filePath = "file_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        filePath = try container.decode(String.self, forKey: .filePath)
        
        // Custom date decoding with multiple formatters
        let dateFormatter = ISO8601DateFormatter()
        let dateFormatterWithFractional = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        dateFormatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        // Try both formatters for each date
        if let createdAtDate = dateFormatter.date(from: createdAtString) ?? dateFormatterWithFractional.date(from: createdAtString),
           let updatedAtDate = dateFormatter.date(from: updatedAtString) ?? dateFormatterWithFractional.date(from: updatedAtString) {
            createdAt = createdAtDate
            updatedAt = updatedAtDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match any expected format.")
        }
    }
} 