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

    var body: some View {
        Group {
            // Use the service's published property
            if jellyfinService.isAuthenticated {
                // Pass the service down to the main navigation view if needed later
                ContentNavigationView()
                    .environmentObject(jellyfinService) // Optionally make it available via EnvironmentObject
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
