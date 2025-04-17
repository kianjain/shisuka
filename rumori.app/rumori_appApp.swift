//
//  rumori_appApp.swift
//  rumori.app
//
//  Created by user on 2025/03/18.
//

import SwiftUI

@main
struct rumori_appApp: App {
    @StateObject private var projectService = ProjectService.shared
    @StateObject private var auth = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if auth.isAuthenticated {
                    MainTabView()
                        .environmentObject(projectService)
                } else {
                    SignInView()
                }
            }
            .environmentObject(auth)
            .preferredColorScheme(.dark) // Force dark mode
            .onAppear {
                Task {
                    await auth.checkAuthState()
                }
                setupAppearance()
            }
        }
    }
    
    private func setupAppearance() {
        // Configure global appearance
        let appearance = UINavigationBarAppearance()
        
        // Configure from scratch instead of using default
        appearance.configureWithTransparentBackground()
        appearance.shadowImage = nil
        appearance.shadowColor = .clear
        
        // Set navigation bar items to white for dark mode
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white  // This affects bar button items
        
        // Remove the border/separator
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        
        // Use default tab bar appearance
        UITabBar.appearance().standardAppearance = UITabBarAppearance()
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
    }
}
