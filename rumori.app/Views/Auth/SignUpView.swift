import SwiftUI

struct SignUpView: View {
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    Button(action: signUp) {
                        if auth.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(auth.isLoading)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(auth.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await auth.signUp(email: email, password: password, username: username)
                dismiss()
            } catch {
                showingError = true
            }
        }
    }
}

#Preview {
    SignUpView()
} 