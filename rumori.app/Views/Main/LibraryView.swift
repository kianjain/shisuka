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
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var searchText = ""
    @State private var selectedFilter: String = "All"
    @State private var showingUpload = false
    @State private var selectedTab: Int = 3
    @Environment(\.colorScheme) private var colorScheme
    
    // Mock data
    private let mockProjects = [
        ProjectPreview(
            id: UUID(),
            name: "Summer Beat",
            description: "A fresh electronic track with tropical vibes. Looking for feedback on the mix and arrangement.",
            fileType: "Audio",
            author: "MusicMaker",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            uploadDate: Date().addingTimeInterval(-7*24*3600),
            status: .active,
            feedback: [
                Feedback(
                    id: UUID(),
                    author: "SoundMaster",
                    comment: "Great mix! The tropical elements really shine through. Maybe consider adding more percussion in the bridge section.",
                    rating: 1,
                    date: Date().addingTimeInterval(-2*24*3600)
                )
            ],
            rumorsSpent: 0,
            likes: 12,
            isOwnedByUser: true,
            lastStatusUpdate: nil
        ),
        ProjectPreview(
            id: UUID(),
            name: "Portrait Series",
            description: "A collection of street photography shots. Need feedback on composition and editing.",
            fileType: "Images",
            author: "PhotoArtist",
            imageUrl: URL(string: "https://example.com/portrait-series-cover.jpg"),
            uploadDate: Date().addingTimeInterval(-14*24*3600),
            status: .completed,
            feedback: [
                Feedback(
                    id: UUID(),
                    author: "PhotoCritic",
                    comment: "The composition is excellent, especially in the urban environment shots. The contrast could be slightly increased in some images.",
                    rating: 1,
                    date: Date().addingTimeInterval(-5*24*3600)
                )
            ],
            rumorsSpent: 0,
            likes: 8,
            isOwnedByUser: true,
            lastStatusUpdate: nil
        ),
        ProjectPreview(
            id: UUID(),
            name: "Short Film Draft",
            description: "A 5-minute drama about family relationships. Looking for feedback on pacing and narrative.",
            fileType: "Video",
            author: "FilmStudent",
            imageUrl: URL(string: "https://example.com/short-film-cover.jpg"),
            uploadDate: Date().addingTimeInterval(-21*24*3600),
            status: .archived,
            feedback: [
                Feedback(
                    id: UUID(),
                    author: "FilmReviewer",
                    comment: "The pacing works well for the story. The emotional moments are well captured. Consider tightening the middle section slightly.",
                    rating: 1,
                    date: Date().addingTimeInterval(-10*24*3600)
                )
            ],
            rumorsSpent: 0,
            likes: 15,
            isOwnedByUser: true,
            lastStatusUpdate: nil
        )
    ]
    
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
    LibraryView()
} 
