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
    @State private var isShowingProject = false
    
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
                    if let error = error {
                        VStack(spacing: 16) {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("Error loading projects")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") {
                                    loadProjects()
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if projects.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No more projects to review")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Check back later for new content")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if currentIndex >= projects.count {
                        VStack(spacing: 16) {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No more projects to review")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Check back later for new content")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack {
                                Spacer()
                                    .frame(height: UIScreen.main.bounds.height * 0.10)
                                
                                projectCard(projects[currentIndex])
                                    .offset(offset)
                                    .rotationEffect(.degrees(Double(offset.width / 40)))
                                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3), value: offset)
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                // Only apply horizontal movement
                                                offset = CGSize(width: gesture.translation.width, height: 0)
                                            }
                                            .onEnded { gesture in
                                                let width = gesture.translation.width
                                                let velocity = gesture.predictedEndLocation.x - gesture.location.x
                                                
                                                if abs(width) > 150 || abs(velocity) > 500 {
                                                    let direction: CGFloat = (width + velocity) > 0 ? 1 : -1
                                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)) {
                                                        offset = CGSize(
                                                            width: direction * 500,
                                                            height: 0
                                                        )
                                                    }
                                                    currentIndex += 1
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)) {
                                                            offset = .zero
                                                        }
                                                    }
                                                } else {
                                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)) {
                                                        offset = .zero
                                                    }
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        if offset == .zero {
                                            // Navigate to project view
                                            let project = projects[currentIndex]
                                            isShowingProject = true
                                        }
                                    }
                                    .sheet(isPresented: $isShowingProject) {
                                        if currentIndex < projects.count {
                                            ProjectView(projectId: projects[currentIndex].id.uuidString)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 20)
                                
                                Spacer()
                                    .frame(height: UIScreen.main.bounds.height * 0.05)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .padding(.top, topBarHeight)
                    }
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
                    HStack(spacing: 8) {
                        ProfileButton(size: 32, action: {
                            showingProfile = true
                        })
                        
                        // Coin Display
                        HStack(spacing: 8) {
                            Image("coin")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 32)
                            if CoinService.shared.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("\(CoinService.shared.balance)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
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
            .sheet(isPresented: $showingNotifications) {
                ActivityView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
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
                        lastStatusUpdate: project.updatedAt,
                        hasUnreadFeedback: false
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
        
        return cardContent
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
