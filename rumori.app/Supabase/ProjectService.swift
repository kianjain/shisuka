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
        } else {
            // For project images, resize to max 1000px width while maintaining aspect ratio
            let maxWidth: CGFloat = 1000
            if image.size.width > maxWidth {
                let scale = maxWidth / image.size.width
                let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
                
                let renderer = UIGraphicsImageRenderer(size: newSize)
                finalImage = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
            }
        }
        
        var compression: CGFloat = 0.8
        var compressedData = finalImage.jpegData(compressionQuality: compression)
        
        while let data = compressedData, Double(data.count) > maxSizeInMB * 1024 * 1024 && compression > 0.1 {
            compression -= 0.1
            compressedData = finalImage.jpegData(compressionQuality: compression)
        }
        
        if let finalData = compressedData {
            print("✅ [Project] Image resized to \(Int(finalImage.size.width))x\(Int(finalImage.size.height)) and compressed to \(finalData.count) bytes")
        }
        
        return compressedData
    }
    
    private func compressAudio(_ audioData: Data, maxSizeInMB: Double = 5.0) -> Data? {
        let fileSizeInMB = Double(audioData.count) / (1024 * 1024)
        if fileSizeInMB <= maxSizeInMB {
            return audioData
        }
        
        // If the file is too large, we'll need to compress it
        // For now, we'll just return nil to indicate the file is too large
        // In a real implementation, you would use an audio compression library
        return nil
    }
    
    @MainActor
    func createProject(title: String, description: String?, imageData: Data?, audioData: Data?, type: UploadType = .photo) async throws -> Project {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        var imageFilePath: String?
        var audioFilePath: String?
        
        do {
            // Upload the image if provided and not an idea
            if type != .idea, let imageData = imageData {
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
            
            // Upload audio if provided and not an idea
            if type != .idea, let audioData = audioData {
                // Compress the audio before uploading
                guard let compressedAudioData = compressAudio(audioData) else {
                    throw NSError(domain: "ProjectService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio file is too large. Maximum size is 5MB."])
                }
                
                audioFilePath = "\(userId)/project_\(timestamp)_audio.m4a"
                try await client.storage
                    .from("project_files")
                    .upload(audioFilePath!, data: compressedAudioData)
                print("✅ Audio uploaded successfully")
            }
            
            // Create project record
            struct ProjectData: Encodable {
                let user_id: UUID
                let title: String
                let description: String?
                let image_path: String
                let audio_path: String?
                let created_at: String
                let updated_at: String
                let status: String
                let file_type: String
            }
            
            let now = ISO8601DateFormatter().string(from: Date())
            let projectData = ProjectData(
                user_id: userId,
                title: title,
                description: description,
                image_path: imageFilePath ?? "",
                audio_path: audioFilePath,
                created_at: now,
                updated_at: now,
                status: "active",
                file_type: type == .idea ? "idea" : (audioFilePath != nil ? "audio" : "photo")
            )
            
            let response = try await client.database
                .from("projects")
                .insert(projectData)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let projects = try? decoder.decode([Project].self, from: response.data),
               let project = projects.first {
                return project
            }
            
            throw NSError(domain: "ProjectService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode project response"])
        } catch {
            print("❌ [Project] Error creating project: \(error)")
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
            // First get all projects that the user has reviewed
            let reviewedProjectsResponse = try await client
                .from("feedback")
                .select("project_id")
                .eq("author_id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct ReviewedProject: Codable {
                let project_id: UUID
            }
            
            let reviewedProjects = try decoder.decode([ReviewedProject].self, from: reviewedProjectsResponse.data)
            let reviewedProjectIds = Set(reviewedProjects.map { $0.project_id })
            
            // Get all active projects not owned by the user
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
                print("ℹ️ [Project] No projects available for review")
                return []
            }
            
            do {
                let allProjects = try decoder.decode([Project].self, from: response.data)
                
                // Filter out reviewed projects
                let projects = allProjects.filter { !reviewedProjectIds.contains($0.id) }
                
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
            
        } catch let error as PostgrestError {
            // Handle PostgrestError specifically
            if error.code == "PGRST100" {
                print("ℹ️ [Project] No projects available for review")
                return []
            }
            print("❌ [Project] Error fetching projects for review: \(error)")
            throw error
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
            
            // Delete all feedback for this project
            _ = try await client
                .from("feedback")
                .delete()
                .eq("project_id", value: projectId)
                .execute()
            
            // Delete the project record
            _ = try await client
                .from("projects")
                .delete()
                .eq("id", value: projectId)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Project and its feedback deleted successfully")
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
    
    @MainActor
    func updateProjectTitle(id: UUID, title: String) async throws {
        let response = try await client
            .from("projects")
            .update([
                "title": title,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id)
            .execute()
        
        if response.status != 200 {
            throw NSError(domain: "ProjectService", code: response.status, userInfo: [
                NSLocalizedDescriptionKey: "Failed to update project title"
            ])
        }
    }
    
    @MainActor
    func updateProjectDescription(id: UUID, description: String) async throws {
        let response = try await client
            .from("projects")
            .update([
                "description": description,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id)
            .execute()
        
        if response.status != 200 {
            throw NSError(domain: "ProjectService", code: response.status, userInfo: [
                NSLocalizedDescriptionKey: "Failed to update project description"
            ])
        }
    }
    
    @MainActor
    func getUserProjects(userId: UUID) async throws -> [Project] {
        do {
            let response = try await client
                .from("projects")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            print("🔍 [Project] Raw response data for user projects: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            // Check if the response is empty
            if response.data.isEmpty {
                print("ℹ️ [Project] No projects found for user")
                return []
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let projects = try decoder.decode([Project].self, from: response.data)
                print("🔍 [Project] Found \(projects.count) projects for user")
                
                // Print details of each project found
                for project in projects {
                    print("🔍 [Project] User project: \(project.title), status: \(project.status.rawValue)")
                }
                
                return projects
            } catch {
                print("❌ [Project] Error decoding projects: \(error)")
                print("❌ [Project] Raw data that failed to decode: \(String(data: response.data, encoding: .utf8) ?? "nil")")
                throw error
            }
            
        } catch let error as PostgrestError {
            // Handle PostgrestError specifically
            if error.code == "PGRST100" {
                print("ℹ️ [Project] No projects found for user")
                return []
            }
            print("❌ [Project] Error fetching user projects: \(error)")
            throw error
        } catch {
            print("❌ [Project] Error fetching user projects: \(error)")
            throw error
        }
    }
} 