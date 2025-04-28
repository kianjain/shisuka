import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthService.shared
    @State private var showingSignOutAlert = false
    @State private var selectedSupportItem: SupportItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Support Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Support")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(supportSettings, id: \.title) { setting in
                                Button(action: {
                                    selectedSupportItem = SupportItem(title: setting.title)
                                }) {
                                    SettingRow(setting: setting)
                                }
                            }
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
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
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await auth.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(item: $selectedSupportItem) { item in
                Group {
                    switch item.title {
                    case "Contact Us":
                        ContactUsView()
                    case "Terms of Service":
                        TermsOfServiceView()
                    case "Privacy Policy":
                        PrivacyPolicyView()
                    default:
                        EmptyView()
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private let supportSettings = [
        SettingItem(title: "Contact Us", icon: "envelope.fill", action: {}),
        SettingItem(title: "Terms of Service", icon: "doc.text.fill", action: {}),
        SettingItem(title: "Privacy Policy", icon: "hand.raised.fill", action: {})
    ]
}

struct SettingItem {
    let title: String
    let icon: String
    let action: () -> Void
}

struct SettingRow: View {
    let setting: SettingItem
    
    var body: some View {
        HStack {
            Image(systemName: setting.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(setting.title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SupportItem: Identifiable {
    let id = UUID()
    let title: String
}

struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Contact Support")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Need help?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("You can reach our support team by sending an email to:")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:info@shisuka.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("info@shisuka.com")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    
                    Text("We typically respond within 24 hours.")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.top, 32)
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Terms of Service")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last updated: March 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("By accessing and using Rumori, you accept and agree to be bound by the terms and provision of this agreement.")
                        .foregroundColor(.gray)
                    
                    Text("2. User Conduct")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Users must not engage in any activity that disrupts or interferes with the service, including but not limited to: uploading malicious content, spamming, or attempting to gain unauthorized access to other users' accounts.")
                        .foregroundColor(.gray)
                    
                    Text("3. Content Ownership")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Users retain ownership of their content. By uploading content to Rumori, you grant us a license to use, store, and display that content in connection with the service.")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.top, 32)
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Privacy Policy")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last updated: March 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("1. Information We Collect")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("We collect information that you provide directly to us, including your name, email address, and any content you upload to the service.")
                        .foregroundColor(.gray)
                    
                    Text("2. How We Use Your Information")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to protect our users.")
                        .foregroundColor(.gray)
                    
                    Text("3. Data Security")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.top, 32)
        }
    }
}

#Preview {
    SettingsView()
} 