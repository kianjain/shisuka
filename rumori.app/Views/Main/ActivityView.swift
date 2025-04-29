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
                                        .cornerRadius(6)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 56, height: 56)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Content
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
}

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topBarHeight: CGFloat = 0
    @State private var uploadNotifications: [NotificationItem] = []
    @State private var feedbackNotifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = error {
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
                } else if uploadNotifications.isEmpty && feedbackNotifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("When you upload projects or receive feedback, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            if !feedbackNotifications.isEmpty {
                                NotificationSection(title: "Recent Feedback", notifications: feedbackNotifications)
                            }
                            if !uploadNotifications.isEmpty {
                                NotificationSection(title: "Recent Uploads", notifications: uploadNotifications)
                            }
                        }
                        .padding(.top, 16)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .refreshable {
                await loadNotifications()
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        Task {
            do {
                async let uploads = NotificationService.shared.getProjectUploadNotifications()
                async let feedback = NotificationService.shared.getFeedbackNotifications()
                
                let (uploadResults, feedbackResults) = try await (uploads, feedback)
                
                await MainActor.run {
                    self.uploadNotifications = uploadResults
                    self.feedbackNotifications = feedbackResults
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
} 