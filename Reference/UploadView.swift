import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .scrollContentBackground(.hidden)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

struct FilePickerButton: View {
    let fileName: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project File")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: action) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                    Text(fileName)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: -2, y: 2)
                .shadow(color: Color.white.opacity(0.3), radius: 8, x: 2, y: -2)
            }
            .foregroundColor(.white)
        }
    }
}

struct RumorsSelection: View {
    @Binding var value: Double
    private let options = [1, 2, 3, 5, 10]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Desired Feedback")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: { value = Double(option) }) {
                            Text("\(option)")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Int(value) == option ? Color(.systemGray6) : Color(.systemGray6))
                                .foregroundColor(Int(value) == option ? .white : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Int(value) == option ? 
                                            Color.white : 
                                            Color.gray.opacity(0.3),
                                            lineWidth: Int(value) == option ? 2 : 1
                                        )
                                )
                                .shadow(
                                    color: Int(value) == option ? 
                                        Color(red: 0.4, green: 0.4, blue: 1.0).opacity(0.3) : 
                                        Color.black.opacity(0.2),
                                    radius: Int(value) == option ? 8 : 0,
                                    x: 0,
                                    y: Int(value) == option ? 2 : 0
                                )
                        }
                    }
                }
                
                Text("This will cost \(Int(value)) rumors")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct UploadButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct RecentUploadCard: View {
    let title: String
    let type: String
    let imageUrl: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.systemGray6)
            }
            .frame(width: 160, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Type Badge
            Text(type.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 160)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Mock data for recent uploads
private let recentUploads = [
    (title: "Summer Beat", type: "Audio", imageUrl: "https://example.com/summer-beat.jpg"),
    (title: "Album Cover", type: "Image", imageUrl: "https://example.com/album-cover.jpg"),
    (title: "Music Video", type: "Video", imageUrl: "https://example.com/music-video.jpg"),
    (title: "New Track", type: "Audio", imageUrl: "https://example.com/new-track.jpg")
]

struct UploadView: View {
    @State private var showingNotifications = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedRumors: Int = 1
    @State private var selectedFile: URL?
    @State private var showingFilePicker = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @Binding var selectedTab: Int
    @EnvironmentObject private var userState: UserState
    
    private let rumorsOptions = [1, 2, 3, 5, 10]
    
    private func handleFileSelection(_ url: URL) {
        // Clear any previous image data
        imageData = nil
        
        // If it's an image file, try to load it
        if url.pathExtension.lowercased() == "jpg" || 
           url.pathExtension.lowercased() == "jpeg" || 
           url.pathExtension.lowercased() == "png" {
            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                imageData = data
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // File Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Project File")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            // Photo Library Button
                            Button(action: { showingImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                    Text("Photo Library")
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                                )
                            }
                            .foregroundColor(.white)
                            
                            // Files Button
                            Button(action: { showingFilePicker = true }) {
                                HStack {
                                    Image(systemName: "doc")
                                        .font(.title2)
                                    Text("Files")
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                                )
                            }
                            .foregroundColor(.white)
                        }
                        
                        // Image Preview
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                imageData = data
                                // Create a temporary file URL
                                let tempDir = FileManager.default.temporaryDirectory
                                let fileName = "image_\(UUID().uuidString).jpg"
                                let fileURL = tempDir.appendingPathComponent(fileName)
                                
                                // Save the image data to the temporary file
                                try? data.write(to: fileURL)
                                selectedFile = fileURL
                            }
                        }
                    }
                    .fileImporter(
                        isPresented: $showingFilePicker,
                        allowedContentTypes: [.audio],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            guard let url = urls.first else { return }
                            selectedFile = url
                            imageData = nil // Clear any previous image data
                        case .failure(let error):
                            print("Error selecting file: \(error.localizedDescription)")
                        }
                    }
                    .onChange(of: selectedFile) { oldValue, newValue in
                        if let newValue = newValue {
                            handleFileSelection(newValue)
                        }
                    }
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("Enter project title", text: $title)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    
                    // Description Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description & Feedback Points")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextEditor(text: $description)
                            .frame(height: 160)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal)
                    
                    // Rumors Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rumors to Spend")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 12) {
                            ForEach(rumorsOptions, id: \.self) { amount in
                                Button(action: {
                                    withAnimation {
                                        selectedRumors = amount
                                    }
                                }) {
                                    Text("\(amount)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedRumors == amount ? 
                                                    Color.white : 
                                                    Color.gray.opacity(0.3),
                                                    lineWidth: selectedRumors == amount ? 2 : 1
                                                )
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit Section
                    Button(action: {
                        // Handle submission
                        Task {
                            do {
                                if let file = selectedFile {
                                    let fileData = try Data(contentsOf: file)
                                    let fileExtension = file.pathExtension.lowercased()
                                    let fileType = fileExtension == "mp3" || fileExtension == "wav" ? "audio/mpeg" : "image/jpeg"
                                    
                                    _ = try await ProjectService.shared.createProject(
                                        title: title,
                                        description: description,
                                        fileType: fileType,
                                        files: [fileData]
                                    )
                                }
                            } catch {
                                print("Error creating project: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .background(Color.black)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            // MARK: - TopBar Implementation
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .padding(.leading, 8)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Notifications Button
                        Button {
                            showingNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .foregroundColor(.white)
                                
                                // Unread Indicator
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                        
                        // Settings Button
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                        }
                        
                        // Profile Button
                        Button {
                            showingProfile = true
                        } label: {
                            ProfilePicture(
                                username: userState.currentProfile?.username,
                                size: 32
                            )
                        }
                    }
                }
            }
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
}

struct PhotosPickerItemView: View {
    let item: PhotosPickerItem
    @State private var image: Image?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
        }
        .task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                image = Image(uiImage: uiImage)
            }
        }
    }
}

#Preview {
    UploadView(selectedTab: .constant(1))
} 
