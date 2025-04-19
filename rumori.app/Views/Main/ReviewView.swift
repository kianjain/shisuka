import SwiftUI
import Supabase
import Foundation

struct ReviewView: View {
    @State private var offset: CGSize = .zero
    @State private var currentIndex = 0
    @State private var topBarHeight: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 2
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var searchText = ""
    @State private var selectedFilter: String = "All"
    @State private var projects: [ProjectPreview] = []
    @State private var isLoading = true
    @State private var error: Error?
    @EnvironmentObject private var projectService: ProjectService
    @StateObject private var auth = AuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if let error = error {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("Error loading projects")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if projects.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                VStack(spacing: 20) {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("No more projects to review")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Check back later for new content")
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if currentIndex < projects.count {
                            VStack {
                                Spacer()
                                    .frame(height: UIScreen.main.bounds.height * 0.10)
                                
                                projectCard(projects[currentIndex])
                                    .offset(offset)
                                    .rotationEffect(.degrees(Double(offset.width / 20)))
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                offset = gesture.translation
                                            }
                                            .onEnded { gesture in
                                                withAnimation {
                                                    let width = gesture.translation.width
                                                    if abs(width) > 100 {
                                                        offset = CGSize(
                                                            width: width > 0 ? 500 : -500,
                                                            height: 0
                                                        )
                                                        currentIndex += 1
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            offset = .zero
                                                        }
                                                    } else {
                                                        offset = .zero
                                                    }
                                                }
                                            }
                                    )
                                
                                Spacer()
                                    .frame(height: UIScreen.main.bounds.height * 0.05)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .padding(.top, topBarHeight)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileButton(size: 32) {
                        showingProfile = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            showingNotifications = true
                        }) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotifications) {
                ActivityView()
            }
        }
        .onAppear {
            loadProjects()
        }
    }
    
    private func loadProjects() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let projects = try await projectService.getProjectsForReview()
                var projectPreviews: [ProjectPreview] = []
                
                for project in projects {
                    // Determine file type based on available paths
                    let fileType = project.audioPath != nil ? "Audio" : "Images"
                    
                    // Fetch the author's profile
                    let authorName = try? await fetchAuthorName(userId: project.userId)
                    
                    let preview = ProjectPreview(
                        id: project.id,
                        name: project.title,
                        description: project.description ?? "",
                        fileType: fileType,
                        author: authorName ?? "User",
                        imageUrl: project.imagePath.map { path in
                            try? SupabaseManager.shared.client.storage
                                .from("project_files")
                                .getPublicURL(path: path)
                        } ?? nil,
                        uploadDate: project.createdAt,
                        status: project.status,
                        feedback: [],
                        rumorsSpent: 0,
                        likes: 0,
                        isOwnedByUser: false,
                        lastStatusUpdate: project.updatedAt
                    )
                    projectPreviews.append(preview)
                }
                
                self.projects = projectPreviews
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
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
    
    private func projectCard(_ project: ProjectPreview) -> some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            // Project Image
            Group {
                if let imageUrl = project.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 340)
                            .frame(height: 340)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(maxWidth: 340)
                            .frame(height: 340)
                            .overlay(
                                Image(systemName: getFileTypeIcon(for: project.fileType))
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: 340)
                        .frame(height: 340)
                        .overlay(
                            Image(systemName: getFileTypeIcon(for: project.fileType))
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            
            // Project Info
            VStack(alignment: .leading, spacing: 12) {
                Text(project.name)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // File Type
                HStack {
                    Image(systemName: getFileTypeIcon(for: project.fileType))
                        .foregroundColor(.gray)
                    Text(project.fileType)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Description
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .frame(maxHeight: 60)
                }
                
                HStack {
                    Text("by \(project.author)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(project.uploadDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
        }
        .frame(width: 340)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        
        return Group {
            if offset == .zero {
                NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func getFileTypeIcon(for fileType: String) -> String {
        switch fileType {
        case "Audio":
            return "waveform"
        case "Images":
            return "photo"
        case "Video":
            return "video"
        default:
            return "doc"
        }
    }
    
    private func skipProject() {
        print("Skipped project")
        moveToNextProject()
    }
    
    private func provideFeedback() {
        print("Providing feedback")
        // This would open a feedback form in the real implementation
    }
    
    private func likeProject() {
        print("Liked project")
        moveToNextProject()
    }
    
    private func moveToNextProject() {
        withAnimation {
            offset = CGSize(width: -500, height: 0)
            currentIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                offset = .zero
            }
        }
    }
}

#Preview {
    ReviewView()
} 
