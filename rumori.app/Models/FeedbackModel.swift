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