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
        
        // First insert the feedback
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
            
        // Then try to earn coins, but don't throw if it fails
        do {
            try await CoinService.shared.earnCoins(
                amount: 1,
                projectId: projectId,
                description: "Earned for reviewing a project"
            )
            print("✅ [Feedback] Feedback submitted and coins earned successfully")
        } catch let error as PostgrestError {
            print("❌ [Feedback] Failed to earn coin - PostgrestError: \(error.message ?? "Unknown error")")
            print("❌ [Feedback] Error code: \(error.code ?? "No code")")
            print("❌ [Feedback] Error details: \(error.detail ?? "No details")")
            print("❌ [Feedback] Error hint: \(error.hint ?? "No hint")")
        } catch {
            print("❌ [Feedback] Failed to earn coin - Error: \(error)")
        }
    }
    
    func getFeedbackForProject(projectId: UUID) async throws -> [FeedbackResponse] {
        print("🔍 [Feedback] Fetching feedback for project: \(projectId)")
        
        // First, get all feedback for the project
        let feedbackResponse = try await supabase
            .from("feedback")
            .select("id, project_id, author_id, comment, created_at, seen_at")
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
                    seenAt: item.seenAt,
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
                    seenAt: item.seenAt,
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
        let seenAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case projectId = "project_id"
            case authorId = "author_id"
            case comment
            case createdAt = "created_at"
            case seenAt = "seen_at"
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
    
    func markFeedbackAsSeen(feedbackId: UUID) async throws {
        try await supabase
            .from("feedback")
            .update(["seen_at": Date().ISO8601Format()])
            .eq("id", value: feedbackId.uuidString)
            .execute()
    }
    
    func getUnreadFeedbackCount() async throws -> Int {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [Feedback] Fetching unread feedback count for user: \(userId)")
        
        // First get all projects owned by the user
        let projectsResponse = try await supabase
            .from("projects")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            
        let decoder = JSONDecoder()
        struct ProjectId: Codable {
            let id: UUID
        }
        
        let projects = try decoder.decode([ProjectId].self, from: projectsResponse.data)
        print("✅ [Feedback] Found \(projects.count) projects owned by user")
        
        // If no projects, return 0
        if projects.isEmpty {
            return 0
        }
        
        // Get count of unread feedback for all projects
        let feedbackResponse = try await supabase
            .from("feedback")
            .select("id")
            .in("project_id", value: projects.map { $0.id.uuidString })
            .is("seen_at", value: nil)
            .execute()
            
        struct FeedbackId: Codable {
            let id: UUID
        }
        
        let unreadFeedback = try decoder.decode([FeedbackId].self, from: feedbackResponse.data)
        print("✅ [Feedback] Found \(unreadFeedback.count) unread feedback items")
        
        return unreadFeedback.count
    }
}

// Response type that includes the author's username
struct FeedbackResponse: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let authorId: UUID
    let comment: String
    let createdAt: Date
    let seenAt: String?
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
        case seenAt = "seen_at"
        case author
    }
}

private struct ProfileResponse: Codable {
    let username: String
} 