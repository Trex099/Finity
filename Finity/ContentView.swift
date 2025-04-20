//
//  ContentView.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI

struct ContentView: View {
    // TODO: Replace with a check against secure storage (e.g., Keychain)
    // to see if authentication tokens exist and are valid.
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                ContentNavigationView()
            } else {
                LoginView(onAuthenticated: {
                    // This closure is called by LoginView upon successful login
                    self.isAuthenticated = true
                })
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard) // Prevent keyboard from causing layout issues
        // Add a transition for a smoother switch between login and main view
        .transition(.opacity)
        .animation(.easeInOut, value: isAuthenticated)
    }
}

#Preview {
    ContentView()
}
