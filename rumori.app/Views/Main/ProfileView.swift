import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var isEditingUsername = false
    @State private var newUsername = ""
    @FocusState private var isUsernameFocused: Bool
    
    private func uploadProfileImage(_ item: PhotosPickerItem) async {
        do {
            // Get the image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("❌ [Profile] Failed to load image data")
                return
            }
            
            // Upload the image using AuthService
            try await auth.uploadProfileImage(data)
            
        } catch {
            print("❌ [Profile] Error uploading profile image: \(error)")
        }
    }
    
    private func updateUsername() async {
        guard !newUsername.isEmpty else { return }
        do {
            try await auth.updateUsername(newUsername)
            isEditingUsername = false
            isUsernameFocused = false
        } catch {
            print("❌ [Profile] Error updating username: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 24) {
                            // Profile Image with Picker
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                ProfilePicture(size: 100, action: nil)
                            }
                            .task(id: selectedImage) {
                                if let image = selectedImage {
                                    await uploadProfileImage(image)
                                }
                            }
                            
                            // User Info
                            VStack(spacing: 4) {
                                if isEditingUsername {
                                    TextField("Username", text: $newUsername)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .focused($isUsernameFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            Task {
                                                await updateUsername()
                                            }
                                        }
                                        .onAppear {
                                            isUsernameFocused = true
                                        }
                                } else {
                                    if let username = auth.currentProfile?.username {
                                        Text(username)
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                newUsername = username
                                                isEditingUsername = true
                                            }
                                    } else {
                                        Text("Anonymous")
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                newUsername = ""
                                                isEditingUsername = true
                                            }
                                    }
                                }
                                
                                Text(auth.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Stats
                            HStack(spacing: 48) {
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
                            .padding()
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
            .onTapGesture {
                if isEditingUsername {
                    isEditingUsername = false
                    isUsernameFocused = false
                }
            }
        }
    }
}

#Preview {
    ProfileView()
} 
