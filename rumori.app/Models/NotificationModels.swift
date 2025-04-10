import Foundation

struct NotificationItem: Identifiable {
    let id = UUID()
    let userName: String
    let action: String
    let projectName: String
    let projectImage: URL?
    let timeAgo: String
} 