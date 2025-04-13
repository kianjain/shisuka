import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Image
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Group {
                                        if let avatarUrl = auth.currentProfile?.avatarUrl {
                                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white)
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                                .clipShape(Circle())
                            
                            // User Info
                            VStack(spacing: 4) {
                                if let username = auth.currentProfile?.username {
                                    Text(username)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                } else {
                                    Text("Anonymous")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                
                                Text(auth.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Stats
                            HStack(spacing: 32) {
                                VStack {
                                    Text("12")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Projects")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("45")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Reviews")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("128")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Rumors")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        
                        // Favorites Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Favorites")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("View All")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            // Favorites Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(0..<6) { _ in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Favorite Item Image
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.3))
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(
                                                Image(systemName: "photo.on.rectangle.angled")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white.opacity(0.7))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Project Title")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text("Category")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
} 