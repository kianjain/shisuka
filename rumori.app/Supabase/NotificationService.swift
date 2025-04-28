import Foundation
import Supabase

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    @MainActor
    func getProjectUploadNotifications() async throws -> [NotificationItem] {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let response = try await client
                .from("projects")
                .select("id, title, image_path, created_at, user_id")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct ProjectNotification: Decodable {
                let id: UUID
                let title: String
                let imagePath: String?
                let createdAt: Date
                let userId: UUID
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case title
                    case imagePath = "image_path"
                    case createdAt = "created_at"
                    case userId = "user_id"
                }
            }
            
            let projects = try decoder.decode([ProjectNotification].self, from: response.data)
            
            return projects.map { project in
                let timeAgo = formatTimeAgo(from: project.createdAt)
                let imageUrl = project.imagePath.map { path in
                    try? SupabaseManager.shared.client.storage
                        .from("project_files")
                        .getPublicURL(path: path)
                } ?? nil
                
                return NotificationItem(
                    userName: "You",
                    action: "uploaded",
                    projectName: project.title,
                    projectImage: imageUrl,
                    timeAgo: timeAgo
                )
            }
        } catch {
            print("❌ [Notification] Error fetching project upload notifications: \(error)")
            throw error
        }
    }
    
    @MainActor
    func getFeedbackNotifications() async throws -> [NotificationItem] {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // First get all projects owned by the user
            let projectsResponse = try await client
                .from("projects")
                .select("id, title")
                .eq("user_id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct Project: Decodable {
                let id: UUID
                let title: String
            }
            
            let projects = try decoder.decode([Project].self, from: projectsResponse.data)
            let projectIds = projects.map { $0.id }
            
            // Then get all feedback for these projects
            let feedbackResponse = try await client
                .from("feedback")
                .select("id, project_id, author_id, comment, created_at")
                .in("project_id", values: projectIds)
                .order("created_at", ascending: false)
                .execute()
            
            struct Feedback: Decodable {
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
            
            let feedbacks = try decoder.decode([Feedback].self, from: feedbackResponse.data)
            
            // Create a dictionary of project titles for quick lookup
            let projectTitles = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.title) })
            
            // Fetch author usernames and profile pictures
            var notifications: [NotificationItem] = []
            for feedback in feedbacks {
                if let projectTitle = projectTitles[feedback.projectId] {
                    // Fetch author's profile
                    let authorResponse = try await client
                        .from("profiles")
                        .select("username, avatar_url")
                        .eq("id", value: feedback.authorId)
                        .single()
                        .execute()
                    
                    struct Profile: Decodable {
                        let username: String
                        let avatarUrl: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case username
                            case avatarUrl = "avatar_url"
                        }
                    }
                    
                    let profile = try decoder.decode(Profile.self, from: authorResponse.data)
                    let timeAgo = formatTimeAgo(from: feedback.createdAt)
                    
                    let notification = NotificationItem(
                        userName: profile.username,
                        action: "just reviewed",
                        projectName: projectTitle,
                        projectImage: profile.avatarUrl.map { URL(string: $0) } ?? nil,
                        timeAgo: timeAgo
                    )
                    notifications.append(notification)
                }
            }
            
            return notifications
        } catch {
            print("❌ [Notification] Error fetching feedback notifications: \(error)")
            throw error
        }
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
} 