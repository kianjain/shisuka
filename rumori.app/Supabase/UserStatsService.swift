import Foundation
import Supabase

class UserStatsService {
    static let shared = UserStatsService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func getUserStats() async throws -> (projectCount: Int, reviewedCount: Int, helpfulPercentage: Int) {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [UserStats] Fetching stats for user: \(userId)")
        
        // Get project count
        let projectsResponse = try await client
            .from("projects")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        struct ProjectId: Codable {
            let id: UUID
        }
        
        let projects = try decoder.decode([ProjectId].self, from: projectsResponse.data)
        let projectCount = projects.count
        print("✅ [UserStats] Found \(projectCount) projects")
        
        // Get reviewed count (feedback given by user)
        let reviewsResponse = try await client
            .from("feedback")
            .select("id")
            .eq("author_id", value: userId)
            .execute()
        
        struct ReviewId: Codable {
            let id: UUID
        }
        
        let reviews = try decoder.decode([ReviewId].self, from: reviewsResponse.data)
        let reviewedCount = reviews.count
        print("✅ [UserStats] Found \(reviewedCount) reviews given")
        
        // Get all feedback given by the user with their helpful ratings
        let feedbackResponse = try await client
            .from("feedback")
            .select("helpful_rating")
            .eq("author_id", value: userId)
            .not("helpful_rating", operator: .is, value: "null")
            .execute()
        
        struct FeedbackRating: Codable {
            let helpfulRating: Int
            
            enum CodingKeys: String, CodingKey {
                case helpfulRating = "helpful_rating"
            }
        }
        
        let feedbackRatings = try decoder.decode([FeedbackRating].self, from: feedbackResponse.data)
        
        // Calculate helpful percentage
        let totalRatedFeedback = feedbackRatings.count
        let helpfulFeedback = feedbackRatings.filter { $0.helpfulRating == 1 }.count
        
        let helpfulPercentage = totalRatedFeedback > 0 ? Int((Double(helpfulFeedback) / Double(totalRatedFeedback)) * 100) : -1
        print("✅ [UserStats] Calculated helpful percentage: \(helpfulPercentage == -1 ? "No data" : "\(helpfulPercentage)% (\(helpfulFeedback)/\(totalRatedFeedback))")")
        
        return (projectCount, reviewedCount, helpfulPercentage)
    }
} 