//
//  rumori_appApp.swift
//  rumori.app
//
//  Created by user on 2025/03/18.
//

import SwiftUI

@main
struct rumori_appApp: App {
    @StateObject private var auth = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if auth.isAuthenticated {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .preferredColorScheme(.dark) // Force dark mode
            .onAppear {
                // Set up any initial app configuration here
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
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Configure text and icon colors for dark mode
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Remove any existing shadow image or color
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        // Configure tab bar items appearance for dark mode
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.5)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
}
