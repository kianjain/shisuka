import SwiftUI

struct ProjectCard: View {
    let project: ProjectPreview
    @State private var imageError: Error?
    
    var body: some View {
        NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
            HStack(spacing: 16) {
                // Square Project Image
                Group {
                    if let imageUrl = project.imageUrl {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                            case .failure(let error):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: fileTypeIcon)
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                    )
                                    .onAppear {
                                        imageError = error
                                    }
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: fileTypeIcon)
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: fileTypeIcon)
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .cornerRadius(10)
                
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
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var searchText = ""
    @State private var selectedFilter: String = "All"
    @State private var showingUpload = false
    @State private var selectedTab: Int = 3
    @State private var projects: [ProjectPreview] = []
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.colorScheme) private var colorScheme
    
    private let filters = ["All", "Audio", "Image", "Active", "Completed", "Archived"]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
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
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                        } else if let error = error {
                            VStack(spacing: 12) {
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
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else if projects.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No projects yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Upload your first project to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(projects.filter { project in
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
                    }
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Library")
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
            .task {
                await loadProjects()
            }
        }
    }
    
    private func loadProjects() async {
        isLoading = true
        error = nil
        
        do {
            let projects = try await ProjectService.shared.getProjects()
            self.projects = projects.map { project in
                print("🔍 [Library] Project: \(project.title)")
                print("🔍 [Library] Image path: \(project.imagePath)")
                let imageUrl = {
                    let storage = SupabaseManager.shared.client.storage.from("project_files")
                    let url = try? storage.getPublicURL(path: project.imagePath)
                    print("🔍 [Library] Generated URL: \(String(describing: url))")
                    return url
                }()
                print("🔍 [Library] Final image URL: \(String(describing: imageUrl))")
                
                return ProjectPreview(
                    id: project.id,
                    name: project.title,
                    description: project.description ?? "",
                    fileType: project.audioPath != nil ? "Audio" : "Images",
                    author: "You",
                    imageUrl: imageUrl,
                    uploadDate: project.createdAt,
                    status: .active,
                    feedback: [],
                    rumorsSpent: 0,
                    likes: 0,
                    isOwnedByUser: true,
                    lastStatusUpdate: project.updatedAt
                )
            }
        } catch {
            self.error = error
            print("❌ Error loading projects: \(error)")
        }
        
        isLoading = false
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
    LibraryView()
} 
