import SwiftUI

struct ProfilePicture: View {
    @StateObject private var auth = AuthService.shared
    let size: CGFloat
    let action: (() -> Void)?
    
    private var initial: String {
        if let username = auth.currentProfile?.username {
            return String(username.prefix(1)).uppercased()
        }
        return "A"
    }
    
    private var backgroundColor: Color {
        // Always return dark gray to match app appearance
        return Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var body: some View {
        Group {
            if let avatarUrl = auth.currentProfile?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: size, height: size)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholderView
            }
        }
        .if(action != nil) { view in
            view.onTapGesture(perform: action!)
        }
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ProfilePicture(size: 32, action: nil)
} 