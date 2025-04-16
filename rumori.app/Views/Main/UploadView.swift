import SwiftUI
import PhotosUI
import Supabase

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

struct UploadView: View {
    @State private var projectName: String = ""
    @State private var projectDescription: String = ""
    @State private var showingFilePicker = false
    @State private var selectedFileName: String = "No file selected"
    @State private var selectedFileURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUploading = false
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 4
    
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Upload section
                        uploadSection
                    }
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Upload")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileButton(size: 32) {
                        showingProfile = true
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
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotifications) {
                ActivityView()
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                        selectedFileName = "Selected Image"
                    }
                }
            }
        }
    }
    
    private var uploadSection: some View {
        VStack(spacing: 24) {
            // File Selection
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
            
            // Project Name
            InputField(
                title: "Project Name",
                placeholder: "Enter project name",
                text: $projectName
            )
            
            // Project Description
            InputField(
                title: "Project Description",
                placeholder: "Describe your project...",
                text: $projectDescription,
                isMultiline: true
            )
            
            // Upload Button
            Button(action: validateAndUpload) {
                Text("Upload Project")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
            }
            .padding(.top, 8)
            .disabled(projectName.isEmpty || imageData == nil || isUploading)
            .opacity(projectName.isEmpty || imageData == nil || isUploading ? 0.6 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private func validateAndUpload() {
        Task {
            do {
                // Validate required fields
                guard !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw UploadError.emptyFields
                }
                
                guard let imageData = imageData else {
                    throw UploadError.noFileSelected
                }
                
                isUploading = true
                
                // Upload the project
                let project = try await ProjectService.shared.uploadProject(
                    title: projectName,
                    description: projectDescription.isEmpty ? nil : projectDescription,
                    imageData: imageData
                )
                
                print("✅ Project uploaded successfully: \(project.title)")
                
                // Reset form
                projectName = ""
                projectDescription = ""
                selectedFileName = "No file selected"
                self.imageData = nil
                isUploading = false
                
            } catch UploadError.emptyFields {
                errorMessage = "Please fill in all required fields"
                showError = true
            } catch UploadError.noFileSelected {
                errorMessage = "Please select a file to upload"
                showError = true
            } catch {
                errorMessage = "Error uploading project: \(error.localizedDescription)"
                showError = true
            }
            isUploading = false
        }
    }
    
    private enum UploadError: Error {
        case fileTooLarge
        case invalidFileType
        case emptyFields
        case noFileSelected
    }
} 
