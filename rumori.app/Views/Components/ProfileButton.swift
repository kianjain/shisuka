import SwiftUI

struct ProfileButton: View {
    let size: CGFloat
    let action: () -> Void
    @State private var showingProfile = false
    
    var body: some View {
        Button {
            showingProfile = true
        } label: {
            ProfilePicture(size: size, action: nil)
        }
        .navigationDestination(isPresented: $showingProfile) {
            ProfileView()
        }
    }
}

#Preview {
    ProfileButton(size: 32, action: {})
} 