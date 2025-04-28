import Foundation

struct NotificationItem: Identifiable {
    let id: UUID
    let userName: String
    let action: String
    let projectName: String
    let projectImage: URL?
    let timeAgo: String
    
    init(id: UUID = UUID(), userName: String, action: String, projectName: String, projectImage: URL?, timeAgo: String) {
        self.id = id
        self.userName = userName
        self.action = action
        self.projectName = projectName
        self.projectImage = projectImage
        self.timeAgo = timeAgo
    }
} 