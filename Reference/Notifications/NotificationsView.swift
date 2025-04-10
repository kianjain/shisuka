import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: String = "All"
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["All", "Unread", "Mentions"], id: \.self) { filter in
                                Button(action: {
                                    selectedFilter = filter
                                }) {
                                    Text(filter)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFilter == filter ?
                                            Color.white.opacity(0.2) :
                                            Color.clear
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color.black)
                    
                    // Notifications List
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else if let error = error {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text("Error loading notifications")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Try Again") {
                                loadNotifications()
                            }
                            .padding(.top, 8)
                        }
                        Spacer()
                    } else if notifications.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No notifications yet")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("When you get notifications, they'll appear here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(notifications) { notification in
                                    NotificationCard(notification: notification)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadNotifications()
            }
        }
    }
    
    private func loadNotifications() {
        isLoading = true
        error = nil
        
        // Simulate loading notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            notifications = [
                NotificationItem(
                    userName: "JohnDoe",
                    action: "commented on your project",
                    projectName: "Summer Beat",
                    projectImage: URL(string: "https://example.com/summer-beat.jpg"),
                    timeAgo: "2h ago"
                ),
                NotificationItem(
                    userName: "JaneSmith",
                    action: "liked your project",
                    projectName: "Urban Photography",
                    projectImage: URL(string: "https://example.com/urban-photo.jpg"),
                    timeAgo: "5h ago"
                ),
                NotificationItem(
                    userName: "MikeJohnson",
                    action: "mentioned you in a comment",
                    projectName: "City Documentary",
                    projectImage: URL(string: "https://example.com/city-doc.jpg"),
                    timeAgo: "1d ago"
                )
            ]
            isLoading = false
        }
    }
}

struct NotificationCard: View {
    let notification: NotificationItem
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // User Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(notification.userName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(notification.userName) \(notification.action)")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(notification.projectName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(notification.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Project Image or Icon
                if let imageUrl = notification.projectImage {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            .padding()
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
}

#Preview {
    NotificationsView()
} 