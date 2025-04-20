//
//  FinityApp.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI
import FirebaseCore

// Define the AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct FinityApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Create a single instance of JellyfinService for the entire app lifecycle
    @StateObject private var jellyfinService = JellyfinService()

    var body: some Scene {
        WindowGroup {
            // Pass the service down to the ContentView
            MainView()
                 .environmentObject(jellyfinService)
        }
    }
}

// You'll need to create this MainView or adapt your existing ContentView
// struct MainView: View {
//     @EnvironmentObject var jellyfinService: JellyfinService
//
//     var body: some View {
//         // Show loading indicator while checking auth state initially
//         if jellyfinService.isCheckingAuth { // Need to add this state to JellyfinService
//              ProgressView()
//         } else if jellyfinService.isAuthenticated {
//              // Assuming ContentNavigationView is your main tab/navigation structure
//              ContentNavigationView() // Pass environment object implicitly
//         } else {
//              LoginView(jellyfinService: jellyfinService) // Pass directly if needed, or use environment
//         }
//     }
// }

// We need to create a view that decides whether to show Login or the main content
// based on the jellyfinService.isAuthenticated state.
// Let's create a simple placeholder MainView for now.
struct MainView: View {
    @EnvironmentObject var jellyfinService: JellyfinService
    // Assuming ContentNavigationView exists and holds HomeView etc.
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        // Show loading indicator while checking auth state initially
         if jellyfinService.isCheckingAuth { // We will add this state
             ZStack {
                 Color.black.edgesIgnoringSafeArea(.all)
                 ProgressView().scaleEffect(1.5).tint(.white)
             }
         } else if jellyfinService.isAuthenticated {
             ContentNavigationView() // Assumes this view uses the environment object
                .environmentObject(navigationState)
         } else {
             LoginView(jellyfinService: jellyfinService) // Pass explicitly as LoginView uses @ObservedObject
         }
    }
}

// Placeholder for your main navigation structure after login
struct ContentNavigationView: View {
     @EnvironmentObject var jellyfinService: JellyfinService
     @EnvironmentObject var navigationState: NavigationState // For managing search view state etc.

     var body: some View {
         // Replace with your actual TabView or main navigation structure
         HomeView(showSearchView: $navigationState.showSearchView) // Pass binding
             .environmentObject(jellyfinService) // Ensure service is passed down if needed further
     }
}

// Simple state object for navigation-related things like showing search
class NavigationState: ObservableObject {
    @Published var showSearchView = false
}
