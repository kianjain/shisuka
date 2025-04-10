import SwiftUI

struct NotificationSection: View {
    let title: String
    let notifications: [NotificationItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 24) {
                ForEach(notifications) { notification in
                    HStack(spacing: 12) {
                        // Project Image
                        if let projectImage = notification.projectImage {
                            AsyncImage(url: projectImage) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(6)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(notification.userName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(notification.timeAgo)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("\(notification.action) \(notification.projectName)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topBarHeight: CGFloat = 0
    
    // Mock data
    private let thisWeekNotifications = [
        NotificationItem(
            userName: "Koyes Ahmed Rumina",
            action: "liked your track",
            projectName: "PULSE (prod. urbs)",
            projectImage: URL(string: "https://example.com/track1.jpg"),
            timeAgo: "2d"
        ),
        NotificationItem(
            userName: "kris",
            action: "liked your track",
            projectName: "Lay Low - Alexa...",
            projectImage: URL(string: "https://example.com/track2.jpg"),
            timeAgo: "7d"
        )
    ]
    
    private let thisMonthNotifications = [
        NotificationItem(
            userName: "MrYeetMaster",
            action: "liked your track",
            projectName: "Rodd Rigo - Trop...",
            projectImage: URL(string: "https://example.com/track3.jpg"),
            timeAgo: "13d"
        ),
        NotificationItem(
            userName: "bliss! archives",
            action: "liked your track",
            projectName: "Rodd Rigo - Abo...",
            projectImage: URL(string: "https://example.com/track4.jpg"),
            timeAgo: "18d"
        ),
        NotificationItem(
            userName: "Julia Reijnen",
            action: "liked your track",
            projectName: "Lay Low - Alexa...",
            projectImage: URL(string: "https://example.com/track5.jpg"),
            timeAgo: "25d"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        NotificationSection(title: "This Week", notifications: thisWeekNotifications)
                        NotificationSection(title: "This Month", notifications: thisMonthNotifications)
                    }
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
} 