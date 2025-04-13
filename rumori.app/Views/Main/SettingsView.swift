import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoPlayEnabled") private var autoPlayEnabled = false
    @StateObject private var auth = AuthService.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(accountSettings, id: \.title) { setting in
                                SettingRow(setting: setting)
                            }
                        }
                        
                        // Preferences Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            Toggle("Dark Mode", isOn: $isDarkMode)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            Toggle("Notifications", isOn: $notificationsEnabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            Toggle("Auto-play Media", isOn: $autoPlayEnabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        // Support Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Support")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(supportSettings, id: \.title) { setting in
                                SettingRow(setting: setting)
                            }
                        }
                        
                        // App Info
                        VStack(spacing: 8) {
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("© 2024 Rumori")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top)
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
        }
    }
    
    private let accountSettings = [
        SettingItem(title: "Edit Profile", icon: "person.fill", action: {}),
        SettingItem(title: "Privacy", icon: "lock.fill", action: {}),
        SettingItem(title: "Security", icon: "shield.fill", action: {}),
        SettingItem(title: "Payment Methods", icon: "creditcard.fill", action: {}),
        SettingItem(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", action: {
            // This will be handled by the alert
        })
    ]
    
    private let supportSettings = [
        SettingItem(title: "Help Center", icon: "questionmark.circle.fill", action: {}),
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
    @State private var showingSignOutAlert = false
    
    var body: some View {
        Button(action: {
            if setting.title == "Sign Out" {
                showingSignOutAlert = true
            } else {
                setting.action()
            }
        }) {
            HStack {
                Image(systemName: setting.icon)
                    .font(.system(size: 20))
                    .foregroundColor(setting.title == "Sign Out" ? .red : .white)
                    .frame(width: 30)
                
                Text(setting.title)
                    .foregroundColor(setting.title == "Sign Out" ? .red : .white)
                
                Spacer()
                
                if setting.title != "Sign Out" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await AuthService.shared.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    SettingsView()
} 