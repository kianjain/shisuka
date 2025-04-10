import SwiftUI

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
                        id: UUID(),
                        name: item.name,
                        description: item.description,
                        fileType: item.type,
                        author: "You",
                        imageUrl: item.imageUrl,
                        uploadDate: Date(),
                        status: .active,
                        feedback: [],
                        rumorsSpent: 0,
                        likes: 0,
                        isOwnedByUser: true,
                        lastStatusUpdate: nil
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
    @State private var showingNotifications = false
    @State private var showingProfile = false
    @State private var showingSettings = false
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    
    // Mock data
    private let newFeedbackCount = 12
    
    // Favorites data
    private let favoriteItems = [
        MinimalisticCardItem(
            name: "Summer Beat",
            subtitle: "🎵",
            description: "A fresh electronic track with tropical vibes",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            type: "Audio"
        ),
        MinimalisticCardItem(
            name: "Portrait Series",
            subtitle: "📸",
            description: "A collection of street photography shots",
            imageUrl: URL(string: "https://example.com/portrait-series-cover.jpg"),
            type: "Images"
        ),
        MinimalisticCardItem(
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
            name: "New Feedback",
            subtitle: "2h ago",
            description: "John commented on 'Summer Beat'",
            imageUrl: nil,
            type: "comment"
        ),
        MinimalisticCardItem(
            name: "Project Completed",
            subtitle: "1d ago",
            description: "Portrait Series is now live",
            imageUrl: nil,
            type: "checkmark.circle"
        ),
        MinimalisticCardItem(
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
            name: "Urban Soundscape",
            subtitle: "2 days ago",
            description: "A collection of field recordings capturing the unique sounds of city life, from bustling streets to quiet alleyways.",
            imageUrl: URL(string: "https://example.com/urban-soundscape-cover.jpg"),
            type: "Audio"
        ),
        MinimalisticCardItem(
            name: "Portrait Series",
            subtitle: "5 days ago",
            description: "A series of street portraits exploring human emotions and connections in urban environments.",
            imageUrl: URL(string: "https://example.com/portrait-series-cover.jpg"),
            type: "Images"
        ),
        MinimalisticCardItem(
            name: "Summer Beat",
            subtitle: "1 week ago",
            description: "An upbeat electronic track blending tropical elements with modern production techniques.",
            imageUrl: URL(string: "https://example.com/summer-beat-cover.jpg"),
            type: "Audio"
        )
    ]
    
    // Review projects data
    private let reviewProjects = [
        (title: "Summer Vibes", type: "Audio", imageUrl: URL(string: "https://example.com/summer-vibes.jpg")),
        (title: "Street Life", type: "Images", imageUrl: URL(string: "https://example.com/street-life.jpg")),
        (title: "Night Sounds", type: "Audio", imageUrl: URL(string: "https://example.com/night-sounds.jpg")),
        (title: "Urban Series", type: "Images", imageUrl: URL(string: "https://example.com/urban-series.jpg"))
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
                    rating: 1,
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
                    VStack(spacing: 24) {
                        // Feedback Count Section
                        VStack(spacing: 16) {
                            FeedbackCountCard(count: newFeedbackCount)
                            
                            LibraryButton {
                                // Handle library action
                            }
                        }
                        .padding(.horizontal)
                        
                        // Earn Rumors Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Earn Rumors")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(reviewProjects, id: \.title) { project in
                                        NavigationLink(destination: ProjectView(project: ProjectPreview(
                                            id: UUID(),
                                            name: project.title,
                                            description: "Sample description for \(project.title)",
                                            fileType: project.type,
                                            author: "Sample Author",
                                            imageUrl: project.imageUrl,
                                            uploadDate: Date(),
                                            status: .active,
                                            feedback: [],
                                            rumorsSpent: 0,
                                            likes: 0,
                                            isOwnedByUser: false,
                                            lastStatusUpdate: nil
                                        ))) {
                                            ReviewProjectCard(
                                                title: project.title,
                                                type: project.type,
                                                imageUrl: project.imageUrl
                                            )
                                        }
                                    }
                                    
                                    // Review More Card
                                    Button(action: {
                                        selectedTab = 2
                                    }) {
                                        ZStack(alignment: .bottomLeading) {
                                            // Background Image
                                            Image("ReviewCardBackground")
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
                        
                        // Minimalistic Cards Section
                        VStack(spacing: 12) {
                            MinimalisticCard(
                                title: "Recent Projects",
                                icon: "clock.fill",
                                items: recentProjectItems,
                                color: .black,
                                actionTitle: "View All Projects",
                                action: {
                                    selectedTab = 3 // Navigate to Library tab
                                }
                            )
                            
                            MinimalisticCard(
                                title: "Notifications",
                                icon: "bell.fill",
                                items: notificationItems,
                                color: .black,
                                actionTitle: "View All Notifications",
                                action: {
                                    // Show notifications sheet
                                    showingNotifications = true
                                }
                            )
                            
                            MinimalisticCard(
                                title: "Favorites",
                                icon: "star.fill",
                                items: favoriteItems,
                                color: .black,
                                actionTitle: "View All Favorites",
                                action: {
                                    // Handle favorites action
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            showingNotifications = true
                        }) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showingNotifications) {
                ActivityView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
} 
