import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "rectangle.split.1x2.fill")
                    Text("Home")
                }
                .tag(0)
            
            UploadView()
                .tabItem {
                    Image(systemName: "arrowshape.up.fill")
                    Text("Upload")
                }
                .tag(1)
            
            LibraryView()
                .tabItem {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Library")
                }
                .tag(2)
            
            ReviewView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Review")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.white)
    }
}

#Preview {
    MainTabView()
} 