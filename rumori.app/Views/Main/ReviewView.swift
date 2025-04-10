import SwiftUI

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
            feedback: [],
            rumorsSpent: 0,
            likes: 8,
            isOwnedByUser: false,
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
            feedback: [],
            rumorsSpent: 0,
            likes: 15,
            isOwnedByUser: false,
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
                    if mockProjects.isEmpty {
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
                        .frame(maxHeight: .infinity)
                    } else if currentIndex < mockProjects.count {
                        VStack {
                            Spacer()
                                .frame(height: 20)
                            
                            projectCard(mockProjects[currentIndex])
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
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .padding(.top, topBarHeight)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Review")
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
            VStack(alignment: .leading, spacing: 16) {
                // Project Type Badge
                Text(project.fileType)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 16)
                
                // Project Title and Author
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text("by \(project.author)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Description
                Text(project.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .background(Color(.systemGray6))
        }
        .frame(maxWidth: 340)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    Color.white.opacity(0.3),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: -2, y: 2)
        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 2, y: -2)
        .padding(.horizontal, 24.0)
        .padding(.vertical, 8)
        
        return Group {
            if offset == .zero {
                NavigationLink(destination: ProjectView(project: project)) {
                    cardContent
                }
            } else {
                cardContent
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
