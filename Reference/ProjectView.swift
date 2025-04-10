import SwiftUI

// MARK: - Project Image View
private struct ProjectImageView: View {
    let fileType: String
    let imageUrl: URL?
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 340)
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
        .padding(.top)
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .overlay(
                Image(systemName: getFileTypeIcon(for: fileType))
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    private func getFileTypeIcon(for fileType: String) -> String {
        switch fileType {
        case "Audio": return "waveform"
        case "Images": return "photo"
        case "Video": return "video"
        default: return "doc"
        }
    }
}

// MARK: - Project Info View
private struct ProjectInfoView: View {
    let project: ProjectPreview
    @Binding var isFavorite: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Favorite Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    if project.isOwnedByUser {
                        Text("Added \(project.uploadDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("by \(project.author)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
            
            // Project Type Badge
            Text(project.fileType)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .foregroundColor(.white)
                .cornerRadius(8)
            
            // Description
            Text(project.description)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(nil)
            
            // Stats
            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.gray)
                    Text("\(project.feedback.count)")
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray)
                    Text("\(project.likes)")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }
}

// MARK: - Reviews View
private struct ReviewsView: View {
    let feedback: [ProjectFeedback]
    
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
                            Text(review.user?.username ?? "Anonymous")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(review.content)
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
    let project: ProjectPreview
    @State private var isFavorite: Bool = false
    @State private var showingFeedbackSheet: Bool = false
    @State private var feedbackText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Project Image
                ProjectImageView(
                    fileType: project.fileType,
                    imageUrl: project.imageUrl
                )
                
                // Project Info
                ProjectInfoView(
                    project: project,
                    isFavorite: $isFavorite
                )
                
                // Reviews
                ReviewsView(feedback: project.feedback)
                
                // Feedback Input
                if !project.isOwnedByUser {
                    FeedbackInputView { text in
                        // Handle feedback submission
                        print("Feedback submitted: \(text)")
                        feedbackText = ""
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Project Preview Initialization
extension ProjectPreview {
    init(from project: Project, author: String, feedback: [ProjectFeedback], isOwnedByUser: Bool) {
        self.id = project.id
        self.name = project.title
        self.description = project.description ?? ""
        self.fileType = project.fileType
        self.author = author
        self.imageUrl = project.files?.first?.url
        self.uploadDate = project.createdAt
        self.status = project.files?.first?.fileType == "Images" ? .active : .completed
        self.feedback = feedback
        self.rumorsSpent = 0
        self.likes = 0
        self.isOwnedByUser = isOwnedByUser
        self.lastStatusUpdate = project.updatedAt
    }
}

#Preview {
    NavigationStack {
        ProjectView(project: ProjectPreview(
            from: Project(
                id: UUID(),
                userId: UUID(),
                title: "Summer Beat",
                description: "A fresh electronic track with tropical vibes. Looking for feedback on the mix and arrangement.",
                fileType: .audio,
                createdAt: Date().addingTimeInterval(-7*24*3600),
                updatedAt: Date(),
                files: [ProjectFile.preview],
                feedback: [],
                isFavorite: false,
                status: .active
            ),
            author: "MusicMaker",
            feedback: [],
            isOwnedByUser: false
        ))
    }
} 
