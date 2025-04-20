//
//  FinityApp.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI

@main
struct FinityApp: App {
    // Create a single instance of JellyfinService for the entire app lifecycle
    @StateObject private var jellyfinService = JellyfinService()

    var body: some Scene {
        WindowGroup {
            // Pass the service down to the ContentView
            ContentView(jellyfinService: jellyfinService)
        }
    }
}
