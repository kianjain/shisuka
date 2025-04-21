import Foundation
import Supabase

@MainActor
class FeedbackService {
    static let shared = FeedbackService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    func submitFeedback(projectId: UUID, comment: String) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let feedback = Feedback(
            id: UUID(),
            author: "User",  // This will be updated by the database trigger
            comment: comment,
            date: Date()
        )
        
        try await supabase
            .from("feedback")
            .insert([
                "id": feedback.id.uuidString,
                "project_id": projectId.uuidString,
                "author_id": userId.uuidString,
                "comment": feedback.comment,
                "created_at": feedback.date.ISO8601Format()
            ])
            .execute()
            
        print("✅ [Feedback] Feedback submitted successfully")
    }
    
    func getFeedbackForProject(projectId: UUID) async throws -> [FeedbackResponse] {
        print("🔍 [Feedback] Fetching feedback for project: \(projectId)")
        
        // First, get all feedback for the project
        let feedbackResponse = try await supabase
            .from("feedback")
            .select("id, project_id, author_id, comment, created_at")
            .eq("project_id", value: projectId)
            .order("created_at", ascending: false)
            .execute()
            
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Decode the feedback data
        let feedbackData = try decoder.decode([FeedbackData].self, from: feedbackResponse.data)
        print("✅ [Feedback] Found \(feedbackData.count) feedback items")
        
        // Create an array to store the final responses
        var responses: [FeedbackResponse] = []
        
        // For each feedback item, fetch the author's profile
        for item in feedbackData {
            do {
                let profileResponse = try await supabase
                    .from("profiles")
                    .select("username")
                    .eq("id", value: item.authorId)
                    .single()
                    .execute()
                
                let profile = try decoder.decode(ProfileResponse.self, from: profileResponse.data)
                
                // Create the final response with the profile data
                let response = FeedbackResponse(
                    id: item.id,
                    projectId: item.projectId,
                    authorId: item.authorId,
                    comment: item.comment,
                    createdAt: item.createdAt,
                    author: FeedbackResponse.Profile(username: profile.username)
                )
                
                responses.append(response)
            } catch {
                print("⚠️ [Feedback] Error fetching profile for feedback \(item.id): \(error)")
                // If we can't get the profile, use a default username
                let response = FeedbackResponse(
                    id: item.id,
                    projectId: item.projectId,
                    authorId: item.authorId,
                    comment: item.comment,
                    createdAt: item.createdAt,
                    author: FeedbackResponse.Profile(username: "User")
                )
                responses.append(response)
            }
        }
        
        return responses
    }
    
    // Helper struct for decoding the initial feedback data
    private struct FeedbackData: Codable {
        let id: UUID
        let projectId: UUID
        let authorId: UUID
        let comment: String
        let createdAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case projectId = "project_id"
            case authorId = "author_id"
            case comment
            case createdAt = "created_at"
        }
    }
    
    func getFeedbackByUser(userId: UUID) async throws -> [FeedbackResponse] {
        print("🔍 [Feedback] Fetching feedback for user: \(userId)")
        
        let response = try await supabase
            .from("feedback")
            .select("*, author:profiles(*)")
            .eq("user_id", value: userId)
            .execute()
            
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let feedback = try decoder.decode([FeedbackResponse].self, from: response.data)
        print("✅ [Feedback] Found \(feedback.count) feedback items for user")
        
        return feedback
    }
    
    private func fetchUsername(userId: UUID) async throws -> String {
        print("🔍 [Feedback] Fetching username for: \(userId)")
        let response = try await supabase
            .from("profiles")
            .select("username")
            .eq("id", value: userId)
            .single()
            .execute()
            
        let decoder = JSONDecoder()
        let profile = try decoder.decode(ProfileResponse.self, from: response.data)
        let username = profile.username
        print("✅ [Feedback] Found username: \(username)")
        return username
    }
}

// Response type that includes the author's username
struct FeedbackResponse: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let authorId: UUID
    let comment: String
    let createdAt: Date
    let author: Profile
    
    struct Profile: Codable {
        let username: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case authorId = "author_id"
        case comment
        case createdAt = "created_at"
        case author
    }
}

private struct ProfileResponse: Codable {
    let username: String
} 