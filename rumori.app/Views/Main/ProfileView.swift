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
    @FocusState private var isUsernameFocused: Bool
    
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
        do {
            try await auth.updateUsername(newUsername)
            isEditingUsername = false
            isUsernameFocused = false
        } catch {
            print("❌ [Profile] Error updating username: \(error)")
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
                    lastStatusUpdate: project.updatedAt
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
        NavigationStack {
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
                                    Text("12")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Projects")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("45")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Reviews")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("128")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Rumors")
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
                                Text("Error loading favorites: \(error.localizedDescription)")
                                    .foregroundColor(.red)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onTapGesture {
                if isEditingUsername {
                    isEditingUsername = false
                    isUsernameFocused = false
                }
            }
            .task {
                await fetchFavoriteProjects()
            }
        }
    }
}

#Preview {
    ProfileView()
}

struct FavoriteProjectItem: View {
    let project: ProjectPreview
    @Binding var favoriteProjects: [ProjectPreview]
    @State private var isUpdatingFavorite = false
    @State private var isFavorite = true // Since this is in favorites, it starts as true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
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
            
            // Favorite Button
            Button {
                Task {
                    isUpdatingFavorite = true
                    do {
                        isFavorite = try await FavoriteService.shared.toggleFavorite(projectId: project.id)
                        if !isFavorite {
                            // Remove the project from the favorites list
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
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(8)
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
