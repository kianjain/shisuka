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
        
        // TODO: Implement actual helpful percentage calculation
        // For now, return a fixed value of 85%
        let helpfulPercentage = 85
        print("✅ [UserStats] Using placeholder helpful percentage: \(helpfulPercentage)%")
        
        return (projectCount, reviewedCount, helpfulPercentage)
    }
} 