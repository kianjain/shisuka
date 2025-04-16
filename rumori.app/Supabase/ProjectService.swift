import Foundation
import Supabase
import UIKit

class ProjectService: ObservableObject {
    static let shared = ProjectService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func compressImage(_ imageData: Data, maxSizeInMB: Double = 1.0) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        var compression: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compression)
        
        while let data = compressedData, Double(data.count) > maxSizeInMB * 1024 * 1024 && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression)
        }
        
        return compressedData
    }
    
    @MainActor
    func uploadProject(title: String, description: String?, imageData: Data) async throws -> Project {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        // Compress the image before uploading
        guard let compressedImageData = compressImage(imageData) else {
            throw NSError(domain: "ProjectService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Generate a unique filename using timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let filePath = "\(userId)/project_\(timestamp).jpg"
        
        // Upload the image
        do {
            try await client.storage
                .from("project_files")
                .upload(filePath, data: compressedImageData)
            
            // Create project record
            struct ProjectData: Encodable {
                let user_id: UUID
                let title: String
                let description: String?
                let file_path: String
                let created_at: String
                let updated_at: String
            }
            
            let projectData = ProjectData(
                user_id: userId,
                title: title,
                description: description,
                file_path: filePath,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            let response = try await client
                .from("projects")
                .insert(projectData)
                .select()
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let project = try decoder.decode(Project.self, from: response.data)
            return project
            
        } catch {
            print("❌ [Project] Error uploading project: \(error)")
            throw error
        }
    }
    
    @MainActor
    func getProjects() async throws -> [Project] {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let response = try await client
                .from("projects")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let projects = try decoder.decode([Project].self, from: response.data)
            return projects
            
        } catch {
            print("❌ [Project] Error fetching projects: \(error)")
            throw error
        }
    }
} 