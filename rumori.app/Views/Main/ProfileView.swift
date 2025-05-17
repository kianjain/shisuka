import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var isEditingUsername = false
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var showingUsernameError = false
    @FocusState private var isUsernameFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    // Stats state
    @State private var projectCount = 0
    @State private var reviewedCount = 0
    @State private var helpfulPercentage = 0
    @State private var isLoadingStats = true
    @State private var statsError: Error?
    
    // Favorites state
    @State private var favoriteProjects: [ProjectPreview] = []
    @State private var isLoadingFavorites = true
    @State private var favoritesError: Error?
    
    private func uploadProfileImage(_ item: PhotosPickerItem) async {
        do {
            // Get the image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("❌ [Profile] Failed to load image data")
                return
            }
            
            // Upload the image using AuthService
            try await auth.uploadProfileImage(data)
            
        } catch {
            print("❌ [Profile] Error uploading profile image: \(error)")
        }
    }
    
    private func updateUsername() async {
        guard !newUsername.isEmpty else { return }
        
        // Store the original username
        let originalUsername = auth.currentProfile?.username ?? "Anonymous"
        
        do {
            let isAvailable = try await auth.checkUsernameAvailability(newUsername)
            if !isAvailable {
                usernameError = "This username is already taken"
                showingUsernameError = true
                newUsername = originalUsername
                return
            }
            
            // If username is available, update it
            try await auth.updateUsername(newUsername)
            isEditingUsername = false
            isUsernameFocused = false
        } catch {
            print("❌ [Profile] Error updating username: \(error)")
            usernameError = error.localizedDescription
            showingUsernameError = true
            newUsername = originalUsername
        }
    }
    
    private func loadUserStats() async {
        isLoadingStats = true
        statsError = nil
        
        do {
            let stats = try await UserStatsService.shared.getUserStats()
            await MainActor.run {
                projectCount = stats.projectCount
                reviewedCount = stats.reviewedCount
                helpfulPercentage = stats.helpfulPercentage
                isLoadingStats = false
            }
        } catch {
            print("❌ [Profile] Error loading user stats: \(error)")
            await MainActor.run {
                statsError = error
                isLoadingStats = false
            }
        }
    }
    
    private func fetchFavoriteProjects() async {
        isLoadingFavorites = true
        favoritesError = nil
        
        do {
            guard let userId = auth.currentUser?.id else {
                throw AuthError.notAuthenticated
            }
            
            // Fetch favorite projects
            let response = try await SupabaseManager.shared.client
                .from("favorites")
                .select("project_id")
                .eq("user_id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            struct Favorite: Codable {
                let projectId: UUID
                
                enum CodingKeys: String, CodingKey {
                    case projectId = "project_id"
                }
            }
            
            let favorites = try decoder.decode([Favorite].self, from: response.data)
            
            // Fetch project details for each favorite
            var projects: [ProjectPreview] = []
            for favorite in favorites {
                let projectResponse = try await SupabaseManager.shared.client
                    .from("projects")
                    .select()
                    .eq("id", value: favorite.projectId)
                    .execute()
                
                let project = try decoder.decode([Project].self, from: projectResponse.data).first!
                
                // Fetch author's profile
                let authorResponse = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("username")
                    .eq("id", value: project.userId)
                    .execute()
                
                struct ProfileResponse: Codable {
                    let username: String
                }
                
                let author = try decoder.decode([ProfileResponse].self, from: authorResponse.data).first!
                
                // Get the image URL if available
                let imageUrl = project.imagePath.map { path in
                    try? SupabaseManager.shared.client.storage
                        .from("project_files")
                        .getPublicURL(path: path)
                } ?? nil
                
                let preview = ProjectPreview(
                    id: project.id,
                    name: project.title,
                    description: project.description ?? "",
                    fileType: project.audioPath != nil ? "Audio" : "Images",
                    author: author.username,
                    imageUrl: imageUrl,
                    uploadDate: project.createdAt,
                    status: project.status,
                    feedback: [],
                    rumorsSpent: 0,
                    likes: 0,
                    isOwnedByUser: project.userId == userId,
                    lastStatusUpdate: project.updatedAt,
                    hasUnreadFeedback: false
                )
                projects.append(preview)
            }
            
            favoriteProjects = projects
        } catch {
            print("❌ [Profile] Error fetching favorites: \(error)")
            favoritesError = error
        }
        
        isLoadingFavorites = false
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 24) {
                        // Profile Image with Picker
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            ProfilePicture(size: 100, action: nil)
                        }
                        .task(id: selectedImage) {
                            if let image = selectedImage {
                                await uploadProfileImage(image)
                            }
                        }
                        
                        // User Info
                        VStack(spacing: 4) {
                            if isEditingUsername {
                                HStack {
                                    TextField("Username", text: $newUsername)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .focused($isUsernameFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            Task {
                                                await updateUsername()
                                            }
                                        }
                                        .onAppear {
                                            isUsernameFocused = true
                                        }
                                }
                            } else {
                                if let username = auth.currentProfile?.username {
                                    Text(username)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                        .onTapGesture {
                                            newUsername = username
                                            isEditingUsername = true
                                        }
                                } else {
                                    Text("Anonymous")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                        .onTapGesture {
                                            newUsername = ""
                                            isEditingUsername = true
                                        }
                                }
                            }
                            
                            Text(auth.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Stats
                        HStack(spacing: 48) {
                            VStack {
                                if isLoadingStats {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("\(projectCount)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                Text("Projects")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                if isLoadingStats {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(helpfulPercentage == -1 ? "No data" : "\(helpfulPercentage)%")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                Text("Helpful")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                if isLoadingStats {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("\(reviewedCount)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                Text("Reviewed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    // Favorites Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Favorites")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if isLoadingFavorites {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .frame(height: 200)
                        } else if let error = favoritesError {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red)
                                Text("Error loading favorites")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") {
                                    Task {
                                        await fetchFavoriteProjects()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if favoriteProjects.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                Text("No favorites yet")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            // Favorites Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(favoriteProjects) { project in
                                    FavoriteProjectItem(project: project, favoriteProjects: $favoriteProjects)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            if isEditingUsername {
                isEditingUsername = false
                isUsernameFocused = false
            }
        }
        .task {
            await loadUserStats()
            await fetchFavoriteProjects()
        }
        .alert("Username Error", isPresented: $showingUsernameError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(usernameError ?? "An unknown error occurred")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ProfileView()
}

struct FavoriteProjectItem: View {
    let project: ProjectPreview
    @Binding var favoriteProjects: [ProjectPreview]
    @State private var isUpdatingFavorite = false
    @State private var isFavorite = true
    @State private var showingProject = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                showingProject = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    ProjectImage(imageUrl: project.imageUrl)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(project.fileType)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Favorite Button
            Button {
                Task {
                    isUpdatingFavorite = true
                    do {
                        isFavorite = try await FavoriteService.shared.toggleFavorite(projectId: project.id)
                        if !isFavorite {
                            if let index = favoriteProjects.firstIndex(where: { $0.id == project.id }) {
                                favoriteProjects.remove(at: index)
                            }
                        }
                    } catch {
                        print("❌ [Profile] Error toggling favorite: \(error)")
                    }
                    isUpdatingFavorite = false
                }
            } label: {
                if isUpdatingFavorite {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(8)
        }
        .sheet(isPresented: $showingProject) {
            NavigationStack {
                ProjectView(projectId: project.id.uuidString)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.black)
        }
    }
}

struct ProjectImage: View {
    let imageUrl: URL?
    
    var body: some View {
        GeometryReader { geometry in
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .overlay(
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
} 
