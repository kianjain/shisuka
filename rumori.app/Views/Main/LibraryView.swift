import SwiftUI

struct ProjectCard: View {
    let project: ProjectPreview
    @State private var imageError: Error?
    @State private var showingActionSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var projectService: ProjectService
    
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
        .contextMenu {
            if project.isOwnedByUser {
                Button(action: {
                    Task {
                        do {
                            try await projectService.updateProjectStatus(project.id, to: .archived)
                        } catch {
                            showingError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }) {
                    Label("Archive", systemImage: "archivebox")
                }
                
                Button(role: .destructive, action: {
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            "Delete Project",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await projectService.deleteProject(project.id)
                    } catch {
                        showingError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
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
    @EnvironmentObject private var projectService: ProjectService
    @State private var projects: [ProjectPreview] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var searchText = ""
    @State private var selectedFilter: String = "All"
    @State private var showingUploadSheet = false
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: ProjectPreview?
    @State private var showingNotifications = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var selectedTab: Int = 1
    
    private let filters = ["All", "Audio", "Image", "Active", "Completed", "Archived"]
    
    var filteredProjects: [ProjectPreview] {
        var filtered = projects
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if selectedFilter == "All" { return filtered }
        if selectedFilter == "Audio" { return filtered.filter { $0.fileType == "Audio" } }
        if selectedFilter == "Image" { return filtered.filter { $0.fileType == "Images" } }
        return filtered.filter { $0.status.rawValue == selectedFilter }
    }
    
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
                } else if filteredProjects.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No projects found")
                                .font(.headline)
                                .foregroundColor(.white)
                            if !searchText.isEmpty {
                                Text("Try adjusting your search")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Upload your first project to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search projects...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(100)
                            .padding(.horizontal)
                            
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
                            if let error = error {
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
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredProjects) { project in
                                        ProjectCard(project: project)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8.0)
                    }
                }
            }
            .navigationTitle("Library")
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
            .sheet(isPresented: $showingUploadSheet) {
                UploadView()
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
            .alert("Delete Project", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        deleteProject(project)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this project? This action cannot be undone.")
            }
        }
        .onAppear {
            loadProjects()
        }
    }
    
    private func filterPill(_ filter: String) -> some View {
        Button(action: { selectedFilter = filter }) {
            Text(filter)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedFilter == filter ? Color.white : Color(.systemGray6))
                .foregroundColor(selectedFilter == filter ? .black : .white)
                .cornerRadius(16)
        }
    }
    
    private func loadProjects() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let projects = try await ProjectService.shared.getProjects()
                self.projects = projects.map { project in
                    print("🔍 [Library] Project: \(project.title)")
                    print("🔍 [Library] Image path: \(String(describing: project.imagePath))")
                    let imageUrl = {
                        let storage = SupabaseManager.shared.client.storage.from("project_files")
                        if let imagePath = project.imagePath {
                            let url = try? storage.getPublicURL(path: imagePath)
                            print("🔍 [Library] Generated URL: \(String(describing: url))")
                            return url
                        }
                        return nil
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
                        status: project.status,
                        feedback: [],
                        rumorsSpent: 0,
                        likes: 0,
                        isOwnedByUser: true,
                        lastStatusUpdate: project.updatedAt
                    )
                }
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func deleteProject(_ project: ProjectPreview) {
        Task {
            do {
                try await ProjectService.shared.deleteProject(project.id)
                loadProjects() // Refresh the list after deletion
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    LibraryView()
} 

