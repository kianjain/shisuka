import SwiftUI

struct SignInView: View {
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo
                Image("sh.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding(.top, 80)
                
                Spacer()
                
                // Form
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                    
                    Button(action: signIn) {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.black)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
                    .opacity(auth.isLoading || email.isEmpty || password.isEmpty ? 0.5 : 1)
                    
                    Button("Don't have an account? Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 200)
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await auth.signIn(email: email, password: password)
                dismiss()
            } catch {
                if let authError = error as? AuthError {
                    switch authError {
                    case .invalidCredentials:
                        errorMessage = "Invalid email or password"
                    case .emailNotVerified:
                        errorMessage = "Please verify your email before signing in"
                    default:
                        errorMessage = "An error occurred during sign in"
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                showingError = true
            }
        }
    }
}

#Preview {
    SignInView()
} 
