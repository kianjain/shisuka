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
            
            ReviewView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                    Text("Review")
                }
                .tag(2)
            
            LibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library")
                }
                .tag(3)
        }
        .tint(.white)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
} 