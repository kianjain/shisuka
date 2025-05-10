import SwiftUI
import Foundation

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
        NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
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
                .font(.system(size: 72, weight: .semibold))
                .foregroundColor(.white)
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
    let id: String
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
        VStack(alignment: .leading, spacing: 16) {
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
            .padding(.horizontal, 16)
            
            // Items
            VStack(spacing: 16) {
                ForEach(items, id: \.id) { item in
                    NavigationLink(destination: ProjectView(projectId: item.id)) {
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
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(item.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 16)
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
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
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
        case "nosign":
            return "nosign"
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
                        .frame(width: 160, height: 200)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 160, height: 200)
                        .overlay(
                            Image(systemName: getFileTypeIcon(for: type))
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 200)
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
            .frame(width: 160, height: 200)
            
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
            .frame(width: 160, height: 200, alignment: .bottomLeading)
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
    @State private var showingNotifications = false
    @State private var showingProfile = false
    @State private var showingSettings = false
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var projectService: ProjectService
    @StateObject private var auth = AuthService.shared
    @StateObject private var coinService = CoinService.shared
    @State private var unreadFeedbackCount: Int = 0
    
    // State for review projects
    @State private var reviewProjects: [ProjectPreview] = []
    @State private var isLoadingReviewProjects = true
    @State private var reviewProjectsError: Error?
    
    // State for recent projects
    @State private var recentProjects: [ProjectPreview] = []
    @State private var isLoadingRecentProjects = true
    @State private var recentProjectsError: Error?
    
    // Notifications state
    @State private var notifications: [NotificationItem] = []
    @State private var isLoadingNotifications = true
    @State private var notificationsError: Error?
    
    // Favorites data
    private let favoriteItems = [
        MinimalisticCardItem(
            id: "Summer Beat",
            name: "Summer Beat",
            subtitle: "🎵",
            description: "A fresh electronic track with tropical vibes",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            type: "Audio"
        ),
        MinimalisticCardItem(
            id: "Portrait Series",
            name: "Portrait Series",
            subtitle: "📸",
            description: "A collection of street photography shots",
            imageUrl: URL(string: "https://example.com/portrait-series-cover.jpg"),
            type: "Images"
        ),
        MinimalisticCardItem(
            id: "Urban Soundscape",
            name: "Urban Soundscape",
            subtitle: "🎧",
            description: "Field recordings from city streets",
            imageUrl: URL(string: "https://example.com/urban-soundscape-cover.jpg"),
            type: "Audio"
        )
    ]
    
    // Notifications data
    private let notificationItems = [
        MinimalisticCardItem(
            id: "New Feedback",
            name: "New Feedback",
            subtitle: "2h ago",
            description: "John commented on 'Summer Beat'",
            imageUrl: nil,
            type: "comment"
        ),
        MinimalisticCardItem(
            id: "Project Completed",
            name: "Project Completed",
            subtitle: "1d ago",
            description: "Portrait Series is now live",
            imageUrl: nil,
            type: "checkmark.circle"
        ),
        MinimalisticCardItem(
            id: "New Followers",
            name: "New Followers",
            subtitle: "2d ago",
            description: "You gained 3 new followers",
            imageUrl: nil,
            type: "person.2"
        )
    ]
    
    // Recent Projects data
    private let recentProjectItems = [
        MinimalisticCardItem(
            id: "Urban Soundscape",
            name: "Urban Soundscape",
            subtitle: "2 days ago",
            description: "A collection of field recordings capturing the unique sounds of city life, from bustling streets to quiet alleyways.",
            imageUrl: URL(string: "https://example.com/urban-soundscape-cover.jpg"),
            type: "Audio"
        ),
        MinimalisticCardItem(
            id: "Portrait Series",
            name: "Portrait Series",
            subtitle: "5 days ago",
            description: "A series of street portraits exploring human emotions and connections in urban environments.",
            imageUrl: URL(string: "https://example.com/portrait-series-cover.jpg"),
            type: "Images"
        ),
        MinimalisticCardItem(
            id: "Summer Beat",
            name: "Summer Beat",
            subtitle: "1 week ago",
            description: "An upbeat electronic track blending tropical elements with modern production techniques.",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            type: "Audio"
        )
    ]
    
    private let featuredProjects = [
        ProjectPreview(
            id: UUID(),
            name: "Summer Beat",
            description: "A fresh electronic track with tropical vibes. Looking for feedback on the mix and arrangement.",
            fileType: "Audio",
            author: "MusicMaker",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            uploadDate: Date().addingTimeInterval(-7*24*3600),
            status: .active,
            feedback: [],
            rumorsSpent: 0,
            likes: 12,
            isOwnedByUser: false,
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
                    date: Date().addingTimeInterval(-5*24*3600)
                )
            ],
            rumorsSpent: 0,
            likes: 8,
            isOwnedByUser: true,
            lastStatusUpdate: nil
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Feedback Count Section
                        VStack(spacing: 16) {
                            FeedbackCountCard(count: unreadFeedbackCount)
                            
                            LibraryButton {
                                selectedTab = 3 // Navigate to Library tab
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Earn Rumors Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Earn Coins")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                            
                            if isLoadingReviewProjects {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(0..<5) { _ in
                                            ReviewProjectCard(
                                                title: "Loading...",
                                                type: "Audio",
                                                imageUrl: nil
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if let error = reviewProjectsError {
                                VStack(spacing: 8) {
                                    Text("Failed to load projects")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(error.localizedDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Button("Try Again") {
                                        loadReviewProjects()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white)
                                }
                                .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(reviewProjects.prefix(5)) { project in
                                            NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
                                                ReviewProjectCard(
                                                    title: project.name,
                                                    type: project.fileType,
                                                    imageUrl: project.imageUrl
                                                )
                                            }
                                        }
                                        
                                        // Review More Card
                                        Button(action: {
                                            selectedTab = 2 // Navigate to Review tab
                                        }) {
                                            ZStack(alignment: .bottomLeading) {
                                                // Background Image
                                                Image("Frame 615")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 160, height: 200)
                                                
                                                // Gradient Overlay
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                                    startPoint: .bottom,
                                                    endPoint: .center
                                                )
                                                
                                                // Text Content
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("REVIEW")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.8))
                                                    Text("More Projects")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                }
                                                .padding(12)
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Notifications Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Notifications")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingNotifications = true
                                }) {
                                    Text("View All")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            if isLoadingNotifications {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if let error = notificationsError {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                    Text("Error loading notifications")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else if notifications.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                    Text("No notifications yet")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(notifications.prefix(3)) { notification in
                                        HStack(spacing: 12) {
                                            // Project Image or Profile Picture
                                            if let projectImage = notification.projectImage {
                                                if notification.action == "just reviewed" {
                                                    // Circular profile picture for feedback
                                                    AsyncImage(url: projectImage) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 56, height: 56)
                                                            .clipShape(Circle())
                                                    } placeholder: {
                                                        Circle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 56, height: 56)
                                                    }
                                                } else {
                                                    // Regular project image for uploads
                                                    AsyncImage(url: projectImage) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 56, height: 56)
                                                            .cornerRadius(10)
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 56, height: 56)
                                                            .cornerRadius(10)
                                                    }
                                                }
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 56, height: 56)
                                                    .cornerRadius(10)
                                                    .overlay(
                                                        Image(systemName: notification.action == "just reviewed" ? "person.fill" : "doc.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.white.opacity(0.5))
                                                    )
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(notification.projectName)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Text(notification.timeAgo)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                if notification.action == "uploaded" {
                                                    Text("was successfully uploaded!")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                } else {
                                                    HStack(spacing: 0) {
                                                        Text("was reviewed by ")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text(notification.userName)
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text("!")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .background(
                            Color(red: 0.08, green: 0.08, blue: 0.08)
                            .background(.ultraThinMaterial)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        
                        // Minimalistic Cards Section
                        VStack(spacing: 16) {
                            if isLoadingRecentProjects {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Recent Projects")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            selectedTab = 3 // Navigate to Library tab
                                        }) {
                                            Text("View All")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .padding(.vertical, 16)
                                .background(
                                    Color(red: 0.08, green: 0.08, blue: 0.08)
                                    .background(.ultraThinMaterial)
                                )
                                .cornerRadius(16)
                            } else if recentProjects.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Recent Projects")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            selectedTab = 1 // Navigate to Upload tab
                                        }) {
                                            Text("Upload Project")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "nosign")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gray)
                                        Text("No projects yet")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                }
                                .padding(.vertical, 16)
                                .background(
                                    Color(red: 0.08, green: 0.08, blue: 0.08)
                                    .background(.ultraThinMaterial)
                                )
                                .cornerRadius(16)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Recent Projects")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            selectedTab = 3 // Navigate to Library tab
                                        }) {
                                            Text("View All")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    VStack(spacing: 16) {
                                        ForEach(recentProjects.prefix(3)) { project in
                                            NavigationLink(destination: ProjectView(projectId: project.id.uuidString)) {
                                                HStack(spacing: 12) {
                                                    // Project Image
                                                    if let imageUrl = project.imageUrl {
                                                        AsyncImage(url: imageUrl) { image in
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 56, height: 56)
                                                                .cornerRadius(10)
                                                        } placeholder: {
                                                            Rectangle()
                                                                .fill(Color.gray.opacity(0.3))
                                                                .frame(width: 56, height: 56)
                                                                .cornerRadius(10)
                                                                .overlay(
                                                                    Image(systemName: getFileTypeIcon(for: project.fileType))
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
                                                                Image(systemName: getFileTypeIcon(for: project.fileType))
                                                                    .font(.system(size: 20))
                                                                    .foregroundColor(.white.opacity(0.5))
                                                            )
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        HStack {
                                                            Text(project.name)
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(.white)
                                                            
                                                            Spacer()
                                                            
                                                            Text(project.uploadDate.formatted(date: .abbreviated, time: .omitted))
                                                                .font(.subheadline)
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Text(project.description)
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .background(
                                    Color(red: 0.08, green: 0.08, blue: 0.08)
                                    .background(.ultraThinMaterial)
                                )
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await loadReviewProjects()
                    await loadRecentProjects()
                    loadNotifications()
                    do {
                        unreadFeedbackCount = try await FeedbackService.shared.getUnreadFeedbackCount()
                    } catch {
                        print("❌ [HomeView] Error refreshing unread feedback count: \(error)")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
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
                            if coinService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("\(coinService.balance)")
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
            loadReviewProjects()
            loadRecentProjects()
            loadNotifications()
            Task {
                do {
                    print("🔄 [HomeView] Fetching unread feedback count...")
                    unreadFeedbackCount = try await FeedbackService.shared.getUnreadFeedbackCount()
                    print("✅ [HomeView] Updated unread feedback count to: \(unreadFeedbackCount)")
                } catch {
                    print("❌ [HomeView] Error fetching unread feedback count: \(error)")
                }
            }
        }
    }
    
    private func loadReviewProjects() {
        isLoadingReviewProjects = true
        reviewProjectsError = nil
        
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
                
                self.reviewProjects = projectPreviews
                isLoadingReviewProjects = false
            } catch {
                self.reviewProjectsError = error
                isLoadingReviewProjects = false
            }
        }
    }
    
    private func loadRecentProjects() {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        isLoadingRecentProjects = true
        recentProjectsError = nil
        
        Task {
            do {
                let projects = try await projectService.getUserProjects(userId: userId)
                var projectPreviews: [ProjectPreview] = []
                
                for project in projects {
                    let preview = ProjectPreview(
                        id: project.id,
                        name: project.title,
                        description: project.description ?? "",
                        fileType: project.audioPath != nil ? "Audio" : "Images",
                        author: "You",
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
                        isOwnedByUser: true,
                        lastStatusUpdate: project.updatedAt
                    )
                    projectPreviews.append(preview)
                }
                
                // Sort by upload date, newest first
                self.recentProjects = projectPreviews.sorted { $0.uploadDate > $1.uploadDate }
                isLoadingRecentProjects = false
            } catch {
                self.recentProjectsError = error
                isLoadingRecentProjects = false
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
    
    private func loadNotifications() {
        Task {
            do {
                async let uploads = NotificationService.shared.getProjectUploadNotifications()
                async let feedback = NotificationService.shared.getFeedbackNotifications()
                
                let (uploadResults, feedbackResults) = try await (uploads, feedback)
                
                // Combine and sort notifications by time
                let allNotifications = (uploadResults + feedbackResults).sorted { first, second in
                    // Extract the numeric value and unit from timeAgo strings
                    let firstValue = Int(first.timeAgo.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                    let secondValue = Int(second.timeAgo.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                    
                    // If both have the same unit (e.g., both "h ago"), compare the values
                    if first.timeAgo.contains("h") && second.timeAgo.contains("h") {
                        return firstValue < secondValue
                    }
                    // If one is in hours and the other in days, hours come first
                    if first.timeAgo.contains("h") && second.timeAgo.contains("d") {
                        return true
                    }
                    if first.timeAgo.contains("d") && second.timeAgo.contains("h") {
                        return false
                    }
                    // If both are in days, compare the values
                    return firstValue < secondValue
                }
                
                await MainActor.run {
                    self.notifications = allNotifications
                    self.isLoadingNotifications = false
                }
            } catch {
                await MainActor.run {
                    self.notificationsError = error
                    self.isLoadingNotifications = false
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

#Preview {
    HomeView(selectedTab: .constant(0))
} 
