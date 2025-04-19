import SwiftUI
import AVFoundation

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
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
            
            HStack {
                Text("by \(username)")
                .font(.subheadline)
                .foregroundColor(.gray)
                
                Spacer()
                
                Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                        .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Reviews View
private struct ReviewsView: View {
    let feedback: [Feedback]
    
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(review.author)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                            Text(review.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(review.comment)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
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
    let projectId: String
    let isReviewMode: Bool
    
    @State private var project: Project?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var feedbackText = ""
    @State private var showFeedbackSheet = false
    @State private var isFavorite = false
    @State private var username: String = "User"
    
    // Editing states
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false
    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    init(projectId: String, isReviewMode: Bool = false) {
        self.projectId = projectId
        self.isReviewMode = isReviewMode
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let project = project {
        ScrollView {
            VStack(spacing: 24) {
                        // Cover image
                        let storage = SupabaseManager.shared.client.storage.from("project_files")
                        if let imagePath = project.imagePath,
                           let imageURL = try? storage.getPublicURL(path: imagePath) {
                            ProjectImageView(imageURL: imageURL)
                        } else {
                            ProjectImageView(imageURL: nil)
                        }
                        
                        // Project Info
                        ProjectInfoView(
                            project: project,
                            isReviewMode: isReviewMode,
                            isEditingTitle: $isEditingTitle,
                            editedTitle: $editedTitle,
                            isTitleFocused: _isTitleFocused,
                            onTitleUpdate: {
                                Task {
                                    await updateProjectTitle()
                                }
                            },
                            username: username
                        )
                        
                        // Audio Player
                        if let audioPath = project.audioPath {
                            if let audioURL = try? storage.getPublicURL(path: audioPath) {
                                AudioPlayerView(audioURL: audioURL)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Description
                        if let description = project.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
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
                                        .onAppear {
                                            isDescriptionFocused = true
                                        }
                                } else {
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .lineLimit(nil)
                                        .onTapGesture {
                                            if !isReviewMode {
                                                editedDescription = description
                                                isEditingDescription = true
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Feedback or Reviews Section
                        if isReviewMode {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Feedback")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("Write your feedback...", text: $feedbackText, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .frame(minHeight: 60, alignment: .topLeading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                
                                Button(action: {
                                    showFeedbackSheet = true
                                }) {
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
                            .padding(.horizontal)
                } else {
                            // Reviews
                            ReviewsView(feedback: [])
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 24)
                }
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .navigationBarHidden(true)
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await loadProject()
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Submit Feedback")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    TextField("Write your feedback...", text: $feedbackText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button("Submit") {
                        // TODO: Implement feedback submission
                        showFeedbackSheet = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showFeedbackSheet = false
                        }
                    }
                }
            }
        }
    }
    
    private func loadProject() async {
        do {
            guard let project = try await ProjectService.shared.getProject(byId: projectId) else {
                print("❌ [Project] Project not found with ID: \(projectId)")
                return
            }
            
            // Fetch username
            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .select("username")
                .eq("id", value: project.userId)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct ProfileResponse: Codable {
                let username: String
            }
            
            if let profiles = try? decoder.decode([ProfileResponse].self, from: response.data),
               let profile = profiles.first {
                await MainActor.run {
                    self.username = profile.username
                }
            }
            
            await MainActor.run {
                self.project = project
                self.isLoading = false
            }
        } catch {
            print("❌ [Project] Error loading project: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func updateProjectTitle() async {
        guard let project = project else { return }
        do {
            try await ProjectService.shared.updateProjectTitle(
                id: project.id,
                title: editedTitle
            )
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
            try await ProjectService.shared.updateProjectDescription(
                id: project.id,
                description: editedDescription
            )
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
}

#Preview {
    NavigationStack {
        ProjectView(projectId: "1")
    }
} 
