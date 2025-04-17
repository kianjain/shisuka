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
                        .clipped()
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
    @Binding var isFavorite: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Favorite Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text("Added \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
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
    @StateObject private var projectService = ProjectService.shared
    @State private var project: Project?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isFavorite = false
    let projectId: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let project = project {
                    // Cover image
                    let storage = SupabaseManager.shared.client.storage.from("project_files")
                    if let imagePath = project.imagePath,
                       let imageURL = try? storage.getPublicURL(path: imagePath) {
                        ProjectImageView(imageURL: imageURL)
                    }
                    
                    // Project Info (Title and Date)
                    ProjectInfoView(project: project, isFavorite: $isFavorite)
                    
                    // Audio player
                    if let audioPath = project.audioPath {
                        let storage = SupabaseManager.shared.client.storage.from("project_files")
                        if let audioURL = try? storage.getPublicURL(path: audioPath) {
                            AudioPlayerView(audioURL: audioURL)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Description
                    if let description = project.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                                .lineLimit(4...)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                        }
                    }
                    
                    // Reviews
                    ReviewsView(feedback: [])
                } else if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
        .scrollIndicators(.hidden)
        .onAppear {
            loadProject()
        }
    }
    
    private func loadProject() {
        Task {
            do {
                project = try await projectService.getProjects().first { $0.id.uuidString == projectId }
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectView(projectId: "1")
    }
} 
