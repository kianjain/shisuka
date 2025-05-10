import Foundation
import Supabase

class FavoriteService {
    static let shared = FavoriteService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func toggleFavorite(projectId: UUID) async throws -> Bool {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [FavoriteService] Checking favorite status for project: \(projectId)")
        
        // Check if the project is already favorited
        let response = try await client
            .from("favorites")
            .select()
            .eq("user_id", value: userId)
            .eq("project_id", value: projectId)
            .execute()
        
        let decoder = JSONDecoder()
        
        struct Favorite: Codable {
            let id: UUID
            let userId: UUID
            let projectId: UUID
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case projectId = "project_id"
            }
        }
        
        // First try to decode the response
        let favorites = try decoder.decode([Favorite].self, from: response.data)
        
        if !favorites.isEmpty {
            print("🗑️ [FavoriteService] Removing favorite for project: \(projectId)")
            // If favorited, delete the favorite
            try await client
                .from("favorites")
                .delete()
                .eq("user_id", value: userId)
                .eq("project_id", value: projectId)
                .execute()
            print("✅ [FavoriteService] Successfully removed favorite")
            return false
        } else {
            print("➕ [FavoriteService] Adding favorite for project: \(projectId)")
            // If not favorited, create a new favorite
            try await client
                .from("favorites")
                .insert([
                    "user_id": userId,
                    "project_id": projectId
                ])
                .execute()
            print("✅ [FavoriteService] Successfully added favorite")
            return true
        }
    }
    
    func isProjectFavorited(projectId: UUID) async throws -> Bool {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let response = try await client
            .from("favorites")
            .select()
            .eq("user_id", value: userId)
            .eq("project_id", value: projectId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct Favorite: Codable {
            let id: UUID
        }
        
        if let favorites = try? decoder.decode([Favorite].self, from: response.data),
           !favorites.isEmpty {
            return true
        }
        return false
    }
} 