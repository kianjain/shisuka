import Foundation

struct FeedbackInput: Codable {
    let projectId: UUID
    let authorId: UUID
    let comment: String
    let rating: Int
    let seenAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case authorId = "author_id"
        case comment
        case rating
        case seenAt = "seen_at"
    }
}

struct FeedbackResponse: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let authorId: UUID
    let comment: String
    let createdAt: Date
    let seenAt: String?
    let author: Profile
    let helpfulRating: Int?
    
    struct Profile: Codable {
        let username: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case authorId = "author_id"
        case comment
        case createdAt = "created_at"
        case seenAt = "seen_at"
        case author
        case helpfulRating = "helpful_rating"
    }
} 