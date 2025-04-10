import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Image
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                )
                            
                            // User Info
                            VStack(spacing: 4) {
                                Text("John Doe")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text("@johndoe")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Stats
                            HStack(spacing: 32) {
                                VStack {
                                    Text("12")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Projects")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("45")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Reviews")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("128")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    Text("Rumors")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Activity")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(0..<5) { _ in
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reviewed a project")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        Text("2 hours ago")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
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
        }
    }
}

#Preview {
    ProfileView()
} 