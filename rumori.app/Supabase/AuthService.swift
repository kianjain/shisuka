import Foundation
import Supabase
import UIKit

enum AuthError: Error {
    case notAuthenticated
    case invalidCredentials
    case emailNotVerified
    case profileNotFound
    case emailAlreadyExists
    case notAuthorized
}

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let client = SupabaseManager.shared.client
    
    private init() {
        Task { @MainActor in
            await checkAuthState()
        }
    }
    
    @MainActor
    func checkAuthState() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.session
            print("🔍 [Auth] Session found - User ID: \(session.user.id)")
            print("🔍 [Auth] User metadata: \(session.user.userMetadata)")
            print("🔍 [Auth] Username from metadata: \(session.user.userMetadata["username"]?.stringValue ?? "nil")")
            
            // Check if user is confirmed
            if session.user.emailConfirmedAt == nil {
                print("⚠️ [Auth] User is not confirmed")
                currentUser = User(
                    id: session.user.id,
                    email: session.user.email ?? "",
                    username: session.user.userMetadata["username"]?.stringValue,
                    createdAt: session.user.createdAt
                )
                print("🔍 [Auth] Set unconfirmed user - Username: \(currentUser?.username ?? "nil")")
                isAuthenticated = false
                return
            }
            
            currentUser = User(
                id: session.user.id,
                email: session.user.email ?? "",
                username: session.user.userMetadata["username"]?.stringValue,
                createdAt: session.user.createdAt
            )
            print("✅ [Auth] Current user set - Email: \(currentUser?.email ?? "no email"), Username: \(currentUser?.username ?? "no username")")
            
            // If user is confirmed, fetch or create profile
            await fetchUserProfile()
            if currentProfile == nil {
                print("⚠️ [Auth] No profile found, creating one")
                let username = session.user.userMetadata["username"]?.stringValue ?? "Anonymous"
                print("🔍 [Auth] Creating profile with username: \(username)")
                await createProfile(for: session.user, username: username)
            } else {
                print("✅ [Auth] Profile found - Username: \(currentProfile?.username ?? "nil")")
            }
            
            isAuthenticated = true
        } catch {
            print("❌ [Auth] Error checking auth state: \(error)")
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
            
        } catch let error as AuthError {
            if error.localizedDescription.contains("User already registered") {
                throw AuthError.emailAlreadyExists
            }
            throw error
        } catch {
            print("Error signing up: \(error)")
            self.error = error
            throw error
        }
    }
    
    @MainActor
    private func createProfile(for user: Auth.User, username: String) async {
        do {
            print("🔍 [Profile] Creating profile for user: \(user.id)")
            print("🔍 [Profile] Username to be set: \(username)")
            
            // Create profile data
            struct ProfileData: Encodable {
                let id: UUID
                let username: String
                let created_at: String
                let updated_at: String
            }
            
            let profileData = ProfileData(
                id: user.id,
                username: username.isEmpty ? "Anonymous" : username,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            print("🔍 [Profile] Profile data to be inserted: \(profileData)")
            
            let response = try await client
                .from("profiles")
                .insert(profileData)
                .execute()
            
            print("✅ [Profile] Profile insert response: \(String(describing: response.data))")
            
            // Fetch the created profile
            await fetchUserProfile()
        } catch {
            print("❌ [Profile] Error creating profile: \(error)")
            print("❌ [Profile] Error details: \(error.localizedDescription)")
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
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "https://kianjain.github.io/shisuka/profile/update")!
        )
    }
    
    @MainActor
    private func fetchUserProfile() async {
        guard let userId = currentUser?.id else { 
            print("❌ [Profile] No user ID available for profile fetch")
            return 
        }
        
        print("🔍 [Profile] Fetching profile for user: \(userId)")
        print("🔍 [Profile] Current username before fetch: \(currentUser?.username ?? "nil")")
        
        do {
            // First try to find profile by user ID
            let response = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let rawData = String(data: response.data, encoding: .utf8) ?? "nil"
            print("🔍 [Profile] Raw profile data: \(rawData)")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let profiles = try decoder.decode([Profile].self, from: response.data)
                if let profile = profiles.first {
                    print("✅ [Profile] Found existing profile - Username: \(profile.username)")
                    currentProfile = profile
                    return
                }
            } catch {
                print("❌ [Profile] Error decoding profile: \(error)")
            }
            
            // If we get here, we need to create a new profile
            print("⚠️ [Profile] No profile found, creating one")
            let session = try await client.auth.session
            let username = session.user.userMetadata["username"]?.stringValue ?? "Anonymous"
            print("🔍 [Profile] Creating profile with username: \(username)")
            await createProfile(for: session.user, username: username)
            
        } catch {
            print("❌ [Profile] Error fetching profile: \(error)")
            print("❌ [Profile] Fetch error details: \(error.localizedDescription)")
            
            // If it's a duplicate key error, try to fetch the existing profile again
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "23505" {
                print("⚠️ [Profile] Profile already exists, fetching it again")
                do {
                    let response = try await client
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .execute()
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let profiles = try decoder.decode([Profile].self, from: response.data)
                    if let profile = profiles.first {
                        print("✅ [Profile] Successfully fetched existing profile - Username: \(profile.username)")
                        currentProfile = profile
                        return
                    }
                } catch {
                    print("❌ [Profile] Error fetching existing profile: \(error)")
                }
            }
            
            self.error = error
        }
    }
    
    @MainActor
    func refreshProfile() async {
        await fetchUserProfile()
    }
    
    @MainActor
    func uploadProfileImage(_ data: Data) async throws {
        guard let userId = currentUser?.id else {
            print("❌ [Profile] No user ID found")
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [Profile] Starting image upload for user: \(userId)")
        print("🔍 [Profile] Original image size: \(data.count) bytes")
        
        // Compress the image if it's too large
        let maxSize = 200 * 1024 // 200KB
        let compressedData = data.count > maxSize ? compressImage(data) : data
        print("🔍 [Profile] Compressed image size: \(compressedData.count) bytes")
        
        // Generate a unique filename using timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let filePath = "\(userId)/avatar_\(timestamp).jpg"
        
        // Delete old avatar if it exists
        if let oldAvatarUrl = currentProfile?.avatarUrl,
           let oldPath = oldAvatarUrl.components(separatedBy: "/").last {
            do {
                try await client.storage
                    .from("avatars")
                    .remove(paths: ["\(userId)/\(oldPath)"])
                print("✅ [Profile] Successfully deleted old avatar")
            } catch {
                print("⚠️ [Profile] Could not delete old avatar: \(error)")
                // Continue with upload even if deletion fails
            }
        }
        
        // Upload the new image
        let _ = try await client.storage
            .from("avatars")
            .upload(filePath, data: compressedData)
        
        // Get the public URL
        let url = try await client.storage
            .from("avatars")
            .getPublicURL(path: filePath)
        
        // Update the profile with the new avatar URL
        try await updateProfile(avatarUrl: url.absoluteString)
        
        print("✅ [Profile] Successfully uploaded and updated profile image")
    }
    
    private func compressImage(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else {
            print("❌ [Profile] Failed to create image from data")
            return data
        }
        
        // Resize image to 200x200 while maintaining aspect ratio
        let targetSize = CGSize(width: 200, height: 200)
        let scale = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let resizedImage = resizedImage,
              let compressedData = resizedImage.jpegData(compressionQuality: 0.5) else {
            print("❌ [Profile] Failed to compress image")
            return data
        }
        
        print("✅ [Profile] Image resized to \(Int(newSize.width))x\(Int(newSize.height)) and compressed to \(compressedData.count) bytes")
        return compressedData
    }
    
    @MainActor
    private func updateProfile(avatarUrl: String) async throws {
        guard let userId = currentUser?.id else {
            print("❌ [Profile] No user ID found for profile update")
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [Profile] Updating profile with new avatar URL: \(avatarUrl)")
        
        let response = try await client
            .from("profiles")
            .update([
                "avatar_url": avatarUrl,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ] as [String: String])
            .eq("id", value: userId)
            .execute()
        
        print("✅ [Profile] Profile update response: \(String(describing: response.data))")
        
        // Refresh the profile to get the updated data
        await refreshProfile()
    }
    
    @MainActor
    func updateUsername(_ newUsername: String) async throws {
        guard let userId = currentUser?.id else {
            print("❌ [Profile] No user ID found for username update")
            throw AuthError.notAuthenticated
        }
        
        print("🔍 [Profile] Updating username to: \(newUsername)")
        
        let response = try await client
            .from("profiles")
            .update([
                "username": newUsername,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ] as [String: String])
            .eq("id", value: userId)
            .execute()
        
        print("✅ [Profile] Username update response: \(String(describing: response.data))")
        
        // Refresh the profile to get the updated data
        await refreshProfile()
    }
    
    @MainActor
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        do {
            let response = try await client
                .from("profiles")
                .select("username")
                .eq("username", value: username)
                .execute()
            
            // The response will be an array of profiles with just the username field
            let decoder = JSONDecoder()
            struct UsernameResponse: Codable {
                let username: String
            }
            let profiles = try decoder.decode([UsernameResponse].self, from: response.data)
            return profiles.isEmpty
        } catch {
            print("Error checking username availability: \(error)")
            throw error
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
    var username: String
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        
        // Custom date decoding with multiple formatters
        let dateFormatter = ISO8601DateFormatter()
        let dateFormatterWithFractional = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        dateFormatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        // Try both formatters for each date
        if let createdAtDate = dateFormatter.date(from: createdAtString) ?? dateFormatterWithFractional.date(from: createdAtString),
           let updatedAtDate = dateFormatter.date(from: updatedAtString) ?? dateFormatterWithFractional.date(from: updatedAtString) {
            createdAt = createdAtDate
            updatedAt = updatedAtDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match any expected format.")
        }
    }
} 