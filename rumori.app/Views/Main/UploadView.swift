import SwiftUI

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
    @State private var desiredFeedback: Double = 1
    @State private var showingFilePicker = false
    @State private var selectedFileName: String = "No file selected"
    @State private var selectedFileURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUploading = false
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
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
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.2.fill")
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
        }
    }
    
    private var uploadSection: some View {
        VStack(spacing: 24) {
            // File Selection
            FilePickerButton(fileName: selectedFileName) {
                showingFilePicker = true
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
            
            // Rumors Amount Selection
            RumorsSelection(value: $desiredFeedback)
            
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
            .disabled(projectName.isEmpty || selectedFileName == "No file selected" || isUploading)
            .opacity(projectName.isEmpty || selectedFileName == "No file selected" || isUploading ? 0.6 : 1.0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private func validateAndUpload() {
        do {
            // Validate required fields
            guard !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw UploadError.emptyFields
            }
            
            isUploading = true
            
            // Simulate upload delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("Mock upload successful for project: \(projectName)")
                print("Description: \(projectDescription)")
                print("Desired feedback: \(Int(desiredFeedback)) rumors")
                print("File: \(selectedFileName)")
                
                // Reset form
                projectName = ""
                projectDescription = ""
                desiredFeedback = 1
                selectedFileName = "No file selected"
                selectedFileURL = nil
                isUploading = false
            }
        } catch UploadError.emptyFields {
            errorMessage = "Please fill in all required fields"
            showError = true
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private enum UploadError: Error {
        case fileTooLarge
        case invalidFileType
        case emptyFields
    }
} 
