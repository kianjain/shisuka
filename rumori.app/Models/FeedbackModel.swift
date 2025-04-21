import Foundation

struct FeedbackInput: Codable {
    let projectId: UUID
    let authorId: UUID
    let comment: String
    let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case authorId = "author_id"
        case comment
        case rating
    }
} 