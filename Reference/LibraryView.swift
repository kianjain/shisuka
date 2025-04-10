import SwiftUI

struct ProjectCard: View {
    let project: ProjectPreview
    
    var body: some View {
        NavigationLink(destination: ProjectView(project: project)) {
            HStack(spacing: 16) {
                // Square Project Image
                if let imageUrl = project.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: fileTypeIcon)
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: fileTypeIcon)
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(10)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Project name and status
                    HStack {
                        Text(project.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.white)
                        Spacer()
                        Text(project.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .cornerRadius(4)
                    }
                    
                    // File type
                    Label(project.fileType, systemImage: fileTypeIcon)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Stats
                    HStack(spacing: 12) {
                        Label("\(project.feedback.count)", systemImage: "bubble.left.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Label("\(project.likes)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch project.status {
        case .active:
            return .white
        case .completed:
            return .green
        case .archived:
            return .gray
        }
    }
    
    private var fileTypeIcon: String {
        switch project.fileType {
        case "Audio":
            return "waveform"
        case "Images":
            return "photo"
        default:
            return "doc"
        }
    }
}

struct LibraryView: View {
    @State private var showingNotifications = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var selectedFilter: String = "All"
    @Binding var selectedTab: Int
    @EnvironmentObject private var userState: UserState
    
    // Mock data - will be replaced with backend data
    private let mockProjects = [
        ProjectPreview(
            from: Project(
                id: UUID(),
                userId: UUID(),
                title: "Project Title",
                description: "Project Description",
                fileType: "Audio",
                createdAt: Date(),
                updatedAt: Date(),
                files: [],
                feedback: [],
                isFavorite: false
            ),
            author: "You",
            feedback: [],
            isOwnedByUser: true
        ),
        ProjectPreview(
            from: Project(
                id: UUID(),
                userId: UUID(),
                title: "Project Title",
                description: "Project Description",
                fileType: "Images",
                createdAt: Date(),
                updatedAt: Date(),
                files: [],
                feedback: [],
                isFavorite: false
            ),
            author: "You",
            feedback: [],
            isOwnedByUser: true
        ),
        ProjectPreview(
            from: Project(
                id: UUID(),
                userId: UUID(),
                title: "Project Title",
                description: "Project Description",
                fileType: "Video",
                createdAt: Date(),
                updatedAt: Date(),
                files: [],
                feedback: [],
                isFavorite: false
            ),
            author: "You",
            feedback: [],
            isOwnedByUser: true
        )
    ]
    
    // Mock data for previews
    private let mockActiveProject = ProjectPreview(
        from: Project(
            id: UUID(),
            userId: UUID(),
            title: "Project Title",
            description: "Project Description",
            fileType: "Audio",
            createdAt: Date(),
            updatedAt: Date(),
            files: [],
            feedback: [],
            isFavorite: false
        ),
        author: "You",
        feedback: [],
        isOwnedByUser: true
    )
    
    private let mockCompletedProject = ProjectPreview(
        from: Project(
            id: UUID(),
            userId: UUID(),
            title: "Project Title",
            description: "Project Description",
            fileType: "Images",
            createdAt: Date(),
            updatedAt: Date(),
            files: [],
            feedback: [],
            isFavorite: false
        ),
        author: "You",
        feedback: [],
        isOwnedByUser: true
    )
    
    private let mockArchivedProject = ProjectPreview(
        from: Project(
            id: UUID(),
            userId: UUID(),
            title: "Project Title",
            description: "Project Description",
            fileType: "Video",
            createdAt: Date(),
            updatedAt: Date(),
            files: [],
            feedback: [],
            isFavorite: false
        ),
        author: "You",
        feedback: [],
        isOwnedByUser: true
    )
    
    private let filters = ["All", "Audio", "Image", "Active", "Completed", "Archived"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                filterPill(filter)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Projects List
                    LazyVStack(spacing: 16) {
                        ForEach(mockProjects.filter { project in
                            if selectedFilter == "All" { return true }
                            if selectedFilter == "Audio" { return project.fileType == "Audio" }
                            if selectedFilter == "Image" { return project.fileType == "Images" }
                            return project.status.rawValue == selectedFilter
                        }) { project in
                            ProjectCard(project: project)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 8.0)
            }
            .background(Color.black)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .padding(.leading, 8)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Notifications Button
                        Button {
                            showingNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .foregroundColor(.white)
                                
                                // Unread Indicator
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                        
                        // Settings Button
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                        }
                        
                        // Profile Button
                        Button {
                            showingProfile = true
                        } label: {
                            ProfilePicture(
                                username: userState.currentProfile?.username,
                                size: 32
                            )
                        }
                    }
                }
            }
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
    }
    
    private func filterPill(_ filter: String) -> some View {
        Button(action: {
            withAnimation {
                selectedFilter = filter
            }
        }) {
            Text(filter)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedFilter == filter ? .black : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if selectedFilter == filter {
                            Color.white
                        } else {
                            Color(.systemGray6)
                        }
                    }
                )
                .clipShape(Capsule())
        }
    }
}

#Preview {
    LibraryView(selectedTab: .constant(3))
} 
