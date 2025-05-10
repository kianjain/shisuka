import SwiftUI
import PhotosUI
import Supabase

enum UploadType {
    case photo
    case audio
}

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

struct SuccessView: View {
    @Binding var selectedTab: Int
    @Binding var showSuccess: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text("Successfully Uploaded!")
                .font(.title3)
                .bold()
                .foregroundColor(.white)
            
            Text("You can now view your project and track reviews inside the library")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .onTapGesture {
            selectedTab = 3 // Switch to Library tab
            showSuccess = false
        }
    }
}

struct FileTypeButton: View {
    let systemName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemName)
                    .font(.title2)
                Text(title)
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

struct FilePreviewView: View {
    let imageData: Data?
    let audioURL: URL?
    let selectedUploadType: UploadType?
    let showingImagePicker: Bool
    let onAddCoverImage: () -> Void
    
    var body: some View {
        VStack {
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
            
            if let audioURL = audioURL {
                Text("Selected: \(audioURL.lastPathComponent)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if selectedUploadType == .audio && imageData == nil {
                Button(action: onAddCoverImage) {
                    HStack {
                        Image(systemName: "photo")
                            .font(.title2)
                        Text("Add Cover Image")
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
    }
}

struct FileSelectionView: View {
    @Binding var selectedUploadType: UploadType?
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: PhotosPickerItem?
    @Binding var imageData: Data?
    @Binding var selectedAudio: URL?
    @Binding var audioData: Data?
    @Binding var projectName: String
    @Binding var projectDescription: String
    @Binding var isUploading: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    @Binding var showingAudioCropper: Bool
    @Binding var selectedAudioURL: URL?
    let viewModel: UploadViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project File")
                .font(.headline)
                .foregroundColor(.white)
            
            if selectedUploadType == nil {
                HStack(spacing: 12) {
                    FileTypeButton(systemName: "photo", title: "Photo Library") {
                        selectedUploadType = .photo
                        showingImagePicker = true
                    }
                    
                    FileTypeButton(systemName: "music.note", title: "Audio File") {
                        selectedUploadType = .audio
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
                            picker.delegate = viewModel
                            window.rootViewController?.present(picker, animated: true)
                        }
                    }
                }
            }
            
            if selectedUploadType != nil {
                FileTypeButton(systemName: "xmark.circle", title: "Cancel") {
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
                    errorMessage = nil
                    selectedAudioURL = nil
                }
                .padding(.top, 8)
            }
            
            FilePreviewView(
                imageData: imageData,
                audioURL: selectedAudio,
                selectedUploadType: selectedUploadType,
                showingImagePicker: showingImagePicker,
                onAddCoverImage: { showingImagePicker = true }
            )
        }
    }
}

struct UploadFormView: View {
    @Binding var projectName: String
    @Binding var projectDescription: String
    @Binding var isUploading: Bool
    @Binding var selectedUploadType: UploadType?
    @Binding var imageData: Data?
    @Binding var audioData: Data?
    let uploadAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
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
            Button(action: uploadAction) {
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
                    (selectedUploadType == .audio && (audioData == nil || imageData == nil)))
            .opacity(projectName.isEmpty || isUploading || 
                    (selectedUploadType == .photo && imageData == nil) ||
                    (selectedUploadType == .audio && (audioData == nil || imageData == nil)) ? 0.6 : 1.0)
        }
    }
}

