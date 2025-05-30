//
//  ContentView.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI

struct ContentView: View {
    // Receive the JellyfinService instance
    @ObservedObject var jellyfinService: JellyfinService
    
    // No longer need local state for authentication
    // @State private var isAuthenticated = false 
    
    // To manage search view state and other navigation state
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        Group {
            // Use the service's published property
            if jellyfinService.isAuthenticated {
                // Use the correct view name that contains the TabView logic
                MainContentNavigationView()
                    .environmentObject(jellyfinService)
                    .environmentObject(navigationState)
            } else {
                // Pass the service to the LoginView
                LoginView(jellyfinService: jellyfinService)
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard) // Prevent keyboard from causing layout issues
        // Add a transition for a smoother switch between login and main view
        .transition(.opacity)
        // Animate based on the service's state
        .animation(.easeInOut, value: jellyfinService.isAuthenticated)
    }
}

#Preview {
    // Provide a mock service for the preview
    ContentView(jellyfinService: JellyfinService())
}
