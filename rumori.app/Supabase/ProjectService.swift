import Foundation
import Supabase
import UIKit

class ProjectService: ObservableObject {
    static let shared = ProjectService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func compressImage(_ imageData: Data, maxSizeInMB: Double = 1.0, targetSize: CGSize? = nil) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        var finalImage = image
        
        // Resize image if target size is specified
        if let targetSize = targetSize {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            finalImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        
        var compression: CGFloat = 0.8
        var compressedData = finalImage.jpegData(compressionQuality: compression)
        
        while let data = compressedData, Double(data.count) > maxSizeInMB * 1024 * 1024 && compression > 0.1 {
            compression -= 0.1
            compressedData = finalImage.jpegData(compressionQuality: compression)
        }
        
        return compressedData
    }
    
    @MainActor
    func uploadProject(title: String, description: String?, imageData: Data?, audioData: Data?) async throws -> Project {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        // Generate unique filenames using timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        var imageFilePath: String?
        var audioFilePath: String?
        
        do {
            // Upload the image if provided
            if let imageData = imageData {
                // Compress the image before uploading
                guard let compressedImageData = compressImage(imageData, targetSize: CGSize(width: 500, height: 500)) else {
                    throw NSError(domain: "ProjectService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
                }
                
                imageFilePath = "\(userId)/project_\(timestamp)_image.jpg"
                try await client.storage
                    .from("project_files")
                    .upload(imageFilePath!, data: compressedImageData)
                print("✅ Image uploaded successfully")
            }
            
            // Upload audio if provided
            if let audioData = audioData {
                audioFilePath = "\(userId)/project_\(timestamp)_audio.mp3"
                try await client.storage
                    .from("project_files")
                    .upload(audioFilePath!, data: audioData)
                print("✅ Audio uploaded successfully")
            }
            
            // Create project record
            struct ProjectData: Encodable {
                let user_id: UUID
                let title: String
                let description: String?
                let image_path: String?
                let audio_path: String?
                let created_at: String
                let updated_at: String
            }
            
            let projectData = ProjectData(
                user_id: userId,
                title: title,
                description: description,
                image_path: imageFilePath,
                audio_path: audioFilePath,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            print("📝 Creating project record with data: \(projectData)")
            
            let response = try await client
                .from("projects")
                .insert(projectData)
                .select()
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let project = try decoder.decode(Project.self, from: response.data)
            print("✅ Project created successfully: \(project.title)")
            return project
            
        } catch {
            print("❌ [Project] Error uploading project: \(error)")
            // If we uploaded files but failed to create the project, try to clean up
            if let imagePath = imageFilePath {
                _ = try? await client.storage
                    .from("project_files")
                    .remove(paths: [imagePath])
            }
            if let audioPath = audioFilePath {
                _ = try? await client.storage
                    .from("project_files")
                    .remove(paths: [audioPath])
            }
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