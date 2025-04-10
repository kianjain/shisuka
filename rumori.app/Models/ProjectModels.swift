import Foundation
import SwiftUI

/// Represents the current state of a project in the system
enum ProjectStatus: String, Codable, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"
    
    /// Returns a color associated with the status
    var color: Color {
        switch self {
        case .active:
            return .blue
        case .completed:
            return .green
        case .archived:
            return .gray
        }
    }
    
    /// Returns a system image name associated with the status
    var iconName: String {
        switch self {
        case .active:
            return "circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .archived:
            return "archivebox.fill"
        }
    }
    
    /// Returns a localized description of what the status means
    var description: String {
        switch self {
        case .active:
            return "Project is currently being worked on"
        case .completed:
            return "Project has been finished"
        case .archived:
            return "Project is stored for future reference"
        }
    }
}

struct ProjectPreview: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let fileType: String
    let author: String
    let imageUrl: URL?
    let uploadDate: Date
    var status: ProjectStatus
    let feedback: [Feedback]
    let rumorsSpent: Int
    let likes: Int
    let isOwnedByUser: Bool
    let lastStatusUpdate: Date?
    
    var positiveRatings: Int {
        feedback.filter { $0.rating > 0 }.count
    }
    
    var negativeRatings: Int {
        feedback.filter { $0.rating < 0 }.count
    }
    
    /// Returns true if the project can be transitioned to the given status
    func canTransition(to newStatus: ProjectStatus) -> Bool {
        // Only allow status changes for user-owned projects
        guard isOwnedByUser else { return false }
        
        // Define valid status transitions
        switch status {
        case .active:
            return newStatus == .completed || newStatus == .archived
        case .completed:
            return newStatus == .active || newStatus == .archived
        case .archived:
            return newStatus == .active || newStatus == .completed
        }
    }
    
    /// Creates a new project preview with an updated status
    func withUpdatedStatus(_ newStatus: ProjectStatus) -> ProjectPreview {
        var updated = self
        updated.status = newStatus
        return updated
    }
}

struct Feedback: Identifiable, Codable {
    let id: UUID
    let author: String
    let comment: String
    let rating: Int // 1 for like, -1 for dislike
    let date: Date
} 