import SwiftUI

struct SignUpView: View {
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var showingError = false
    @State private var showingConfirmation = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var isCheckingUsername = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and Description
                VStack(spacing: 12) {
                    Text("New here?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Let's get you started")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
                
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
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    
                    HStack {
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .tint(.white)
                            .onChange(of: username) { oldValue, newValue in
                                checkUsernameAvailability()
                            }
                        
                        if isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(width: 24, height: 24)
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        } else if let isAvailable = isUsernameAvailable {
                            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isAvailable ? .green : .red)
                                .frame(width: 24, height: 24)
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(.white)
                    
                    Button(action: { showingConfirmation = true }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .disabled(!(isUsernameAvailable ?? false) || username.isEmpty || email.isEmpty || password.isEmpty)
                    .opacity((isUsernameAvailable ?? false) && !username.isEmpty && !email.isEmpty && !password.isEmpty ? 1 : 0.5)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 200)
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(auth.error?.localizedDescription ?? "An unknown error occurred")
            }
            .navigationDestination(isPresented: $showingConfirmation) {
                SignUpConfirmationView(
                    email: email,
                    password: password,
                    username: username,
                    onComplete: { dismiss() }
                )
            }
        }
    }
    
    private func checkUsernameAvailability() {
        guard !username.isEmpty else {
            isUsernameAvailable = nil
            return
        }
        
        isCheckingUsername = true
        isUsernameAvailable = nil
        
        Task {
            do {
                let isAvailable = try await auth.checkUsernameAvailability(username)
                isUsernameAvailable = isAvailable
            } catch {
                // Silently handle the error by marking username as not available
                isUsernameAvailable = false
            }
            isCheckingUsername = false
        }
    }
}

struct SignUpConfirmationView: View {
    let email: String
    let password: String
    let username: String
    let onComplete: () -> Void
    
    @StateObject private var auth = AuthService.shared
    @State private var showingError = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Check your email")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We'll send a confirmation link to your email address. Please check your inbox and click the link to verify your account.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 100)
            
            Spacer()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            
            Button(action: completeSignUp) {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .disabled(auth.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(auth.error?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    private func completeSignUp() {
        Task {
            do {
                try await auth.signUp(email: email, password: password, username: username)
                onComplete()
            } catch {
                if let authError = error as? AuthError, authError == .emailAlreadyExists {
                    errorMessage = "This email is linked to an already existing account. Try to log in."
                } else {
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    SignUpView()
} 
