import SwiftUI
import AVFoundation
import PhotosUI
import Supabase

// MARK: - Project Image View
private struct ProjectImageView: View {
    let imageURL: URL?
    
    var body: some View {
        Group {
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
}

// MARK: - Project Info View
private struct ProjectInfoView: View {
    let project: Project
    let isReviewMode: Bool
    @Binding var isEditingTitle: Bool
    @Binding var editedTitle: String
    @FocusState var isTitleFocused: Bool
    let onTitleUpdate: () -> Void
    let username: String
    @State private var isFavorite: Bool = false
    @State private var isUpdatingFavorite: Bool = false
    @State private var authorAvatarURL: URL?
    let feedbackCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Favorite Button
            HStack {
                if isEditingTitle {
                    TextField("Project Title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .focused($isTitleFocused)
                        .onSubmit {
                            onTitleUpdate()
                        }
                        .onAppear {
                            isTitleFocused = true
                        }
                } else {
                    Text(project.title)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .onTapGesture {
                            if !isReviewMode {
                                editedTitle = project.title
                                isEditingTitle = true
                            }
                        }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        isUpdatingFavorite = true
                        do {
                            // Toggle the favorite status
                            let newFavoriteState = try await FavoriteService.shared.toggleFavorite(projectId: project.id)
                            // Update the UI state
                            await MainActor.run {
                                isFavorite = newFavoriteState
                            }
                        } catch {
                            print("❌ [ProjectView] Error toggling favorite: \(error)")
                        }
                        isUpdatingFavorite = false
                    }
                }) {
                    if isUpdatingFavorite {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                }
                .disabled(isUpdatingFavorite)
            }
            
            // Author and Date
            HStack {
                // Author Avatar and Name
                HStack(spacing: 8) {
                    if let avatarURL = authorAvatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(username.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text(username)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .task {
            do {
                isFavorite = try await FavoriteService.shared.isProjectFavorited(projectId: project.id)
                
                // Fetch author's profile image
                let response = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("avatar_url")
                    .eq("id", value: project.userId)
                    .execute()
                
                let decoder = JSONDecoder()
                struct ProfileResponse: Codable {
                    let avatar_url: String?
                }
                
                if let profiles = try? decoder.decode([ProfileResponse].self, from: response.data),
                   let profile = profiles.first,
                   let avatarUrl = profile.avatar_url {
                    authorAvatarURL = URL(string: avatarUrl)
                }
            } catch {
                print("❌ [ProjectView] Error checking favorite status or fetching avatar: \(error)")
            }
        }
    }
}

// MARK: - Reviews View
private struct ReviewsView: View {
    let feedback: [FeedbackResponse]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reviews")
                .font(.headline)
                .foregroundColor(.white)
            
            if feedback.isEmpty {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(feedback, id: \.id) { review in
                    ReviewItemView(review: review)
                }
            }
        }
        .padding()
    }
}

private struct ReviewItemView: View {
    @State var review: FeedbackResponse
    @State private var authorAvatarURL: URL?
    @State private var isUpdatingRating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Author Avatar and Name
                HStack(spacing: 8) {
                    if let avatarURL = authorAvatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(review.author.username.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text(review.author.username)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(.gray)
            
            // Helpful Rating Buttons
            VStack(spacing: 8) {
                Text("Helpful?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { 
                        print("😑 Button clicked - Current rating: \(review.helpfulRating ?? -999)")
                        updateRating(-1) 
                    }) {
                        Text("😑")
                            .font(.title2)
                            .opacity(review.helpfulRating == -1 ? 1.0 : 0.5)
                    }
                    .disabled(isUpdatingRating)
                    
                    Button(action: { 
                        print("🤔 Button clicked - Current rating: \(review.helpfulRating ?? -999)")
                        updateRating(0) 
                    }) {
                        Text("🤔")
                            .font(.title2)
                            .opacity(review.helpfulRating == 0 ? 1.0 : 0.5)
                    }
                    .disabled(isUpdatingRating)
                    
                    Button(action: { 
                        print("🫡 Button clicked - Current rating: \(review.helpfulRating ?? -999)")
                        updateRating(1) 
                    }) {
                        Text("🫡")
                            .font(.title2)
                            .opacity(review.helpfulRating == 1 ? 1.0 : 0.5)
                    }
                    .disabled(isUpdatingRating)
                    Spacer()
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .task {
            do {
                // Fetch author's profile image
                let response = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("avatar_url")
                    .eq("id", value: review.authorId)
                    .execute()
                
                let decoder = JSONDecoder()
                struct ProfileResponse: Codable {
                    let avatar_url: String?
                }
                
                if let profiles = try? decoder.decode([ProfileResponse].self, from: response.data),
                   let profile = profiles.first,
                   let avatarUrl = profile.avatar_url {
                    authorAvatarURL = URL(string: avatarUrl)
                }
            } catch {
                print("❌ [ProjectView] Error fetching author avatar: \(error)")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateRating(_ rating: Int) {
        print("🔄 [Rating] Starting rating update - Feedback ID: \(review.id), New rating: \(rating)")
        isUpdatingRating = true
        
        Task {
            do {
                print("🔄 [Rating] Calling updateHelpfulRating service")
                try await FeedbackService.shared.updateHelpfulRating(feedbackId: review.id, rating: rating)
                print("✅ [Rating] Successfully updated rating to \(rating)")
                
                // Update the local state with the new rating
                await MainActor.run {
                    review = FeedbackResponse(
                        id: review.id,
                        projectId: review.projectId,
                        authorId: review.authorId,
                        comment: review.comment,
                        createdAt: review.createdAt,
                        seenAt: review.seenAt,
                        author: review.author,
                        helpfulRating: rating
                    )
                }
            } catch {
                print("❌ [Rating] Error updating rating: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
            isUpdatingRating = false
            print("🔄 [Rating] Update completed - isUpdatingRating set to false")
        }
    }
}

// MARK: - Feedback Input View
private struct FeedbackInputView: View {
    @State private var feedbackText: String = ""
    let onSubmit: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Feedback")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $feedbackText)
                .frame(height: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scrollContentBackground(.hidden)
            
            Button(action: { onSubmit(feedbackText) }) {
                Text("Submit Feedback")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
            }
            .disabled(feedbackText.isEmpty)
            .opacity(feedbackText.isEmpty ? 0.6 : 1.0)
        }
        .padding()
    }
}

// MARK: - Main Project View
struct ProjectView: View {
    @Environment(\.dismiss) private var dismiss
    let projectId: String
    
    @State private var project: Project?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var username: String = "User"
    @State private var isOwnedByUser: Bool = false
    
    // Feedback states
    @State private var feedbackText = ""
    @State private var isSubmittingFeedback = false
    @State private var feedbackError: Error?
    @State private var showFeedbackError = false
    @State private var projectFeedback: [FeedbackResponse] = []
    @State private var isFeedbackLoading = true
    @State private var userFeedback: FeedbackResponse?
    
    // Editing states
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false
    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // Success state
    @State private var showFeedbackSuccess = false
    
    // New states
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: Project?
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isUploadingImage = false
    @State private var imageError: Error?
    @State private var showImageError = false
    @State private var isDeleting = false
    @State private var isShowingProject = false
    @State private var isShowingLibrary = false
    @State private var selectedTab: Int = 0
    
    init(projectId: String) {
        self.projectId = projectId
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Error loading project")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(error.localizedDescription)
                        .foregroundColor(.gray)
                }
            } else if showFeedbackSuccess {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("Feedback Submitted!")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Thank you for your feedback!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
                .onTapGesture {
                    showFeedbackSuccess = false
                    dismiss()
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if let project = project {
                            // Cover image
                            let storage = SupabaseManager.shared.client.storage.from("project_files")
                            if let imagePath = project.imagePath,
                               let imageURL = try? storage.getPublicURL(path: imagePath) {
                                ProjectImageView(imageURL: imageURL)
                            } else {
                                ProjectImageView(imageURL: nil)
                            }
                            
                            ProjectInfoView(
                                project: project,
                                isReviewMode: false,
                                isEditingTitle: $isEditingTitle,
                                editedTitle: $editedTitle,
                                isTitleFocused: _isTitleFocused,
                                onTitleUpdate: {
                                    Task {
                                        await updateProjectTitle()
                                    }
                                },
                                username: username,
                                feedbackCount: projectFeedback.count
                            )
                            
                            // Audio Player
                            if let audioPath = project.audioPath,
                               let audioURL = try? storage.getPublicURL(path: audioPath) {
                                // Get the original filename without extension
                                let originalName = (audioPath as NSString).deletingPathExtension
                                // Create the final path with .m4a extension
                                let finalAudioPath = "\(originalName).m4a"
                                if let finalAudioURL = try? storage.getPublicURL(path: finalAudioPath) {
                                    AudioPlayerView(audioURL: finalAudioURL)
                                        .padding(.horizontal)
                                }
                            }
                            
                            // Description
                            if let description = project.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if isEditingDescription {
                                        TextField("Project Description", text: $editedDescription, axis: .vertical)
                                            .textFieldStyle(.plain)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .focused($isDescriptionFocused)
                                            .lineLimit(nil)
                                            .onSubmit {
                                                Task {
                                                    await updateProjectDescription()
                                                }
                                            }
                                    } else {
                                        Text(description)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .lineLimit(nil)
                                            .onTapGesture {
                                                if isOwnedByUser {
                                                    editedDescription = description
                                                    isEditingDescription = true
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Feedback input for other users' projects
                            if !isOwnedByUser {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let userFeedback = userFeedback {
                                        // Show user's existing feedback
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Your Feedback")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text(userFeedback.comment)
                                                .foregroundColor(.white)
                                                .padding(12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(12)
                                            
                                            Text("Submitted on \(userFeedback.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        // Show feedback input form
                                        HStack {
                                            Text("Your Feedback")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(feedbackText.count)/100")
                                                .font(.caption)
                                                .foregroundColor(feedbackText.count >= 100 ? .white : .gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        TextField("Write your feedback...", text: $feedbackText, axis: .vertical)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .foregroundColor(.white)
                                            .frame(minHeight: 60, alignment: .topLeading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                        
                                        Spacer()
                                            .frame(height: 16)
                                        
                                        Button(action: submitFeedback) {
                                            if isSubmittingFeedback {
                                                HStack {
                                                    Spacer()
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle())
                                                    Spacer()
                                                }
                                            } else {
                                                Text("Submit Feedback")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.black)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white, lineWidth: 1)
                                                    )
                                                    .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                                            }
                                        }
                                        .disabled(isSubmittingFeedback || feedbackText.count < 100)
                                        .opacity(feedbackText.count < 100 ? 0.6 : 1.0)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Reviews section for owned projects
                            if isOwnedByUser {
                                if isFeedbackLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding()
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Reviews")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if projectFeedback.isEmpty {
                                            Text("No reviews yet")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .padding()
                                        } else {
                                            ForEach(projectFeedback, id: \.id) { review in
                                                ReviewItemView(review: review)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await loadProject()
                await loadFeedback()
            }
        }
        .alert("Error Submitting Feedback", isPresented: $showFeedbackError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(feedbackError?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    private func fetchAuthorName(userId: UUID) async throws -> String? {
        let response = try await SupabaseManager.shared.client
            .from("profiles")
            .select("username")
            .eq("id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct ProfileResponse: Codable {
            let username: String
        }
        
        if let profiles = try? decoder.decode([ProfileResponse].self, from: response.data),
           let profile = profiles.first {
            return profile.username
        }
        return nil
    }
    
    private func loadProject() async {
        do {
            guard let loadedProject = try await ProjectService.shared.getProject(byId: projectId) else {
                print("❌ [Project] Project not found with ID: \(projectId)")
                return
            }
            
            // Get the project author's username
            let authorName = try? await fetchAuthorName(userId: loadedProject.userId)
            
            await MainActor.run {
                self.project = loadedProject
                self.username = authorName ?? "User"
                self.isLoading = false
                // Check if the project is owned by the current user
                if let currentUserId = AuthService.shared.currentUser?.id {
                    self.isOwnedByUser = loadedProject.userId == currentUserId
                }
            }
        } catch {
            print("❌ [Project] Error loading project: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func updateProjectTitle() async {
        guard let project = project else { return }
        
        do {
            try await ProjectService.shared.updateProjectTitle(id: project.id, title: editedTitle)
            
            await MainActor.run {
                self.project = Project(
                    id: project.id,
                    userId: project.userId,
                    title: editedTitle,
                    description: project.description,
                    imagePath: project.imagePath,
                    audioPath: project.audioPath,
                    createdAt: project.createdAt,
                    updatedAt: Date(),
                    status: project.status
                )
                self.isEditingTitle = false
            }
        } catch {
            print("❌ [Project] Error updating title: \(error)")
        }
    }
    
    private func updateProjectDescription() async {
        guard let project = project else { return }
        
        do {
            try await ProjectService.shared.updateProjectDescription(id: project.id, description: editedDescription)
            
            await MainActor.run {
                self.project = Project(
                    id: project.id,
                    userId: project.userId,
                    title: project.title,
                    description: editedDescription,
                    imagePath: project.imagePath,
                    audioPath: project.audioPath,
                    createdAt: project.createdAt,
                    updatedAt: Date(),
                    status: project.status
                )
                self.isEditingDescription = false
            }
        } catch {
            print("❌ [Project] Error updating description: \(error)")
        }
    }
    
    private func loadFeedback() async {
        guard let projectUUID = UUID(uuidString: projectId) else { return }
        
        do {
            let feedback = try await FeedbackService.shared.getFeedbackForProject(projectId: projectUUID)
            
            // Only mark feedback as seen if the current user is the project owner
            if let currentUserId = AuthService.shared.currentUser?.id,
               let project = project,
               currentUserId == project.userId {
                for item in feedback {
                    if item.seenAt == nil {
                        try await FeedbackService.shared.markFeedbackAsSeen(feedbackId: item.id)
                    }
                }
            }
            
            // Check if current user has already reviewed
            if let currentUserId = AuthService.shared.currentUser?.id {
                userFeedback = feedback.first { $0.authorId == currentUserId }
            }
            
            await MainActor.run {
                self.projectFeedback = feedback
                self.isFeedbackLoading = false
            }
        } catch {
            print("❌ [Project] Error loading feedback: \(error)")
            await MainActor.run {
                self.isFeedbackLoading = false
            }
        }
    }
    
    private func submitFeedback() {
        guard let projectUUID = UUID(uuidString: projectId) else { return }
        isSubmittingFeedback = true
        
        Task {
            do {
                try await FeedbackService.shared.submitFeedback(
                    projectId: projectUUID,
                    comment: feedbackText
                )
                // Clear the form after successful submission
                await MainActor.run {
                    feedbackText = ""
                    isSubmittingFeedback = false
                    showFeedbackSuccess = true
                }
                // Reload feedback to show the new one
                await loadFeedback()
            } catch {
                await MainActor.run {
                    feedbackError = error
                    showFeedbackError = true
                    isSubmittingFeedback = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectView(projectId: "1")
    }
} 
