import SwiftUI

// Model types for HomeView
struct ReviewProject: Identifiable {
    let id = UUID()
    let title: String
    let type: String
    let imageUrl: URL?
}

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

struct Stat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            Text(value)
                .font(.title)
                .bold()
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
    }
}

struct FeaturedProjectCard: View {
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
                                Image(systemName: getFileTypeIcon(for: project.fileType))
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                    .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: getFileTypeIcon(for: project.fileType))
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .cornerRadius(12)
                }
                
                // Project Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(project.fileType)
                            .font(.caption)
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Text("Added \(project.uploadDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
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
}

struct FeedbackCountCard: View {
    let count: Int
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 82, weight: .semibold))
                .foregroundColor(.white)
                // Subtle shadows for depth
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: -2, y: 2)
                .shadow(color: Color.white.opacity(0.3), radius: 5, x: 2, y: -2)
            
            Text("New Reviews")
                .font(.title3)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top,32)
        .padding(.bottom, 16)
    }
}

struct LibraryButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title3)
                Text("View Library")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .padding(.bottom, 20)
    }
}

struct MinimalisticCardItem {
    let name: String
    let subtitle: String
    let description: String
    let imageUrl: URL?
    let type: String
}

struct MinimalisticCard: View {
    let title: String
    let icon: String
    let items: [MinimalisticCardItem]
    let color: Color
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Items
            VStack(spacing: 12) {
                ForEach(items, id: \.name) { item in
                    NavigationLink(destination: ProjectView(project: ProjectPreview(
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
                    ))) {
                        HStack(spacing: 12) {
                            // Image or Icon
                            if let imageUrl = item.imageUrl {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipped()
                                        .cornerRadius(10)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 56, height: 56)
                                        .cornerRadius(10)
                                        .overlay(
                                            Image(systemName: getFileTypeIcon(for: item.type))
                                                .font(.system(size: 20))
                                                .foregroundColor(.white.opacity(0.5))
                                        )
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(10)
                                    .overlay(
                                        Image(systemName: getNotificationIcon(for: item.type))
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                            }
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Action Button
            Button(action: action) {
                HStack {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            Color(red: 0.08, green: 0.08, blue: 0.08)
            .background(.ultraThinMaterial)
        )
        .cornerRadius(16)
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
    
    private func getNotificationIcon(for type: String) -> String {
        switch type {
        case "comment":
            return "bubble.left.fill"
        case "checkmark.circle":
            return "checkmark.circle.fill"
        case "person.2":
            return "person.2.fill"
        default:
            return "bell.fill"
        }
    }
}

struct ReviewProjectCard: View {
    let title: String
    let type: String
    let imageUrl: URL?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: getFileTypeIcon(for: type))
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: getFileTypeIcon(for: type))
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                startPoint: .bottom,
                endPoint: .center
            )
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(type.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .frame(width: 160, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getFileTypeIcon(for fileType: String) -> String {
        switch fileType {
        case "Audio":
            return "waveform"
        case "Images":
            return "photo"
        default:
            return "doc"
        }
    }
}

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var showingUpload = false
    
    // Mock data for preview
    private let mockProjects = [
        Project(
            id: UUID(),
            title: "Summer Beat",
            description: "A fresh electronic track with tropical vibes",
            fileType: .audio,
            status: .pending,
            createdAt: Date().addingTimeInterval(-7*24*3600),
            updatedAt: Date()
        ),
        Project(
            id: UUID(),
            title: "Nature Photography",
            description: "Collection of landscape photos",
            fileType: .image,
            status: .inReview,
            createdAt: Date().addingTimeInterval(-5*24*3600),
            updatedAt: Date()
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Featured Projects
                    VStack(alignment: .leading) {
                        Text("Featured Projects")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(mockProjects) { project in
                                    ProjectCard(project: project)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading) {
                        Text("Recent Activity")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(mockProjects) { project in
                            ActivityRow(project: project)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingUpload = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingUpload) {
                UploadView()
            }
        }
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading) {
            // Project Image/Thumbnail
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 120)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.headline)
                
                if let description = project.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: project.fileType == .audio ? "waveform" : "photo")
                    Text(project.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(project.status.color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActivityRow: View {
    let project: Project
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(project.title)
                    .font(.headline)
                
                if let description = project.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Updated \(project.updatedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: project.fileType == .audio ? "waveform" : "photo")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

#Preview {
    HomeView()
} 
