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
            // Calculate scale to maintain aspect ratio
            let scale = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            finalImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
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
        
        print("📝 Starting project upload for user: \(userId)")
        
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
                let status: String
            }
            
            let projectData = ProjectData(
                user_id: userId,
                title: title,
                description: description,
                image_path: imageFilePath,
                audio_path: audioFilePath,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date()),
                status: ProjectStatus.active.rawValue
            )
            
            print("📝 Creating project record with data: \(projectData)")
            
            let response = try await client
                .from("projects")
                .insert(projectData)
                .select()
                .single()
                .execute()
            
            print("📝 Raw response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let project = try decoder.decode(Project.self, from: response.data)
            print("✅ Project created successfully: \(project.title), status: \(project.status.rawValue)")
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
    
    @MainActor
    func getProjectsForReview() async throws -> [Project] {
        guard let userId = AuthService.shared.currentUser?.id else {
            print("❌ [Project] No authenticated user found")
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [Project] Current user ID for review: \(userId)")
        print("🔍 [Project] Current user email: \(AuthService.shared.currentUser?.email ?? "unknown")")
        
        do {
            // First, let's check what projects exist in the database
            let allProjectsResponse = try await client
                .from("projects")
                .select()
                .execute()
            
            print("🔍 [Project] All projects in database: \(String(data: allProjectsResponse.data, encoding: .utf8) ?? "nil")")
            
            // Now get projects for review
            let response = try await client
                .from("projects")
                .select()
                .neq("user_id", value: userId)
                .ilike("status", pattern: ProjectStatus.active.rawValue)
                .order("created_at", ascending: false)
                .execute()
            
            print("🔍 [Project] Raw response data for review: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            // Check if the response is empty
            if response.data.isEmpty {
                print("⚠️ [Project] No projects found in the database")
                return []
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let projects = try decoder.decode([Project].self, from: response.data)
                print("🔍 [Project] Found \(projects.count) projects for review")
                
                // Print details of each project found
                for project in projects {
                    print("🔍 [Project] Review project: \(project.title), user_id: \(project.userId), status: \(project.status.rawValue)")
                }
                
                return projects
            } catch {
                print("❌ [Project] Error decoding projects: \(error)")
                print("❌ [Project] Raw data that failed to decode: \(String(data: response.data, encoding: .utf8) ?? "nil")")
                throw error
            }
            
        } catch {
            print("❌ [Project] Error fetching projects for review: \(error)")
            throw error
        }
    }
    
    @MainActor
    func updateProjectStatus(_ projectId: UUID, to status: ProjectStatus) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            _ = try await client
                .from("projects")
                .update(["status": status.rawValue])
                .eq("id", value: projectId)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Project status updated to \(status.rawValue)")
        } catch {
            print("❌ [Project] Error updating project status: \(error)")
            throw error
        }
    }
    
    @MainActor
    func deleteProject(_ projectId: UUID) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // First get the project to delete its files
            let response = try await client
                .from("projects")
                .select()
                .eq("id", value: projectId)
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let project = try decoder.decode(Project.self, from: response.data)
            
            // Delete the project files from storage
            if let imagePath = project.imagePath {
                _ = try? await client.storage
                    .from("project_files")
                    .remove(paths: [imagePath])
            }
            if let audioPath = project.audioPath {
                _ = try? await client.storage
                    .from("project_files")
                    .remove(paths: [audioPath])
            }
            
            // Delete the project record
            _ = try await client
                .from("projects")
                .delete()
                .eq("id", value: projectId)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Project deleted successfully")
        } catch {
            print("❌ [Project] Error deleting project: \(error)")
            throw error
        }
    }
    
    @MainActor
    func getProject(byId projectId: String) async throws -> Project? {
        do {
            let response = try await client
                .from("projects")
                .select()
                .eq("id", value: projectId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let project = try decoder.decode(Project.self, from: response.data)
            return project
        } catch {
            print("❌ [Project] Error fetching project by ID: \(error)")
            throw error
        }
    }
} 