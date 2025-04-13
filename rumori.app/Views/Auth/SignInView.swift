import SwiftUI

struct SignInView: View {
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
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
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    Button(action: signIn) {
                        if auth.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(auth.isLoading)
                    
                    Button("Don't have an account? Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.blue)
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
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(auth.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await auth.signIn(email: email, password: password)
                dismiss()
            } catch {
                showingError = true
            }
        }
    }
}

#Preview {
    SignInView()
} 