struct UploadContentView: View {
    @Binding var showSuccess: Bool
    @Binding var selectedTab: Int
    @Binding var selectedUploadType: UploadType?
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: PhotosPickerItem?
    @Binding var imageData: Data?
    @Binding var selectedAudio: URL?
    @Binding var audioData: Data?
    @Binding var projectName: String
    @Binding var projectDescription: String
    @Binding var isUploading: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    @Binding var showingAudioCropper: Bool
    @Binding var selectedAudioURL: URL?
    @Binding var showingProfile: Bool
    @Binding var showingSettings: Bool
    @Binding var showingNotifications: Bool
    let viewModel: UploadViewModel
    let uploadAction: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if showSuccess {
                SuccessView(selectedTab: $selectedTab, showSuccess: $showSuccess)
                    .transition(.opacity)
                    .navigationBarHidden(true)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        FileSelectionView(
                            selectedUploadType: $selectedUploadType,
                            showingImagePicker: $showingImagePicker,
                            selectedImage: $selectedImage,
                            imageData: $imageData,
                            selectedAudio: $selectedAudio,
                            audioData: $audioData,
                            projectName: $projectName,
                            projectDescription: $projectDescription,
                            isUploading: $isUploading,
                            showError: $showError,
                            errorMessage: Binding(
                                get: { errorMessage ?? "" },
                                set: { errorMessage = $0 }
                            ),
                            showingAudioCropper: $showingAudioCropper,
                            selectedAudioURL: $selectedAudioURL,
                            viewModel: viewModel
                        )
                        
                        UploadFormView(
                            projectName: $projectName,
                            projectDescription: $projectDescription,
                            isUploading: $isUploading,
                            selectedUploadType: $selectedUploadType,
                            imageData: $imageData,
                            audioData: $audioData,
                            uploadAction: uploadAction
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Upload")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Upload")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    ProfileButton(size: 32, action: {
                        showingProfile = true
                    })
                    
                    // Coin Display
                    HStack(spacing: 8) {
                        Image("coin")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                        Text("\(CoinService.shared.balance)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
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
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 3 {
                showSuccess = false
            }
        }
        .sheet(isPresented: $showingNotifications) {
            ActivityView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
}

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedAudio: URL?
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var isUploading = false
    @State private var selectedUploadType: UploadType?
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var showingImagePicker = false
    @State private var showSuccess = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 4
    
    var body: some View {
        NavigationStack {
            UploadContentView(
                showSuccess: $showSuccess,
                selectedTab: $selectedTab,
                selectedUploadType: $selectedUploadType,
                showingImagePicker: $showingImagePicker,
                selectedImage: $selectedImage,
                imageData: $viewModel.imageData,
                selectedAudio: $selectedAudio,
                audioData: $viewModel.audioData,
                projectName: $projectName,
                projectDescription: $projectDescription,
                isUploading: $isUploading,
                showError: $viewModel.showError,
                errorMessage: $viewModel.errorMessage,
                showingAudioCropper: $viewModel.showingAudioCropper,
                selectedAudioURL: $viewModel.selectedAudioURL,
                showingProfile: $showingProfile,
                showingSettings: $showingSettings,
                showingNotifications: $showingNotifications,
                viewModel: viewModel,
                uploadAction: uploadProject
            )
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { oldValue, newValue in
            Task {
                await viewModel.loadImageData(from: newValue)
            }
        }
        .onChange(of: viewModel.croppedAudioURL) { oldValue, newValue in
            if let url = newValue {
                selectedAudio = url
            }
        }
        .sheet(isPresented: $viewModel.showingAudioCropper) {
            if let audioURL = viewModel.selectedAudioURL {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack {
                            AudioCropperView(audioURL: audioURL, viewModel: viewModel)
                        }
                        .navigationTitle("Crop Audio")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .presentationDetents([.large])
            }
        }
        .navigationDestination(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    private func uploadProject() {
        guard !projectName.isEmpty else { return }
        isUploading = true
        
        Task {
            do {
                // Upload the project
                let project = try await ProjectService.shared.createProject(
                    title: projectName,
                    description: projectDescription.isEmpty ? nil : projectDescription,
                    imageData: viewModel.imageData,
                    audioData: viewModel.audioData
                )
                
                // Reset form
                projectName = ""
                projectDescription = ""
                viewModel.imageData = nil
                viewModel.audioData = nil
                selectedImage = nil
                selectedAudio = nil
                
                // Show success message
                showSuccess = true
                
                // Dismiss the view after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccess = false
                }
            } catch {
                print("❌ [UploadView] Error uploading project: \(error)")
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
            
            await MainActor.run {
                isUploading = false
            }
        }
    }
}

class UploadViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var selectedAudioURL: URL?
    @Published var croppedAudioURL: URL?
    @Published var audioData: Data?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var imageData: Data?
    @Published var showingAudioCropper: Bool = false
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("📁 Document picker selected files: \(urls)")
        guard let url = urls.first else { 
            print("❌ No URL selected")
            return 
        }
        print("✅ Selected audio URL: \(url)")
        print("📱 Current selectedAudioURL state: \(String(describing: selectedAudioURL))")
        selectedAudioURL = url
        print("📱 New selectedAudioURL state: \(String(describing: selectedAudioURL))")
        showingAudioCropper = true
    }
    
    func handleCroppedAudio(_ url: URL) {
        print("✂️ Cropped audio URL received: \(url)")
        print("📱 Current croppedAudioURL state: \(String(describing: croppedAudioURL))")
        croppedAudioURL = url
        print("📱 New croppedAudioURL state: \(String(describing: croppedAudioURL))")
        loadAudioData(from: url)
    }
    
    func loadImageData(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            let data = try await item.loadTransferable(type: Data.self)
            await MainActor.run {
                imageData = data
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func loadAudioData(from url: URL) {
        Task { @MainActor in
            do {
                print("📦 Loading audio data from URL")
                let data = try Data(contentsOf: url)
                audioData = data
                print("✅ Successfully loaded audio data")
            } catch {
                print("❌ Failed to load audio data: \(error)")
                errorMessage = "Failed to load audio file: \(error.localizedDescription)"
                showError = true
            }
        }
    }
} 
