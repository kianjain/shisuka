import SwiftUI

struct ProfileButton: View {
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ProfilePicture(size: size, action: nil)
        }
    }
}

#Preview {
    ProfileButton(size: 32, action: {})
} 