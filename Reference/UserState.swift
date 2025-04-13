import SwiftUI

class UserState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isLoading: Bool = false
    
    static let shared = UserState()
    
    private init() {
        checkAuthState()
    }
    
    func checkAuthState() {
        isLoading = true
        // For now, we'll just set a default state
        isAuthenticated = false
        currentUser = nil
        currentProfile = nil
        isLoading = false
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        currentProfile = nil
    }
}

struct User: Identifiable {
    let id: UUID
    var email: String
    var name: String?
    var avatarUrl: String?
    var createdAt: Date
    
    static let preview = User(
        id: UUID(),
        email: "preview@example.com",
        name: "Preview User",
        avatarUrl: nil,
        createdAt: Date()
    )
} 