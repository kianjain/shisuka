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

struct UploadView: View {
    enum UploadType {
        case photo
        case audio
    }
    
    @StateObject private var viewModel = UploadViewModel()
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedAudio: URL?
    @State private var imageData: Data?
    @State private var audioData: Data?
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedUploadType: UploadType?
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var showingImagePicker = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 4
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // File Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Project File")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if selectedUploadType == nil {
                                HStack(spacing: 12) {
                                    // Photo Library Button
                                    Button(action: { 
                                        selectedUploadType = .photo
                                        showingImagePicker = true 
                                    }) {
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
                                    
                                    // Audio File Button
                                    Button(action: { 
                                        selectedUploadType = .audio
                                        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
                                        picker.delegate = viewModel
                                        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                                    }) {
                                        HStack {
                                            Image(systemName: "music.note")
                                                .font(.title2)
                                            Text("Audio File")
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
                            }
                            
                            // Cancel Button (always visible when upload type is selected)
                            if selectedUploadType != nil {
                                Button(action: {
                                    // Reset all state variables
                                    selectedUploadType = nil
                                    selectedImage = nil
                                    imageData = nil
                                    selectedAudio = nil
                                    audioData = nil
                                    projectName = ""
                                    projectDescription = ""
                                    isUploading = false
                                    showError = false
                                    errorMessage = ""
                                }) {
                                    HStack {
                                        Image(systemName: "xmark.circle")
                                            .font(.title2)
                                        Text("Cancel")
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
                                .padding(.top, selectedUploadType == nil ? 0 : 8)
                            }
                            
                            // Image Preview
                            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                                VStack {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.top, 8)
                            }
                            
                            // Audio File Info
                            if let audioURL = selectedAudio {
                                Text("Selected: \(audioURL.lastPathComponent)")
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            }
                            
                            // Optional Cover Image for Audio
                            if selectedUploadType == .audio && imageData == nil {
                                Button(action: { showingImagePicker = true }) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .font(.title2)
                                        Text("Add Cover Image (Optional)")
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
                                .padding(.top, 8)
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
                        Button(action: uploadProject) {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
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
                        }
                        .padding(.top, 8)
                        .disabled(projectName.isEmpty || isUploading || 
                                (selectedUploadType == .photo && imageData == nil) ||
                                (selectedUploadType == .audio && audioData == nil))
                        .opacity(projectName.isEmpty || isUploading || 
                                (selectedUploadType == .photo && imageData == nil) ||
                                (selectedUploadType == .audio && audioData == nil) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
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
                        self.imageData = data
                    } else {
                        self.imageData = nil
                    }
                }
            }
            .onChange(of: viewModel.selectedAudioURL) { oldValue, newValue in
                if let url = newValue {
                    selectedAudio = url
                    do {
                        audioData = try Data(contentsOf: url)
                    } catch {
                        showError = true
                        errorMessage = "Failed to load audio file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func uploadProject() {
        guard let uploadType = selectedUploadType else { return }
            
            isUploading = true
            
        Task {
            do {
                let project = try await ProjectService.shared.uploadProject(
                    title: projectName,
                    description: projectDescription.isEmpty ? nil : projectDescription,
                    imageData: imageData,
                    audioData: uploadType == .audio ? audioData : nil
                )
                
                // Reset form
                DispatchQueue.main.async {
                    self.projectName = ""
                    self.projectDescription = ""
                    self.imageData = nil
                    self.audioData = nil
                    self.selectedImage = nil
                    self.selectedAudio = nil
                    self.selectedUploadType = nil
                    self.isUploading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                    self.isUploading = false
                }
            }
        }
    }
}

class UploadViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var selectedAudioURL: URL?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        selectedAudioURL = url
    }
} 
