//
//  ContentView.swift
//  rumori.app
//
//  Created by user on 2025/03/18.
//

import SwiftUI

// Commenting out custom tab bar as it might interfere
/*struct CustomTabBar: View {
    let selectedTab: Int
    
    var body: some View {
        // Background container
        VStack(spacing: 0) {
            Spacer()
            
            // Blur and gradient container
            ZStack {
                // Base blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.85), location: 0),
                                .init(color: Color.black.opacity(0.6), location: 0.4),
                                .init(color: Color.black.opacity(0.4), location: 0.7),
                                .init(color: Color.black.opacity(0.2), location: 1)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                
                // Inner shadow at the top
                Rectangle()
                    .fill(Color.clear)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.1),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 4)
                    , alignment: .top)
            }
            .frame(height: 100)
        }
        .ignoresSafeArea()
    }
}*/

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "rectangle.grid.1x2")
                    Text("Home")
                }
                .tag(0)
            
            UploadView()
                .tabItem {
                    Image(systemName: "arrow.up.circle")
                    Text("Upload")
                }
                .tag(1)
            
            ReviewView()
                .tabItem {
                    Image(systemName: "bubble.left.fill")
                    Text("Review")
                }
                .tag(2)
            
            LibraryView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Library")
                }
                .tag(3)
        }
        .tint(.white)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            // Use this appearance for both normal and scrolling states
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Library Tab") {
    ContentView()
        .onAppear {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.view.backgroundColor = .systemBackground
            }
        }
}

