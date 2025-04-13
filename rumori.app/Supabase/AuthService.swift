import Foundation
import Supabase

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let client = SupabaseManager.shared.client
    
    private init() {
        Task {
            await checkAuthState()
        }
    }
    
    @MainActor
    func checkAuthState() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.session
            print("Session found: \(session.user.id)")
            
            // Check if user is confirmed
            if session.user.emailConfirmedAt == nil {
                print("User is not confirmed")
                currentUser = User(
                    id: session.user.id,
                    email: session.user.email ?? "",
                    username: session.user.userMetadata["username"]?.stringValue,
                    createdAt: session.user.createdAt
                )
                isAuthenticated = false
                return
            }
            
            currentUser = User(
                id: session.user.id,
                email: session.user.email ?? "",
                username: session.user.userMetadata["username"]?.stringValue,
                createdAt: session.user.createdAt
            )
            print("Current user set: \(currentUser?.email ?? "no email")")
            
            // If user is confirmed, fetch or create profile
            await fetchUserProfile()
            if currentProfile == nil {
                print("No profile found, creating one")
                await createProfile(for: session.user, username: session.user.userMetadata["username"]?.stringValue ?? "")
            }
            
            isAuthenticated = true
        } catch {
            print("Error checking auth state: \(error)")
            self.error = error
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            print("Sign in successful: \(session.user.id)")
            print("User metadata: \(session.user.userMetadata)")
            
            // Get username from metadata or use email prefix as fallback
            let username = session.user.userMetadata["username"]?.stringValue ?? email.components(separatedBy: "@").first ?? "Anonymous"
            
            currentUser = User(
                id: session.user.id,
                email: session.user.email ?? "",
                username: username,
                createdAt: session.user.createdAt
            )
            print("Current user set: \(currentUser?.email ?? "no email"), username: \(currentUser?.username ?? "no username")")
            await fetchUserProfile()
            isAuthenticated = true
        } catch {
            print("Error signing in: \(error)")
            self.error = error
            throw error
        }
    }
    
    @MainActor
    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First, sign up the user
            let session = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["username": AnyJSON.string(username)]
            )
            print("Sign up successful: \(session.user.id)")
            
            // Check if user is confirmed
            if session.user.emailConfirmedAt == nil {
                print("User needs email verification")
                // Set current user but don't create profile yet
                currentUser = User(
                    id: session.user.id,
                    email: session.user.email ?? "",
                    username: username,
                    createdAt: session.user.createdAt
                )
                // User is not fully authenticated until email is verified
                isAuthenticated = false
                return
            }
            
            // If user is already confirmed, create profile
            print("User is already confirmed, creating profile")
            await createProfile(for: session.user, username: username)
            isAuthenticated = true
            
        } catch {
            print("Error signing up: \(error)")
            self.error = error
            throw error
        }
    }
    
    @MainActor
    private func createProfile(for user: Auth.User, username: String) async {
        do {
            // Create profile data
            struct ProfileData: Encodable {
                let id: UUID
                let username: String
                let created_at: String
                let updated_at: String
            }
            
            let profileData = ProfileData(
                id: user.id,
                username: username,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            print("Creating profile with data: \(profileData)")
            
            let response = try await client
                .from("profiles")
                .insert(profileData)
                .execute()
            
            print("Profile insert response: \(String(describing: response.data))")
            
            // Fetch the created profile
            await fetchUserProfile()
        } catch {
            print("Error creating profile: \(error)")
            print("Error details: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    @MainActor
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
        } catch {
            self.error = error
            throw error
        }
    }
    
    @MainActor
    private func fetchUserProfile() async {
        guard let userId = currentUser?.id else { 
            print("No user ID available for profile fetch")
            return 
        }
        
        do {
            print("Fetching profile for user: \(userId)")
            // First try to find profile by user ID
            let response = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let rawData = String(data: response.data, encoding: .utf8) ?? "nil"
            print("Raw profile data: \(rawData)")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try to decode the response as an array of profiles
            if let profiles = try? decoder.decode([Profile].self, from: response.data) {
                if let profile = profiles.first {
                    print("Found existing profile: \(profile)")
                    print("Profile username: \(profile.username ?? "nil")")
                    currentProfile = profile
                } else {
                    print("No profile found by ID, trying to find by username")
                    // Try to find profile by username
                    if let username = currentUser?.username {
                        let usernameResponse = try await client
                            .from("profiles")
                            .select()
                            .eq("username", value: username)
                            .execute()
                        
                        let usernameRawData = String(data: usernameResponse.data, encoding: .utf8) ?? "nil"
                        print("Raw profile data by username: \(usernameRawData)")
                        
                        if let usernameProfiles = try? decoder.decode([Profile].self, from: usernameResponse.data),
                           let existingProfile = usernameProfiles.first {
                            print("Found existing profile by username: \(existingProfile)")
                            currentProfile = existingProfile
                        } else {
                            print("No profile found by username, creating new one")
                            let session = try await client.auth.session
                            await createProfile(for: session.user, username: username)
                        }
                    }
                }
            } else {
                print("Error decoding profiles array")
                // Try to find profile by username
                if let username = currentUser?.username {
                    let usernameResponse = try await client
                        .from("profiles")
                        .select()
                        .eq("username", value: username)
                        .execute()
                    
                    let usernameRawData = String(data: usernameResponse.data, encoding: .utf8) ?? "nil"
                    print("Raw profile data by username: \(usernameRawData)")
                    
                    if let usernameProfiles = try? decoder.decode([Profile].self, from: usernameResponse.data),
                       let existingProfile = usernameProfiles.first {
                        print("Found existing profile by username: \(existingProfile)")
                        currentProfile = existingProfile
                    } else {
                        print("No profile found by username, creating new one")
                        let session = try await client.auth.session
                        await createProfile(for: session.user, username: username)
                    }
                }
            }
        } catch {
            print("Error fetching profile: \(error)")
            print("Fetch error details: \(error.localizedDescription)")
            // Try to find profile by username
            if let username = currentUser?.username {
                do {
                    let usernameResponse = try await client
                        .from("profiles")
                        .select()
                        .eq("username", value: username)
                        .execute()
                    
                    let usernameRawData = String(data: usernameResponse.data, encoding: .utf8) ?? "nil"
                    print("Raw profile data by username: \(usernameRawData)")
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    if let usernameProfiles = try? decoder.decode([Profile].self, from: usernameResponse.data),
                       let existingProfile = usernameProfiles.first {
                        print("Found existing profile by username: \(existingProfile)")
                        currentProfile = existingProfile
                    } else {
                        print("No profile found by username, creating new one")
                        let session = try await client.auth.session
                        await createProfile(for: session.user, username: username)
                    }
                } catch {
                    print("Error getting profile by username: \(error)")
                }
            }
            self.error = error
        }
    }
}

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let username: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt = "created_at"
    }
}

struct Profile: Identifiable, Codable {
    let id: UUID
    var username: String?
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 